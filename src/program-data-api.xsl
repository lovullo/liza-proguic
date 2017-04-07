<?xml version="1.0"?>
<!--
  Builds the data API data structures to be included in the Program class
  for a given program

  Copyright (C) 2017 LoVullo Associates, Inc.

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
<xsl:stylesheet version="2.0"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:lv="http://www.lovullo.com"
  xmlns:compiler="http://www.lovullo.com/program/compiler"
  xmlns:assert="http://www.lovullo.com/assert">

<xsl:output
  method="text"
  indent="yes"
  omit-xml-declaration="yes"
  />


<!--
  Constructs an object literal containing object-literal definitions of each
  API, indexed by API id
-->
<xsl:template match="lv:program" mode="compiler:compile-apis">
  <xsl:text>{</xsl:text>
    <xsl:for-each select="./lv:api">
      <xsl:if test="position() > 1">
        <xsl:text>,</xsl:text>
      </xsl:if>

      <xsl:text>'</xsl:text>
        <xsl:value-of select="@id" />
      <xsl:text>':</xsl:text>

      <xsl:apply-templates select="." mode="compiler:compile" />
    </xsl:for-each>
  <xsl:text>}</xsl:text>
</xsl:template>


<xsl:template match="lv:program" mode="compiler:compile-question-apis">
  <xsl:text>{</xsl:text>
    <xsl:for-each select="//lv:question[ lv:data ]">
      <xsl:if test="position() > 1">
        <xsl:text>,</xsl:text>
      </xsl:if>

      <xsl:value-of select="concat( '''',
                                    @id,
                                    ''':''',
                                    lv:data/@source,
                                    '''' )" />
    </xsl:for-each>
  <xsl:text>}</xsl:text>
</xsl:template>


<!--
  RESTful API definition

  Much of this would be common to any type of API, so this can be refactored
  if/when other types are added.

  The generated code is an object literal describing the API.
-->
<xsl:template match="lv:api[@type='rest' or @type='local']" mode="compiler:compile" priority="5">
  <xsl:variable name="api" select="." />

  <xsl:text>{</xsl:text>
    <!-- simply copy over the string values of each of these attributes -->
    <xsl:for-each select="('type', 'source', 'method')">
      <xsl:variable name="attr" select="." />

      <xsl:value-of select="$attr" />
      <xsl:text>:'</xsl:text>
        <xsl:value-of select="$api/@*[ local-name() = $attr ]" />
      <xsl:text>',</xsl:text>
    </xsl:for-each>

    <!-- build params (to be sent to the service) -->
    <xsl:text>params:{</xsl:text>
      <xsl:for-each select="./lv:param">
        <xsl:if test="position() > 1">
          <xsl:text>,</xsl:text>
        </xsl:if>

        <xsl:text>'</xsl:text>
          <xsl:value-of select="@name" />
        <xsl:text>':</xsl:text>

        <!-- generate the param description -->
        <xsl:apply-templates select="." mode="compiler:compile" />
      </xsl:for-each>
    <xsl:text>},</xsl:text>

    <!-- build an array of expected return values -->
    <xsl:text>retvals:[</xsl:text>
      <xsl:for-each select="./lv:returns/lv:param">
        <xsl:if test="position() > 1">
          <xsl:text>,</xsl:text>
        </xsl:if>

        <xsl:text>'</xsl:text>
          <xsl:value-of select="@name" />
        <xsl:text>'</xsl:text>
      </xsl:for-each>
    <xsl:text>],</xsl:text>

    <!-- static values to prepend to the server response set -->
    <xsl:text>'static':[</xsl:text>
      <xsl:for-each select="./lv:returns/lv:static/lv:item">
        <xsl:if test="position() > 1">
          <xsl:text>,</xsl:text>
        </xsl:if>

        <xsl:text>{</xsl:text>
          <xsl:apply-templates select="." mode="compiler:compile" />
        <xsl:text>}</xsl:text>
      </xsl:for-each>
    <xsl:text>],</xsl:text>

    <xsl:text>static_nonempty:</xsl:text>
    <xsl:choose>
      <xsl:when test="./lv:returns/lv:static/@nonempty = 'true'">
        <xsl:text>true</xsl:text>
      </xsl:when>

      <xsl:otherwise>
        <xsl:text>false</xsl:text>
      </xsl:otherwise>
    </xsl:choose>

    <xsl:text>,</xsl:text>

    <xsl:text>static_multiple:</xsl:text>
    <xsl:choose>
      <xsl:when test="./lv:returns/lv:static/@multiple = 'true'">
        <xsl:text>true</xsl:text>
      </xsl:when>

      <xsl:otherwise>
        <xsl:text>false</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  <xsl:text>}</xsl:text>
</xsl:template>


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
<xsl:template match="lv:api/lv:param" mode="compiler:compile">
  <xsl:text>{</xsl:text>

  <!-- param name -->
  <xsl:text>name:'</xsl:text>
    <xsl:value-of select="@name" />
  <xsl:text>',</xsl:text>

  <!-- default value, if any (will default to an empty string -->
  <xsl:text>'default':{</xsl:text>
    <xsl:text>type:'</xsl:text>
      <xsl:choose>
        <!-- if the value starts with a single quote, then it is to be
             interpreted as a string instead of a bucket reference -->
        <xsl:when test="starts-with( @value, &quot;'&quot; )">
          <xsl:text>string</xsl:text>
        </xsl:when>

        <!-- non-strings are considered to be bucket references -->
        <xsl:otherwise>
          <xsl:text>ref</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    <xsl:text>',</xsl:text>

    <xsl:text>value:'</xsl:text>
      <!-- remove single quotes, which may or may not be present -->
      <xsl:value-of select="translate( @value, &quot;'&quot;, '' )" />
    <xsl:text>'</xsl:text>
  <xsl:text>}</xsl:text>

  <xsl:text>}</xsl:text>
</xsl:template>


<xsl:template match="lv:api/lv:returns/lv:static/lv:item" mode="compiler:compile">
  <xsl:for-each select="./lv:value">
    <xsl:if test="position() > 1">
      <xsl:text>,</xsl:text>
    </xsl:if>

    <xsl:text>'</xsl:text>
      <xsl:value-of select="@param" />
    <xsl:text>':'</xsl:text>
      <!-- remove single quotes -->
      <xsl:value-of select="translate( ., &quot;'&quot;, '' )" />
    <xsl:text>'</xsl:text>
  </xsl:for-each>
</xsl:template>


<!-- unknown API type -->
<xsl:template match="lv:api" mode="compiler:compile" priority="1">
  <compiler:error>
    <xsl:text>Unknown API type '</xsl:text>
      <xsl:value-of select="@type" />
    <xsl:text>'</xsl:text>
  </compiler:error>
</xsl:template>


<!--
  Triggers API calls when dependency params change
-->
<xsl:template mode="post-parse-question-event"
              priority="5"
              match="lv:question[
                       ./lv:data
                       or @id=//lv:data/@* ]">
  <xsl:param name="type" />
  <xsl:param name="id" />
  <xsl:param name="eventData" />

  <xsl:choose>
    <xsl:when test="$type = 'dapi'">
      <xsl:call-template name="compiler:dapi-event" />
    </xsl:when>

    <xsl:when test="$type = 'change'">
      <xsl:sequence select="concat(
                            $eventData,
                            '.dapi[''', $id, ''']',
                            '.apply( this, arguments ); ' )" />
    </xsl:when>
  </xsl:choose>
</xsl:template>


<xsl:template name="compiler:dapi-event">
  <xsl:variable name="id"       select="@id" />
  <xsl:variable name="question" select="." />

  <!-- are we used as a dependency for any other API calls? -->
  <xsl:variable name="depof" as="element( lv:question )*"
                select="//lv:question[ ./lv:data/@* = $id ]" />

  <xsl:variable name="dapi-call" as="element( lv:data )+"
                select="if ( exists( $depof ) ) then
                          $depof/lv:data
                        else
                          $question/lv:data" />

  <!-- whether any questions we map _to_ request that their values be
       retained -->
  <xsl:variable name="has-retains" as="xs:boolean"
              select="exists( //lv:question[
                          @id = $dapi-call/lv:map/@into
                          and @retain = 'true'
                      ] )" />

  <xsl:for-each select="$depof">
    <xsl:choose>
      <xsl:when test="lv:data/@source=//lv:api[ @combined='true' ]/@id">
        <!-- marker to help find this code in the compiled file -->
        <xsl:text>/*dapicall-combined*/</xsl:text>

        <!-- we only care about the indexes that have actually changed -->
        <xsl:text>if(diff['</xsl:text>
          <xsl:value-of select="$id" />
        <xsl:text>']){</xsl:text>
          <!-- trigger the API call -->
          <xsl:apply-templates select="./lv:data" mode="compiler:api-trigger" />
        <xsl:text>}</xsl:text>
      </xsl:when>


      <xsl:otherwise>
        <!-- marker to help find this code in the compiled file -->
        <xsl:text>/*dapicall*/</xsl:text>

        <!-- we only care about the indexes that have actually changed -->
        <xsl:text>var diffdata=diff['</xsl:text>
          <xsl:value-of select="$id" />
        <xsl:text>'];</xsl:text>

        <!-- we must make the API call for each index -->
        <!-- N.B. As a consequence of this, since diff should be {} on load (since
             nothing actually changed), this will not kick off on step load (see the change
             event for the question itself) -->
        <xsl:text>var cdata=bucket.getDataByName('</xsl:text>
          <xsl:value-of select="$id" />
        <xsl:text>');</xsl:text>
        <xsl:text>for(var i in (diffdata||cdata)){</xsl:text>
          <!-- if any destination field requests to retain its value
               when its predicate no longer matches, then there is no
               use in ignoring the predicate, since there's no value
               to clear when it becomes false if we don't make the
                call to begin with -->
            <xsl:if test="not( $has-retains )">
            <!-- if subject to a predicate, ensure that it is met -->
            <xsl:text>if(cmatch['</xsl:text>
                <xsl:value-of select="@id" />
            <xsl:text>'] &amp;&amp; +cmatch['</xsl:text>
                <xsl:value-of select="@id" />
            <xsl:text>'].indexes[i] !== 1</xsl:text>
            <xsl:text> &amp;&amp; !cmatch['</xsl:text>
                <xsl:value-of select="@id" />
            <xsl:text>'].all) {</xsl:text>
                <xsl:text>this.dapiManager.fieldStale('</xsl:text>
                    <xsl:value-of select="@id" />
                <xsl:text>',i); continue;</xsl:text>
            <xsl:text>};</xsl:text>
          </xsl:if>

          <!-- ensure that i keeps its value throughout the life of the request -->
          <xsl:text>(function(i){</xsl:text>

            <!-- trigger the API call -->
            <xsl:apply-templates select="./lv:data" mode="compiler:api-trigger">
              <xsl:with-param name="i" select="'i'" />
            </xsl:apply-templates>

          <!-- self-executing closure for the index (otherwise the value would have
               changed before the request comes back, so we would always be dealing
               with the last index) -->
          <xsl:text>}).call(this,i);</xsl:text>

        <xsl:text>}</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:for-each>

  <!-- compile any direct API calls, if any -->
  <xsl:apply-templates select="./lv:data" mode="compiler:compile" />
</xsl:template>


<!--
  Triggers the actual data API call.

  This will attempt to retrieve data from the API. In the event that required
  params are missing, it will throw an exception, which this will interpret as
  "not enough data" and will clear the field and each of its mapped bucket
  values. Consequently, this means that erasing the value of a field that this
  depends on will cause this field to be cleared.
-->
<xsl:template match="lv:data" mode="compiler:api-trigger">
  <!-- the variable in the generated JS holding the index to operate on -->
  <xsl:param name="i" select="'-1'" />

  <xsl:variable name="self" select="." />

  <!-- id of the parent question -->
  <xsl:variable name="qid" select="../@id" />

  <!-- grab a list of all the API call params -->
  <xsl:variable name="params"
    select="@*[ not( local-name()='source' ) ]" />

  <!-- grab value and label mappings -->
  <xsl:variable name="value-map" select="./lv:value/@from" />
  <xsl:variable name="label-map">
    <xsl:choose>
      <!-- if a label map is given, use it -->
      <xsl:when test="./lv:label">
        <xsl:value-of select="./lv:label/@from" />
      </xsl:when>

      <!-- otherwise, default to the same value as the value map -->
      <xsl:otherwise>
        <xsl:value-of select="$value-map" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:text>var _self=this;</xsl:text>

  <!-- this is where the magic happens -->
  <xsl:if test="$i = '-1'">
    <xsl:text>var i=-1;</xsl:text>
  </xsl:if>

  <xsl:text>(function(i){</xsl:text>
    <!-- default; TODO: we don't always need this -->
    <xsl:text>var cdata = [];</xsl:text>

    <!-- do we have any restrictions on this API call? -->
    <xsl:for-each select="lv:unless-set">
      <!-- return immediately from the lambda if the value is already set -->
      <xsl:text>if(''+bucket.getDataByName('</xsl:text>
        <xsl:value-of select="@ref" />
      <xsl:text>')[i]!=='')return;</xsl:text>
    </xsl:for-each>


    <!-- prevents race conditions when triggering fieldLoading event -->
    <xsl:text>var doload=true;</xsl:text>

    <!-- TODO: duplicated  -->
    <xsl:text>var prediff=bucket.getDataByName('</xsl:text>
        <xsl:value-of select="../@id" />
    <xsl:text>');</xsl:text>

    <xsl:text>this.dapiManager.getApiData('</xsl:text>
      <xsl:value-of select="@source" />
    <xsl:text>', {</xsl:text>

      <!-- add each of the param lookups -->
      <xsl:for-each select="$params">
        <xsl:if test="position() > 1 ">
          <xsl:text>,</xsl:text>
        </xsl:if>

        <!-- the ref we need to look up for this param -->
        <xsl:variable name="ref" select="." />

        <!-- get the name associated with this param -->
        <xsl:variable name="pname"
          select="$self/@*[ . = $ref ]/local-name()" />

        <xsl:text>'</xsl:text>
          <xsl:value-of select="$pname" />
        <xsl:text>': </xsl:text>

        <xsl:variable name="bucket-data">
          <xsl:call-template name="parse-expected">
            <xsl:with-param name="expected" select="$ref" />
            <xsl:with-param name="with-diff" select="true()" />
          </xsl:call-template>
        </xsl:variable>

        <xsl:choose>
          <xsl:when test="substring( $ref, 1, 1 ) = &quot;'&quot;">
            <xsl:value-of select="$ref" />
          </xsl:when>

          <!-- -1 is the "combined" index -->
          <xsl:when test="$i = '-1'">
            <xsl:value-of select="$bucket-data" />
          </xsl:when>

          <xsl:otherwise>
            <xsl:value-of select="$bucket-data" />
            <xsl:text>[</xsl:text>
              <xsl:value-of select="$i" />
            <xsl:text>]</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>

      <xsl:text>},</xsl:text>

      <!-- once the data is returned, populate the field -->
      <xsl:text>function(err,retdata){doload=false;_self.dapiManager.setFieldData('</xsl:text>
        <xsl:value-of select="$qid" />
      <xsl:text>',</xsl:text>
        <xsl:value-of select="$i" />
      <xsl:text>,retdata,'</xsl:text>
        <xsl:value-of select="$value-map" />
      <xsl:text>','</xsl:text>
        <xsl:value-of select="$label-map" />
      <xsl:text>',(prediff[i]===cdata[i]))},</xsl:text>

    <xsl:text>'</xsl:text>
      <xsl:value-of select="$qid" />
    <xsl:text>',i,bucket,function(e){</xsl:text>
      <!-- on failure -->
      <xsl:text>_self.dapiManager.clearPendingApiCall('</xsl:text>
        <xsl:value-of select="$qid" />
      <xsl:text>_'+i);</xsl:text>

      <xsl:text>_self.dapiManager.fieldNotReady('</xsl:text>
        <xsl:value-of select="$qid" />
      <xsl:text>',</xsl:text>
        <xsl:value-of select="$i" />
      <xsl:text>,bucket);</xsl:text>

    <!-- end of getApiData() call -->
    <xsl:text>});</xsl:text>

    <!-- kick off an event allowing the UI/etc to indicate that the field
         is loading (we must do this *after* the call to ensure that this
         is only kicked off if there is no error) -->
    <xsl:text>if(doload){</xsl:text>
      <xsl:text>this.emit('fieldLoading','</xsl:text>
        <xsl:value-of select="$qid" />
      <xsl:text>',</xsl:text>
        <xsl:value-of select="$i" />
      <xsl:text>);</xsl:text>
    <xsl:text>}</xsl:text>
  <!-- invoke lambda with i to ensure that the value does not change on us -->
  <xsl:text>}).call(this,i);</xsl:text>
</xsl:template>


<xsl:template match="lv:data" mode="compiler:gen-data-map">
  <xsl:for-each select="./lv:map">
    <xsl:if test="position() > 1">
      <xsl:text>,</xsl:text>
    </xsl:if>

    <xsl:text>'</xsl:text>
      <xsl:value-of select="@into" />
    <xsl:text>':'</xsl:text>
      <xsl:value-of select="@param" />
    <xsl:text>'</xsl:text>
  </xsl:for-each>
</xsl:template>


<!--
  Handles param expansion when a field containing API data changes
-->
<xsl:template match="lv:question/lv:data" mode="compiler:compile">
  <!-- The change event is triggered on step load as well as the addition of
       any indexes, giving us the chance to initialize any API calls. This also
       allows us to initialize once on page load rather than once per param
       change event (which would be bad) -->
  <xsl:apply-templates select="." mode="compiler:compile-api-init" />

  <!-- we only care about the indexes that have actually changed -->
  <xsl:text>var diffdata=diff['</xsl:text>
      <xsl:value-of select="../@id" />
    <xsl:text>']||</xsl:text>
    <!-- we need to update the values for each field -->
    <xsl:text>bucket.getDataByName('</xsl:text>
      <xsl:value-of select="../@id" />
  <xsl:text>');</xsl:text>

  <xsl:text>var prediff=bucket.getDataByName('</xsl:text>
      <xsl:value-of select="../@id" />
  <xsl:text>');</xsl:text>

  <!-- XXX: duplicate -->
  <xsl:variable name="label-map">
    <xsl:choose>
      <!-- if a label map is given, use it -->
      <xsl:when test="./lv:label">
        <xsl:value-of select="./lv:label/@from" />
      </xsl:when>

      <!-- otherwise, default to the same value as the value map -->
      <xsl:otherwise>
        <xsl:value-of select="lv:value/@from" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:text>for(var i in diffdata){</xsl:text>
    <!-- null represents a removal -->
    <xsl:text>if(diffdata[i]===null){</xsl:text>
      <xsl:text>this.dapiManager.clearFieldData('</xsl:text>
        <xsl:value-of select="../@id" />
      <xsl:text>',i, false);</xsl:text>
      <xsl:text>continue;</xsl:text>
    <xsl:text>}</xsl:text>

    <xsl:text>if(this.dapiManager.hasFieldData('</xsl:text>
      <xsl:value-of select="../@id" />
    <xsl:text>',i)){</xsl:text>

      <!-- if we have no diff date, then this is probably triggered as the result
           of visiting the step; ensure that we populate the field if necessary
           -->
      <xsl:text>var expand=(prediff[i]!==diffdata[i]);</xsl:text>
      <xsl:text>if(!diff['</xsl:text>
        <xsl:value-of select="../@id" />
      <xsl:text>']){</xsl:text>
        <xsl:text>expand=this.dapiManager.triggerFieldUpdate('</xsl:text>
          <xsl:value-of select="../@id" />
        <xsl:text>',</xsl:text>
          <xsl:value-of select="'i'" />
        <xsl:text>,'</xsl:text>
          <xsl:value-of select="lv:value/@from" />
        <xsl:text>','</xsl:text>
          <xsl:value-of select="$label-map" />
        <xsl:text>',(cdata[i]===diffdata[i]));</xsl:text>
      <xsl:text>}</xsl:text>

      <!-- expand the data into the bucket (the last argument indicates that we
           can predictively set values knowing that the data for the value may
           become available in the near future) -->
      <xsl:text>if(expand)this.dapiManager.expandFieldData('</xsl:text>
        <xsl:value-of select="../@id" />
      <xsl:text>',i,bucket,{</xsl:text>
        <xsl:apply-templates select="." mode="compiler:gen-data-map" />
      <xsl:text>},true,diff);</xsl:text>
    <xsl:text>}</xsl:text>

  <xsl:text>}</xsl:text>
</xsl:template>


<!--
  If an API call has no arguments, then it must be populated immediately (since
  there are no other fields that could trigger its population)
-->
<xsl:template match="lv:question/lv:data" mode="compiler:compile-api-init">

  <xsl:variable name="qid" select="../@id" />

  <!-- marker to make it easier to find a section in the compiled code -->
  <xsl:text>/*dapiinit*/</xsl:text>

  <!-- current bucket data -->
  <xsl:text>var cdata=diff['</xsl:text>
    <xsl:value-of select="$qid" />
  <xsl:text>']||bucket.getDataByName('</xsl:text>
    <xsl:value-of select="$qid" />
  <xsl:text>');</xsl:text>

  <xsl:choose>
    <!-- combined call -->
    <xsl:when test="@source=//lv:api[ @combined='true' ]/@id">
      <!-- if we already have the API data, then we need only populate this
           field -->
      <xsl:text>if(this.dapiManager.hasFieldData('</xsl:text>
        <xsl:value-of select="$qid" />
      <xsl:text>')){</xsl:text>

        <!-- XXX: duplicate -->
        <xsl:variable name="label-map">
          <xsl:choose>
            <!-- if a label map is given, use it -->
            <xsl:when test="./lv:label">
              <xsl:value-of select="./lv:label/@from" />
            </xsl:when>

            <!-- otherwise, default to the same value as the value map -->
            <xsl:otherwise>
              <xsl:value-of select="lv:value/@from" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <!-- populate only the indexes that have changed -->
        <xsl:text>var cdiff=diff['</xsl:text>
          <xsl:value-of select="$qid" />
        <xsl:text>'];</xsl:text>
        <xsl:text>for(var i in cdiff){</xsl:text>

          <!-- do nothing if the data is unchanged -->
          <xsl:text>if(cdiff[i]||cdiff[i]===''){</xsl:text>

            <xsl:text>this.dapiManager.triggerFieldUpdate('</xsl:text>
              <xsl:value-of select="$qid" />
            <xsl:text>',</xsl:text>
              <xsl:value-of select="'i'" />
            <xsl:text>,'</xsl:text>
              <xsl:value-of select="lv:value/@from" />
            <xsl:text>','</xsl:text>
              <xsl:value-of select="$label-map" />
            <xsl:text>',(cdata[i]===cdiff[i]));</xsl:text>

          <xsl:text>}</xsl:text>

        <xsl:text>}</xsl:text>

      <!-- otherwise, we do not yet have any data; perform the API call -->
      <xsl:text>}else{</xsl:text>
        <xsl:apply-templates select="." mode="compiler:api-trigger" />
      <xsl:text>}</xsl:text>
    </xsl:when>

    <!-- per-index -->
    <xsl:otherwise>
      <!-- check each existing index -->
      <xsl:text>for(var i in cdata){</xsl:text>

        <!-- populate the field if it does not yet have any data -->
        <xsl:text>if(!this.dapiManager.hasFieldData('</xsl:text>
          <xsl:value-of select="$qid" />
        <xsl:text>',i)){</xsl:text>

          <!-- trigger the API call for this index -->
          <xsl:apply-templates select="." mode="compiler:api-trigger">
            <xsl:with-param name="i" select="'i'" />
          </xsl:apply-templates>

        <xsl:text>}</xsl:text>
      <xsl:text>}</xsl:text>
    </xsl:otherwise>
  </xsl:choose>

</xsl:template>


</xsl:stylesheet>

