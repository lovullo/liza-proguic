<?xml version="1.0"?>
<!--
  Builds the data API data structures to be included in the Program class
  for a given program

  Copyright (C) 2017 R-T Specialty, LLC.

    This file is part of the Liza Program UI Compiler.

    liza-proguic is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see
    <http://www.gnu.org/licenses/>.

  AN XSLT 2.0 PARSER IS REQUIRED TO PROCESS THIS STYLESHEET!
-->
<stylesheet version="2.0"
            xmlns="http://www.w3.org/1999/XSL/Transform"
            xmlns:xs="http://www.w3.org/2001/XMLSchema"
            xmlns:lv="http://www.lovullo.com"
            xmlns:st="http://www.lovullo.com/liza/proguic/util/struct"
            xmlns:compiler="http://www.lovullo.com/program/compiler"
            xmlns:assert="http://www.lovullo.com/assert">

<output method="text"
        indent="yes"
        omit-xml-declaration="yes" />


<!--
  Constructs an object literal containing object-literal definitions of each
  API, indexed by API id
-->
<template match="lv:program" mode="compiler:compile-apis">
  <text>{</text>
    <for-each select="./lv:api">
      <if test="position() > 1">
        <text>,</text>
      </if>

      <text>'</text>
        <value-of select="@id" />
      <text>':</text>

      <apply-templates select="." mode="compiler:compile" />
    </for-each>
  <text>}</text>
</template>


<!--
  RESTful API definition

  Much of this would be common to any type of API, so this can be refactored
  if/when other types are added.

  The generated code is an object literal describing the API.
-->
<template match="lv:api[@type='rest' or @type='local' or @type='quote']"
          mode="compiler:compile" priority="5">
  <variable name="api" select="." />

  <text>{</text>
    <!-- simply copy over the string values of each of these attributes -->
    <for-each select="('type', 'source', 'method', 'enctype')">
      <variable name="attr" select="." />

      <value-of select="$attr" />
      <text>:'</text>
        <value-of select="$api/@*[ local-name() = $attr ]" />
      <text>',</text>
    </for-each>

    <!-- build params (to be sent to the service) -->
    <text>params:{</text>
      <for-each select="./lv:param">
        <if test="position() > 1">
          <text>,</text>
        </if>

        <text>'</text>
          <value-of select="@name" />
        <text>':</text>

        <!-- generate the param description -->
        <apply-templates select="." mode="compiler:compile" />
      </for-each>
    <text>},</text>

    <!-- build an array of expected return values -->
    <text>retvals:[</text>
      <for-each select="./lv:returns/lv:param">
        <if test="position() > 1">
          <text>,</text>
        </if>

        <text>'</text>
          <value-of select="@name" />
        <text>'</text>
      </for-each>
    <text>],</text>

    <!-- static values to prepend to the server response set -->
    <text>'static':[</text>
      <for-each select="./lv:returns/lv:static/lv:item">
        <if test="position() > 1">
          <text>,</text>
        </if>

        <text>{</text>
          <apply-templates select="." mode="compiler:compile" />
        <text>}</text>
      </for-each>
    <text>],</text>

    <text>static_nonempty:</text>
    <choose>
      <when test="./lv:returns/lv:static/@nonempty = 'true'">
        <text>true</text>
      </when>

      <otherwise>
        <text>false</text>
      </otherwise>
    </choose>

    <text>,</text>

    <text>static_multiple:</text>
    <choose>
      <when test="./lv:returns/lv:static/@multiple = 'true'">
        <text>true</text>
      </when>

      <otherwise>
        <text>false</text>
      </otherwise>
    </choose>
  <text>}</text>
</template>


<!--
  Generates an object literal describing a particular API parameter

  Params can have default values that are either strings or references to
  bucket values; the distinction is made via a "type" field.

  All single quotes are stripped, even if they are within the middle of a
  string. This has the consequence of both removing single quotes for string
  literals and preventing the user from terminating the string (code injection,
  syntax errors more likely); if we need single quotes, that will have to be
  changed in the future. Changes are, single quotes will not be needed.
-->
<template match="lv:api/lv:param" mode="compiler:compile">
  <text>{</text>

  <!-- param name -->
  <text>name:'</text>
    <value-of select="@name" />
  <text>',</text>

  <!-- default value, if any (will default to an empty string -->
  <text>'default':{</text>
    <text>type:'</text>
      <choose>
        <!-- if the value starts with a single quote, then it is to be
             interpreted as a string instead of a bucket reference -->
        <when test="starts-with( @value, &quot;'&quot; )">
          <text>string</text>
        </when>

        <!-- non-strings are considered to be bucket references -->
        <otherwise>
          <text>ref</text>
        </otherwise>
      </choose>
    <text>',</text>

    <text>value:'</text>
      <!-- remove single quotes, which may or may not be present -->
      <value-of select="translate( @value, &quot;'&quot;, '' )" />
    <text>'</text>
  <text>}</text>

  <text>}</text>
</template>


<template match="lv:api/lv:returns/lv:static/lv:item" mode="compiler:compile">
  <for-each select="./lv:value">
    <if test="position() > 1">
      <text>,</text>
    </if>

    <text>'</text>
      <value-of select="@param" />
    <text>':'</text>
      <!-- remove single quotes -->
      <value-of select="translate( ., &quot;'&quot;, '' )" />
    <text>'</text>
  </for-each>
</template>


<!-- unknown API type -->
<template match="lv:api" mode="compiler:compile" priority="1">
  <compiler:error>
    <text>Unknown API type '</text>
      <value-of select="@type" />
    <text>'</text>
  </compiler:error>
</template>


<!--
  Triggers API calls when dependency params change
-->
<template mode="post-parse-question-event"
              priority="5"
              match="lv:question[
                       ./lv:data
                       or @id=//lv:question/lv:data/@* ]">
  <param name="type" />
  <param name="id" />
  <param name="eventData" />

  <choose>
    <when test="$type = 'dapi'">
      <call-template name="compiler:dapi-event" />
    </when>

    <when test="$type = 'change'">
      <sequence select="concat(
                          $eventData,
                          '.dapi[''', $id, ''']',
                          '.apply( this, arguments ); ' )" />
    </when>
  </choose>
</template>


<template name="compiler:dapi-event">
  <variable name="id"       select="@id" />
  <variable name="question" select="." />

  <!-- are we used as a dependency for any other API calls? -->
  <variable name="depof" as="element( lv:question )*"
                select="//lv:question[ ./lv:data/@* = $id ]" />

  <variable name="dapi-call" as="element( lv:data )+"
                select="if ( exists( $depof ) ) then
                          $depof/lv:data
                        else
                          $question/lv:data" />

  <!-- whether any questions we map _to_ request that their values be
       retained -->
  <variable name="has-retains" as="xs:boolean"
              select="exists( //lv:question[
                          @id = $dapi-call/lv:map/@into
                          and @retain = 'true'
                      ] )" />

  <for-each select="$depof">
    <choose>
      <when test="lv:data/@source=//lv:api[ @combined='true' ]/@id">
        <!-- marker to help find this code in the compiled file -->
        <text>/*dapicall-combined*/</text>

        <!-- we only care about the indexes that have actually changed -->
        <text>if(diff['</text>
          <value-of select="$id" />
        <text>']){</text>
          <!-- trigger the API call -->
          <apply-templates select="./lv:data" mode="compiler:api-trigger" />
        <text>}</text>
      </when>


      <otherwise>
        <!-- marker to help find this code in the compiled file -->
        <text>/*dapicall*/</text>

        <!-- we only care about the indexes that have actually changed -->
        <text>var diffdata=diff['</text>
          <value-of select="$id" />
        <text>'];</text>

        <!-- we must make the API call for each index -->
        <!-- N.B. As a consequence of this, since diff should be {} on load (since
             nothing actually changed), this will not kick off on step load (see the change
             event for the question itself) -->
        <text>var cdata=bucket.getDataByName('</text>
          <value-of select="$id" />
        <text>');</text>
        <text>for(var i in (diffdata||cdata)){</text>
          <!-- if any destination field requests to retain its value
               when its predicate no longer matches, then there is no
               use in ignoring the predicate, since there's no value
               to clear when it becomes false if we don't make the
                call to begin with -->
            <if test="not( $has-retains )">
            <!-- if subject to a predicate, ensure that it is met -->
            <text>if(cmatch['</text>
                <value-of select="@id" />
            <text>'] &amp;&amp; +cmatch['</text>
                <value-of select="@id" />
            <text>'].indexes[i] !== 1</text>
            <text> &amp;&amp; !cmatch['</text>
                <value-of select="@id" />
            <text>'].all) {</text>
                <text>this.dapiManager.fieldStale('</text>
                    <value-of select="@id" />
                <text>',i); continue;</text>
            <text>};</text>
          </if>

          <!-- ensure that i keeps its value throughout the life of the request -->
          <text>(function(i){</text>

            <!-- trigger the API call -->
            <apply-templates select="./lv:data" mode="compiler:api-trigger">
              <with-param name="i" select="'i'" />
            </apply-templates>

          <!-- self-executing closure for the index (otherwise the value would have
               changed before the request comes back, so we would always be dealing
               with the last index) -->
          <text>}).call(this,i);</text>

        <text>}</text>
      </otherwise>
    </choose>
  </for-each>

  <!-- compile any direct API calls, if any -->
  <apply-templates select="./lv:data" mode="compiler:compile" />
</template>


<!--
  Triggers the actual data API call.

  This will attempt to retrieve data from the API. In the event that required
  params are missing, it will throw an exception, which this will interpret as
  "not enough data" and will clear the field and each of its mapped bucket
  values. Consequently, this means that erasing the value of a field that this
  depends on will cause this field to be cleared.
-->
<template match="lv:data" mode="compiler:api-trigger">
  <!-- the variable in the generated JS holding the index to operate on -->
  <param name="i" select="'-1'" />

  <variable name="self" select="." />

  <!-- id of the parent question -->
  <variable name="qid" select="../@id" />

  <!-- grab a list of all the API call params -->
  <variable name="params"
    select="@*[ not( local-name()='source' ) ]" />

  <!-- grab value and label mappings -->
  <variable name="value-map" select="./lv:value/@from" />
  <variable name="label-map">
    <choose>
      <!-- if a label map is given, use it -->
      <when test="./lv:label">
        <value-of select="./lv:label/@from" />
      </when>

      <!-- otherwise, default to the same value as the value map -->
      <otherwise>
        <value-of select="$value-map" />
      </otherwise>
    </choose>
  </variable>

  <text>var _self=this;</text>

  <!-- this is where the magic happens -->
  <if test="$i = '-1'">
    <text>var i=-1;</text>
  </if>

  <text>(function(i){</text>
    <!-- default; TODO: we don't always need this -->
    <text>var cdata = [];</text>

    <!-- do we have any restrictions on this API call? -->
    <for-each select="lv:unless-set">
      <!-- return immediately from the lambda if the value is already set -->
      <text>if(''+bucket.getDataByName('</text>
        <value-of select="@ref" />
      <text>')[i]!=='')return;</text>
    </for-each>


    <!-- prevents race conditions when triggering fieldLoading event -->
    <text>var doload=true;</text>

    <!-- TODO: duplicated  -->
    <text>var prediff=bucket.getDataByName('</text>
        <value-of select="../@id" />
    <text>');</text>

    <text>this.dapiManager.getApiData('</text>
      <value-of select="@source" />
    <text>', {</text>

      <!-- add each of the param lookups -->
      <for-each select="$params">
        <if test="position() > 1 ">
          <text>,</text>
        </if>

        <!-- the ref we need to look up for this param -->
        <variable name="ref" select="." />

        <!-- get the name associated with this param -->
        <variable name="pname"
          select="$self/@*[ . = $ref ]/local-name()" />

        <text>'</text>
          <value-of select="$pname" />
        <text>': </text>

        <variable name="bucket-data">
          <call-template name="parse-expected">
            <with-param name="expected" select="$ref" />
            <with-param name="with-diff" select="true()" />
          </call-template>
        </variable>

        <choose>
          <when test="substring( $ref, 1, 1 ) = &quot;'&quot;">
            <value-of select="$ref" />
          </when>

          <!-- -1 is the "combined" index -->
          <when test="$i = '-1'">
            <value-of select="$bucket-data" />
          </when>

          <otherwise>
            <value-of select="$bucket-data" />
            <text>[</text>
              <value-of select="$i" />
            <text>]</text>
          </otherwise>
        </choose>
      </for-each>

      <text>},</text>

      <!-- once the data is returned, populate the field -->
      <text>function(err,retdata){doload=false;_self.dapiManager.setFieldData('</text>
        <value-of select="$qid" />
      <text>',</text>
        <value-of select="$i" />
      <text>,retdata,'</text>
        <value-of select="$value-map" />
      <text>','</text>
        <value-of select="$label-map" />
      <text>',(prediff[i]===cdata[i]))},</text>

    <text>'</text>
      <value-of select="$qid" />
    <text>',i,bucket,function(e){</text>
      <!-- on failure -->
      <text>_self.dapiManager.clearPendingApiCall('</text>
        <value-of select="$qid" />
      <text>_'+i);</text>

      <text>_self.dapiManager.fieldNotReady('</text>
        <value-of select="$qid" />
      <text>',</text>
        <value-of select="$i" />
      <text>,bucket);</text>

    <!-- end of getApiData() call -->
    <text>});</text>

    <!-- kick off an event allowing the UI/etc to indicate that the field
         is loading (we must do this *after* the call to ensure that this
         is only kicked off if there is no error) -->
    <text>if(doload){</text>
      <text>this.emit('fieldLoading','</text>
        <value-of select="$qid" />
      <text>',</text>
        <value-of select="$i" />
      <text>);</text>
    <text>}</text>
  <!-- invoke lambda with i to ensure that the value does not change on us -->
  <text>}).call(this,i);</text>
</template>


<template match="lv:data" mode="compiler:gen-data-map">
  <for-each select="./lv:map">
    <if test="position() > 1">
      <text>,</text>
    </if>

    <text>'</text>
      <value-of select="@into" />
    <text>':'</text>
      <value-of select="@param" />
    <text>'</text>
  </for-each>
</template>


<!--
  Handles param expansion when a field containing API data changes
-->
<template match="lv:question/lv:data" mode="compiler:compile">
  <!-- The change event is triggered on step load as well as the addition of
       any indexes, giving us the chance to initialize any API calls. This also
       allows us to initialize once on page load rather than once per param
       change event (which would be bad) -->
  <apply-templates select="." mode="compiler:compile-api-init" />

  <!-- we only care about the indexes that have actually changed -->
  <text>var diffdata=diff['</text>
      <value-of select="../@id" />
    <text>']||</text>
    <!-- we need to update the values for each field -->
    <text>bucket.getDataByName('</text>
      <value-of select="../@id" />
  <text>');</text>

  <text>var prediff=bucket.getDataByName('</text>
      <value-of select="../@id" />
  <text>');</text>

  <!-- XXX: duplicate -->
  <variable name="label-map">
    <choose>
      <!-- if a label map is given, use it -->
      <when test="./lv:label">
        <value-of select="./lv:label/@from" />
      </when>

      <!-- otherwise, default to the same value as the value map -->
      <otherwise>
        <value-of select="lv:value/@from" />
      </otherwise>
    </choose>
  </variable>

  <text>for(var i in diffdata){</text>
    <!-- null represents a removal -->
    <text>if(diffdata[i]===null){</text>
      <text>this.dapiManager.clearFieldData('</text>
        <value-of select="../@id" />
      <text>',i, false);</text>
      <text>continue;</text>
    <text>}</text>

    <text>if(this.dapiManager.hasFieldData('</text>
      <value-of select="../@id" />
    <text>',i)){</text>

      <!-- if we have no diff date, then this is probably triggered as the result
           of visiting the step; ensure that we populate the field if necessary
           -->
      <text>var expand=(prediff[i]!==diffdata[i]);</text>
      <text>if(!diff['</text>
        <value-of select="../@id" />
      <text>']){</text>
        <text>expand=this.dapiManager.triggerFieldUpdate('</text>
          <value-of select="../@id" />
        <text>',</text>
          <value-of select="'i'" />
        <text>,'</text>
          <value-of select="lv:value/@from" />
        <text>','</text>
          <value-of select="$label-map" />
        <text>',(cdata[i]===diffdata[i]));</text>
      <text>}</text>

      <!-- expand the data into the bucket (the last argument indicates that we
           can predictively set values knowing that the data for the value may
           become available in the near future) -->
      <text>if(expand)this.dapiManager.expandFieldData('</text>
        <value-of select="../@id" />
      <text>',i,bucket,{</text>
        <apply-templates select="." mode="compiler:gen-data-map" />
      <text>},true,diff);</text>
    <text>}</text>

  <text>}</text>
</template>


<!--
  If an API call has no arguments, then it must be populated immediately (since
  there are no other fields that could trigger its population)
-->
<template match="lv:question/lv:data" mode="compiler:compile-api-init">

  <variable name="qid" select="../@id" />

  <!-- marker to make it easier to find a section in the compiled code -->
  <text>/*dapiinit*/</text>

  <!-- current bucket data -->
  <text>var cdata=diff['</text>
    <value-of select="$qid" />
  <text>']||bucket.getDataByName('</text>
    <value-of select="$qid" />
  <text>');</text>

  <choose>
    <!-- combined call -->
    <when test="@source=//lv:api[ @combined='true' ]/@id">
      <!-- if we already have the API data, then we need only populate this
           field -->
      <text>if(this.dapiManager.hasFieldData('</text>
        <value-of select="$qid" />
      <text>')){</text>

        <!-- XXX: duplicate -->
        <variable name="label-map">
          <choose>
            <!-- if a label map is given, use it -->
            <when test="./lv:label">
              <value-of select="./lv:label/@from" />
            </when>

            <!-- otherwise, default to the same value as the value map -->
            <otherwise>
              <value-of select="lv:value/@from" />
            </otherwise>
          </choose>
        </variable>

        <!-- populate only the indexes that have changed -->
        <text>var cdiff=diff['</text>
          <value-of select="$qid" />
        <text>'];</text>
        <text>for(var i in cdiff){</text>

          <!-- do nothing if the data is unchanged -->
          <text>if(cdiff[i]||cdiff[i]===''){</text>

            <text>this.dapiManager.triggerFieldUpdate('</text>
              <value-of select="$qid" />
            <text>',</text>
              <value-of select="'i'" />
            <text>,'</text>
              <value-of select="lv:value/@from" />
            <text>','</text>
              <value-of select="$label-map" />
            <text>',(cdata[i]===cdiff[i]));</text>

          <text>}</text>

        <text>}</text>

      <!-- otherwise, we do not yet have any data; perform the API call -->
      <text>}else{</text>
        <apply-templates select="." mode="compiler:api-trigger" />
      <text>}</text>
    </when>

    <!-- per-index -->
    <otherwise>
      <!-- check each existing index -->
      <text>for(var i in cdata){</text>

        <!-- populate the field if it does not yet have any data -->
        <text>if(!this.dapiManager.hasFieldData('</text>
          <value-of select="$qid" />
        <text>',i)){</text>

          <!-- trigger the API call for this index -->
          <apply-templates select="." mode="compiler:api-trigger">
            <with-param name="i" select="'i'" />
          </apply-templates>

        <text>}</text>
      <text>}</text>
    </otherwise>
  </choose>

</template>

</stylesheet>
