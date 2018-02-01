<?xml version="1.0"?>
<!--
  Builds Program JavaScript classes to be used both server and client side

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
-->
<stylesheet version="2.0"
            xmlns="http://www.w3.org/1999/XSL/Transform"
            xmlns:lv="http://www.lovullo.com"
            xmlns:compiler="http://www.lovullo.com/program/compiler"
            xmlns:assert="http://www.lovullo.com/assert"
            xmlns:st="http://www.lovullo.com/liza/proguic/util/struct"
            xmlns:preproc="http://www.lovullo.com/program/preprocessor">

<output method="text"
        indent="yes"
        omit-xml-declaration="yes" />

<!-- todo: way to remove? Needed by questions -->
<variable name="debug" select="false()" />

<!-- metadata -->
<include href="program-build-meta.xsl" />

<!-- calculated value methods -->
<include href="program-calc-methods.xsl" />

<!-- data APIs -->
<include href="program-data-api.xsl" />

<!-- questions -->
<include href="question/question.xsl" />

<param name="include-path" />


<!--
  Compilation entry point
-->
<template match="/lv:program">
  <apply-templates select="." mode="compiler:compile" />
</template>


<!--
  Prevent compilation in the event of preprocessor errors

  This will output all preprocessor errors to stdout and terminate, failing compilation.
-->
<template match="/lv:program[ .//preproc:error ]" mode="compiler:compile" priority="9">
  <!-- terminate with the preprocessor error messages -->
  <for-each select=".//preproc:error">
    <message>
      <text>[Preprocessor error] </text>
      <value-of select="." />
    </message>
  </for-each>

  <!-- finally, abort -->
  <!-- Yes, this is incredibly obnoxious! However, due to all the other build
       output, it's likely that it may not even be seen otherwise. -->
  <message>***********************************************</message>
  <message>*** Terminating due to preprocessor errors. ***</message>
  <message>***********************************************</message>
  <message terminate="yes">Compilation failed.</message>
</template>


<!--
  Compile source tree (kicked off after preprocessing)

  Note that this has a low priority, so it will only kick off if there are no
  other matches (e.g. matches for preprocessor errors)
-->
<template match="/lv:program" mode="compiler:compile" priority="1">
  <!-- require XSLT 2.0 parser -->
  <if test="number(system-property('version')) &lt; 2.0">
    <message terminate="yes">XSLT 2.0 processor required</message>
  </if>

  <!-- generate program path name -->
  <variable name="path-program" select="lower-case(@id)"/>

  <!-- includes must be kept separate from the program file, as they are not
       intended for the server. The program file is shared with both the server
       and the client. -->
  <!-- TODO: separate into sepaate build; we can't add a Makefile
       target for this -->
  <result-document href="include.js">
    <apply-templates select="lv:include" mode="build-pre" />
  </result-document>

  <!-- generate program file -->
  <apply-templates select="." mode="build-program-class" />
</template>


<template match="/lv:program/lv:include" mode="build-pre">
  <variable name="path"
                select="concat( $include-path, '/', @src )" />
  <variable name="module"
                select="if ( @as ) then
                          @as
                        else
                          replace( @src, '.js', '' )" />

  <!-- include script, wrapping it as a CommonJS module with the same name as
       the path, sans the .js extension -->
  <text>(function(require,module){var exports=module.exports={};</text>
  <value-of select="unparsed-text( $path, 'iso-8859-1' )" disable-output-escaping="yes" />
  <text>})(require,modules['</text>
  <value-of select="$module" />
  <text>']={});</text>
</template>


<template match="/lv:program" mode="build-program-class">
  <text>var Calc=require('program/Calc');</text>
  <text>var BaseAssertions=require('assert/BaseAssertions');</text>
  <text>var Program=require('program/Program').Program;</text>

  <text>module.exports=Program.extend({</text>
    <text>id:'</text><value-of select="@id" /><text>',</text>
    <text>version:'</text><value-of select="@version" /><text>',</text>
    <text>title:'</text><value-of select="@title" /><text>',</text>
    <text>steps:[</text><call-template name="build-steps" /><text>],</text>
    <text>help:{</text><call-template name="build-help" /><text>},</text>
    <text>internal:{</text><call-template name="build-internal" /><text>},</text>
    <text>defaults:{</text><call-template name="build-defaults" /><text>},</text>
    <text>displayDefaults:{</text><call-template name="build-display-defaults" /><text>},</text>
    <text>groupIndexField:{</text><call-template name="build-group-index-fields" /><text>},</text>
    <text>groupFields:{</text><call-template name="build-group-fields" /><text>},</text>
    <text>groupUserFields:{</text>
      <call-template name="build-group-fields">
        <with-param name="linked" select="false()" />
        <with-param name="visonly" select="true()" />
      </call-template>
    <text>},</text>
    <text>groupExclusiveFields:{</text><call-template name="build-group-fields"><with-param name="linked" select="false()" /></call-template><text>},</text>
    <text>links:{</text><call-template name="build-linked-fields" /><text>},</text>
    <text>classes:{</text><call-template name="build-field-classes" /><text>},</text>
    <text>cretain:{</text><call-template name="build-field-retains" /><text>},</text>
    <text>whens:{</text><call-template name="build-field-when" /><text>},</text>
    <text>qwhens:{</text><call-template name="build-qwhen-list" /><text>},</text>
    <text>kbclear:{</text><call-template name="build-kbclear" /><text>},</text>
    <text>requiredFields:{</text><call-template name="build-required-fields" /><text>},</text>
    <text>meta:</text><call-template name="build-meta" /><text>,</text>
    <text>secureFields:[</text><call-template name="build-secure-fields" /><text>],</text>
    <text>unlockable:</text><value-of select="if ( @unlockable ) then 'true' else 'false'" /><text>,</text>
    <text>discardable:[</text><call-template name="build-discard" /><text>],</text>
    <text>rateSteps:[</text><call-template name="build-rate-steps" /><text>],</text>
    <text>ineligibleLockCount:</text>
      <value-of select="if ( @ineligibleLockCount ) then @ineligibleLockCount else '0'" />
      <text>,</text>
    <text>isInternal:false,</text>

    <!-- determine an appropriate first step id -->
    <text>firstStepId:</text><call-template name="get-fist-step-id" /><text>,</text>

    <text>sidebar:{</text>
      <text>static_content: '</text>
      <for-each select="lv:sidebar/lv:static">
          <apply-templates select="." mode="generate-static" />
      </for-each>
      <text>',</text>
      <text>overview:{</text>
        <call-template name="build-sidebar-overview" />
    <text>}},</text>

    <!-- data APIs -->
    <text>apis:</text>
      <apply-templates select="." mode="compiler:compile-apis" />
      <text>,</text>
    <text>mapis:</text>
      <sequence select="st:to-json(
                          st:dict(
                            st:group-items-by-key(
                              ( for $ref in lv:meta/lv:field/lv:data
                                    /@*[ not( local-name() = 'source' ) ]
                                  return st:item( $ref/ancestor::lv:field/@id,
                                                  string( $ref ) ) ) ) ) )" />
      <text>,</text>

    <text>initQuote:</text><call-template name="build-init" /><text>,</text>

    <!-- classifier module -->
    <text>'protected classifier':</text>'<value-of select="@classifier" /><text>',</text>

    <!-- export services -->
    <text>export_path: {</text>
    <text>c1: '</text>
      <value-of select="@c1-import-path" />
    <text>'},</text>

    <!-- sorted group sets -->
    <text>sortedGroups:[</text><call-template name="compiler:gen-sorted-groups" /><text>],</text>

    <!-- build the event data for each step -->
    <text>eventData:(function(){</text>
      <text>var ret_data=[];</text>
      <apply-templates select="lv:step" mode="build-program-class">
        <with-param name="ret" select="'ret_data'" />
      </apply-templates>

      <text>return ret_data;</text>
    <text>})()</text>
  <text>});</text>
</template>


<!--
  Generates array containing step titles
-->
<template name="build-steps">
  <for-each select="//lv:step">
    <!-- since there is no step 0, always add delimiter -->
    <text>,</text>

    <text>{title:'</text>
    <value-of select="@title" />
    <text>',type:'</text>
    <value-of select="@type" />
    <text>'}</text>
  </for-each>
</template>


<template match="lv:step" mode="build-program-class">
  <param name="ret" />

  <!-- represents the event data we'll be updating -->
  <variable name="eventData">
    <value-of select="$ret" /><text>[</text>
      <value-of select="position()" />
    <text>]</text>
  </variable>

  <variable name="step" select="current()" />

  <text>
/*step</text><value-of select="position()" />
    <text>(</text><value-of select="@title" />
    <text>)*/</text>

  <!-- initialize the variable -->
  <value-of select="$eventData" /><text>={};</text>

  <!-- question-based assertion events -->
  <for-each select="('submit', 'change', 'forward', 'dapi')">
    <call-template name="parse-assert-events">
      <with-param name="eventData" select="$eventData" />
      <with-param name="type" select="." />
      <with-param name="step" select="$step" />

      <with-param name="default" select="if ( current() = 'submit' ) then true() else false()" />
      <with-param name="perQuestion"
                      select="( current() = 'change' )
                              or ( current() = 'dapi' )" />
    </call-template>
  </for-each>

  <!-- non-question (and non-assertion) events -->
  <for-each select="('beforeLoad', 'postSubmit', 'visit')">
    <call-template name="parse-events">
      <with-param name="eventData" select="$eventData" />
      <with-param name="type" select="." />
      <with-param name="step" select="$step" />
    </call-template>
  </for-each>

  <!-- actions -->
  <value-of select="$eventData" />
  <text>.action={</text>
    <for-each select=".//lv:question[ ./lv:action ]">
      <if test="position() > 1">
        <text>,</text>
      </if>

      <apply-templates select="." mode="build-actions">
        <with-param name="eventData" select="$eventData" />
      </apply-templates>
    </for-each>
  <text>};</text>
</template>


<template match="lv:question[ ./lv:action ]" mode="build-actions">
  <param name="eventData" />

  <text>'</text>
    <value-of select="@id" />
  <text>':{</text>

    <!-- build each action -->
    <for-each select="./lv:action">
      <if test="position() > 1">
        <text>,</text>
      </if>

      <apply-templates select="." mode="build-actions" />
    </for-each>

  <text>}</text>
</template>


<template match="lv:question/lv:action" mode="build-actions">
  <text>'</text>
    <value-of select="@on" />
  <text>':function(trigger_callback,bucket,index){</text>
    <!-- no diff support yet (doesn't make sense at the time of writing) -->
    <text>var diff={};</text>

    <!-- compile triggers -->
    <apply-templates select="./lv:trigger" mode="gen-trigger">
      <with-param name="question_id_default" select="ancestor::lv:question/@id" />
      <!-- the triggers expect an array of indexes, so just create an array
           from the single index that we were given (actions will never be
           performed on more than one index...at least not with the current
           implementation) -->
      <with-param name="indexes" select="'[index]'" />
    </apply-templates>

  <text>}</text>
</template>


<template name="parse-script-events">
  <param name="type" />
  <param name="step" />

  <!-- simply inject the script (whoopie!) -->
  <variable name="script"
    select="$step/lv:script[ contains( @onEvent, $type ) ]" />

  <!-- if a script was found, enclose it in a closure (so that the vars we
       define don't screw with the remainder of the script) and inject it
  -->
  <if test="$script">
    <text>(function(){</text>
    <value-of select="$script" />
    <text>})();</text>
  </if>
</template>


<!--
  Generates assertions for the given event (non-assertion)

  @param xs:string type        event type
  @param xs:string eventData   string representing the variable to assign
                               generated function to
  @param node      step        step node
  @param xs:bool   default     whether this event is the default (can be blank)
-->
<template name="parse-events">
  <param name="type" />
  <param name="eventData" />
  <param name="step" />
  <param name="default" select="false()" />

  <!-- locate all assertion-less triggers that are direct descendants of the step node -->
  <variable name="triggerdata">
    <for-each select="$step/lv:trigger[ ( $default = true() and not(@onEvent) ) or contains(@onEvent, $type) ]">
      <apply-templates select="." mode="gen-trigger">
        <with-param name="question_id_default" select="''" />
      </apply-templates>
    </for-each>
  </variable>

  <!-- parse scripts for this event -->
  <variable name="scriptdata">
    <for-each select="$step/lv:script[ contains(@onEvent, $type) ]">
      <call-template name="parse-script-events">
        <with-param name="type" select="$type" />
        <with-param name="step" select="$step" />
      </call-template>
    </for-each>
  </variable>

  <!-- append data, if we generated anything (IMPORTANT: we must not output
       anything if it is not necessary, as this is a crucial assumption made by
       the system) -->
  <if test="( string-length( $triggerdata ) > 0 ) or ( string-length( $scriptdata ) > 0 )">
    <value-of select="$eventData" />.<value-of select="$type" />
    <text>=function(trigger_callback,bucket){</text>
    <value-of select="$triggerdata" />
    <value-of select="$scriptdata" />
    <text>};</text>
  </if>
</template>


<!--
  Generates assertions for the given question-based assertion event

  @param xs:string type        event type
  @param xs:string eventData   string representing the variable to assign
                               generated function to
  @param node      step        step node
  @param xs:bool   default     whether this event is the default (can be blank)
  @param xs:bool   perQuestion generate assertions for each question rather
                               than each step
-->
<template name="parse-assert-events">
  <param name="type" />
  <param name="eventData" />
  <param name="step" />
  <param name="default" select="false()" />
  <param name="perQuestion" select="false()" />

  <variable name="funcTop">
    <text>=function(bucket,diff,cmatch,trigger_callback){</text>
      <text>var fail={},failed=false,causes=[];</text>
      <text>var retval=true;</text>
  </variable>

  <variable name="scripts">
    <!-- process scripts within the XML -->
    <call-template name="parse-script-events">
      <with-param name="type" select="$type" />
      <with-param name="step" select="$step" />
    </call-template>
  </variable>

  <variable name="funcBottom">
      <!-- if we have no failures, return null to indicate that everything
           looks good -->
      <text>return (failed)?fail:null;</text>
    <text>};</text>
  </variable>

  <!-- normal, big chuncks -->
  <if test="not($perQuestion)">
    <!-- This complicated XPath expression will find all assertions that we are
         interested in. That is:

           - All assertions for questions and question-copies that are part of
           the given step
           - All assertions for question-copy references (to copy assertions)

         Each of the above must meet the following criteria:

           - We must be processing the default ($default) and there must be no
             lv:onEvent attribute, or
           - The assertion must contain the requested event as the value of
             lv:onEvent
    -->
    <variable name="assertions"
      select="( $step//*[local-name()='question' or local-name()='question-copy']
              | $step/..//lv:question[ @id = $step//lv:question-copy/@ref ]
              )/assert:*[ ( $default = true() and not(@lv:onEvent) ) or contains(@lv:onEvent, $type) ]
              "
      />

    <!-- only add the function if we have assertions to put into it -->
    <if test="$assertions or $scripts">
      <value-of select="$eventData" />.<value-of select="$type" />
      <value-of select="$funcTop" />

      <value-of select="$scripts" />

      <!-- generate each of the assertions -->
      <for-each select="$assertions">
        <apply-templates select="." mode="gen-assert" />
      </for-each>

      <value-of select="$funcBottom" />
    </if>
  </if>
  <!-- otherwise, per-question chunks -->
  <if test="$perQuestion">
    <value-of select="$eventData" />
    <text>.</text>
    <value-of select="$type" />
    <text>={};</text>

    <for-each select="$step//lv:question | $step//lv:question-copy
                          | $step//lv:external">
      <call-template name="gen-per-question">
        <with-param name="eventData" select="$eventData" />
        <with-param name="funcTop" select="$funcTop" />
        <with-param name="funcBottom" select="$funcBottom" />
        <with-param name="type" select="$type" />
      </call-template>
    </for-each>
  </if>
</template>


<!--
  Post-parse question-based events

  This template is used in the event that certain events wish to add additional
  data to an event *before* the assertions are performed. For example,
  calculated values are tied to the 'change' event and we wish for their values
  to be available to the assertions.

  @param string type event type
  @param string id   question id (optional)
-->
<template name="pre-parse-question-event">
  <param name="type" />
  <param name="id" select="@id" />

  <!-- if we don't calculate the calculated values before assertions, then
       their values may lag behind in undefined circumstances -->
  <if test="$type = 'change'">
    <call-template name="gen-calc-for-id">
      <with-param name="id" select="$id" />
    </call-template>
  </if>
</template>


<template name="gen-calc-for-id">
  <param name="id" />

  <apply-templates select="//lv:calc[@ref=$id or @value=$id]" mode="gen-calc">
    <with-param name="deps" select="true()" />
    <with-param name="children" select="true()" />
  </apply-templates>
</template>


<!--
  Post-parse question-based events

  This template is used in the event that certain events wish to add additional
  data to an event.

  @param string type event type
  @param string id   question id (optional)
-->
<template name="post-parse-question-event">
  <param name="type" />
  <param name="id" select="@id" />
  <param name="eventData" />

  <apply-templates select="//lv:question[ @id=$id ]" mode="post-parse-question-event">
    <with-param name="type"      select="$type" />
    <with-param name="id"        select="$id" />
    <with-param name="eventData" select="$eventData" />
  </apply-templates>
</template>

<template match="*" mode="post-parse-question-event" priority="1">
  <!-- catch-all; do nothing -->
</template>


<template name="gen-per-question">
  <param name="eventData" />
  <param name="funcTop" />
  <param name="funcBottom" />
  <param name="type" />
  <param name="id" select="@id | @ref" />

  <variable name="assertions"
    select="assert:*[ contains(@lv:onEvent, $type) ]" />

  <variable name="preParse">
    <!-- certain things should be done before assertions -->
    <call-template name="pre-parse-question-event">
      <with-param name="type" select="$type" />
      <with-param name="id" select="$id" />
    </call-template>
  </variable>

  <variable name="postParse">
    <!-- we may want to append some code to the function -->
    <call-template name="post-parse-question-event">
      <with-param name="type"      select="$type" />
      <with-param name="id"        select="$id" />
      <with-param name="eventData" select="$eventData" />
    </call-template>

    <!-- add any dynamic defaults -->
    <call-template name="gen-dynamic-defaults">
      <with-param name="change_id" select="$id" />
    </call-template>
  </variable>

  <!-- only add the function if we have some assertions or post-parse data -->
  <if test="
      $assertions
      or ( string-length( $preParse ) > 0 )
      or ( string-length( $postParse ) > 0 )
    ">

    <value-of select="$eventData" />.<value-of select="$type" />
    <text>['</text>
    <value-of select="$id" />
    <text>']</text>

    <value-of select="$funcTop" />

    <value-of select="$preParse" />

    <for-each select="$assertions">
      <apply-templates select="." mode="gen-assert" />
    </for-each>

    <!-- add assertions that reference this question -->
    <for-each select="../../lv:group/*[local-name()='question' or local-name()='question-copy']/assert:*[ contains(@lv:onEvent, $type) and @value = $id ]">
      <apply-templates select="." mode="gen-assert" />
    </for-each>

    <value-of select="$postParse" />

    <value-of select="$funcBottom" />
  </if>
</template>


<!-- XXX: Refactor into a common function which can simply be called here -->
<template name="gen-dynamic-defaults">
  <param name="change_id" />

  <for-each select="//lv:question[@defaultTo = $change_id]">
    <!-- get default and current data and initialize an array to store the new
         data to be set -->
    <text>(function(){</text>
      <text>var ddata=</text>
        <call-template name="parse-expected">
          <with-param name="expected" select="$change_id" />
          <with-param name="with-diff" select="true()" />
        </call-template>
      <text>,</text>
      <text>curdata=</text>
        <call-template name="parse-expected">
          <with-param name="expected" select="@id" />
          <with-param name="with-diff" select="true()" />
        </call-template>
      <text>,newdata=[],chgi=0;</text>

      <!-- replace only empty values -->
      <text>for(var i in ddata){</text>
        <text>if(curdata[i]){newdata[i]=curdata[i];continue;}</text>
        <text>if(!ddata[i])continue;</text>
        <text>newdata[i]=ddata[i];chgi++;</text>
      <text>}</text>

      <!-- don't bother doing anything if no changes are to be made -->
      <text>if(chgi===0)return;</text>

      <!-- perform overwrite with new data -->
      <text>bucket.overwriteValues({'</text>
      <value-of select="@id" />
      <text>':newdata});</text>
    <text>})();</text>
  </for-each>
</template>


<template name="parse-expected">
  <param name="expected">
    <!-- use value attribute if available -->
    <if test="@value">
      <value-of select="@value" />
    </if>
    <!-- otherwise attempt to use value list -->
    <if test="not( @value )">
      <text>'</text>
      <for-each select="assert:value">
        <if test="position() > 1 ">
          <text>,</text>
        </if>
        <value-of select="replace( node(), &quot;'&quot;, &quot;\\'&quot; )" />
      </for-each>
      <text>'</text>
    </if>
  </param>
  <param name="with-diff" select="false()" />
  <param name="merge-diff" select="false()" />
  <param name="bracket" select="true()" />
  <param name="for-each" />

  <choose>
    <!-- explicit value -->
    <when test="starts-with( $expected, &quot;'&quot; )">
      <text>[</text><value-of select="$expected" /><text>]</text>
    </when>

    <!-- cmatch reference -->
    <when test="starts-with( $expected, 'c:' )">
      <text>((cmatch['</text>
        <value-of select="substring-after( $expected, ':' )" />
      <text>']||{}).indexes||[])</text>
    </when>

    <!-- bucket reference -->
    <otherwise>
      <!-- we'll need to make this an array, since we'll be selecting a single index -->
      <if test="@forEach and $bracket">
        <text>[</text>
      </if>

      <!-- get the value without any index included -->
      <variable name="field-id" select="
          if ( contains( $expected, '[' ) ) then
            substring-before( $expected, '[' )
          else
            $expected
        " />

      <text>(</text>
      <choose>
        <when test="$merge-diff">
          <text>bucket.getPendingDataByName('</text>
            <value-of select="$field-id" />
          <text>',diff)</text>
        </when>

        <otherwise>
          <if test="$with-diff">
            <text>diff['</text>
            <value-of select="$field-id" />
            <text>'] || </text>
          </if>
          <text>bucket.getDataByName('</text>
            <value-of select="$field-id" />
          <text>')</text>
        </otherwise>
      </choose>
      <text>)</text>

      <choose>
        <!-- if an index was provided, use it -->
        <when test="contains( $expected, '[' )">
          <text>[</text>
          <value-of select="substring-after( $expected, '[' )" />
        </when>

        <!-- if a forEach was provided, ensure we check the associated index -->
        <when test="$for-each">
          <text>[gi]</text>
        </when>

        <otherwise>
          <!-- nothing -->
        </otherwise>
      </choose>

      <if test="@forEach and $bracket">
        <text>]</text>
      </if>
    </otherwise>
  </choose>
</template>


<template match="assert:success" mode="gen-assert-expected-result">
  <text>true</text>
</template>
<template match="assert:failure" mode="gen-assert-expected-result">
  <text>false</text>
</template>

<template match="assert:success" mode="gen-assert-getset">
  <text>Successes</text>
</template>
<template match="assert:failure" mode="gen-assert-getset">
  <text>Failures</text>
</template>


<!--
  Success/failure group header

  This should be output only on the first of a set of success/failure groups,
  otherwise the values for the contained variables would be reset for each
  group.
-->
<template match="
  assert:success[ not( preceding-sibling::assert:success ) ]
  |assert:failure[ not( preceding-sibling::assert:failure) ]
" mode="gen-assert-group-head">

  <text>var count=0;</text>
  <text>var retval=true;</text>

  <!-- this var will hold the successes or failures -->
  <text>var results=(gi!==undefined)?[gi]:assertion.get</text>
    <apply-templates select="." mode="gen-assert-getset" />
  <text>();</text>
</template>

<!--
  Success/failure group footer

  This should be output only on the last of a set of success/failure groups,
  otherwise the compiled function will return prematurely.
-->
<template match="
  assert:success[ not( following-sibling::assert:success ) ]
  |assert:failure[ not( following-sibling::assert:failure) ]
" mode="gen-assert-group-tail">

  <!-- if there were no assertions, default to returning the value associated
       with the type of group -->
  <text>return(count==0)?</text>
    <apply-templates select="." mode="gen-assert-expected-result" />
  <text>:retval;</text>
</template>


<!--
  Compile sub-assertions and triggers associated with a particular
  success/failure group.
-->
<template match="assert:success|assert:failure" mode="gen-assert-group">
  <param name="question_id" />

  <variable name="self" select="." />

  <!-- e.g. Successes/Failures to be translated into get*/set* -->
  <variable name="result-getset">
    <apply-templates select="." mode="gen-assert-getset" />
  </variable>

  <!-- Boolean value representing what result we would expected to be a "good
       thing" for this group with regards to sub-assertions; that is, in a
       success group, if we have all succeeding sub-assertions, then we need
       not do anything. However, in a failure group, succeeding sub-assertions
       would require that we take another action (since failure is no longer
       the case). -->
  <variable name="expected-result">
    <apply-templates select="." mode="gen-assert-expected-result" />
  </variable>

  <apply-templates select="." mode="gen-assert-group-head" />

  <if test="@associative">
    <!-- if we are NOT nested inside a previous associative assertion,
         then get the list of failed items.

         otherwise, use the previously failed index to ensure we do not
         break the mapping (FS#5769) -->
    <if test="not( ../@associative )">
      <!-- get results from the previous (failed) assertion -->
      <text>var i=0,len=results.length;</text>
    </if>

      <!-- triggers (must be done before looping to ensure the original
           results are triggered ) -->
      <apply-templates select="./lv:trigger" mode="gen-trigger">
        <with-param name="question_id_default" select="$question_id" />
        <with-param name="indexes" select="'results'" />
      </apply-templates>

    <if test="not( ../@associative )">
      <!-- loop over all the results -->
      <text>for(var i=0,len=results.length;i&lt;len;i++){</text>
    </if>

        <text>var index=results[i];</text>

        <!-- We can only break out of the loop if we're actually in the
             loop. This check is unnecessary if we're not. -->
        <if test="not( ../@associative )">
          <text>if(index===undefined){</text>
              <text>continue;</text>
          <text>}</text>
        </if>

        <!-- generates success array for this index -->
        <text>var this_result = [];this_result[i]=i;</text>

        <if test="./assert:*">
          <text>var result=</text>
            <for-each select="./assert:*">
              <!-- join siblings with a logical and -->
              <if test="position() > 1">
                <text>&amp;&amp;</text>
              </if>

              <!-- XXX: we'll need to do a bit more refactoring to resolve this mess -->
              <variable name="fail-index">
                <if test="local-name( $self ) = 'failure'">
                  <text>this_result</text>
                </if>
              </variable>

              <apply-templates select="." mode="gen-assert">
                <with-param name="question_id_default" select="$question_id" />
                <with-param name="trackCount" select="true()" />
                <with-param name="failIndex" select="$fail-index" />
                <with-param name="result-var" select="'index'" />
                <with-param name="givenPrefix">
                  <text>[</text>
                </with-param>
                <with-param name="givenSuffix">
                  <text>[index]]</text>
                </with-param>
                <!-- suppress semicolon at the end of the block so that
                     they may be chained -->
                <with-param name="semicolon" select="false()" />
              </apply-templates>
            </for-each>
            <text>;</text>

          <!-- remove from success list if failed -->
          <text>if(result!==</text>
            <value-of select="$expected-result" />
          <text>){</text>
              <text>delete results[i];</text>
          <text>}else{retval=false;}</text>
       </if>

    <!-- we will have only looped if we aren't a nested associative
         success -->
    <if test="not( ../@associative )">
      <text>}</text>
    </if>

    <text>assertion.set</text>
      <value-of select="$result-getset" />
    <text>(results);</text>
  </if>

  <!-- non-associative triggers -->
  <if test="not( @associative )">
    <apply-templates select="./lv:trigger" mode="gen-trigger">
      <with-param name="question_id_default" select="$question_id" />
      <with-param name="indexes" select="'results'" />
    </apply-templates>

    <apply-templates select="./assert:*" mode="gen-assert">
      <with-param name="question_id_default" select="$question_id" />
      <with-param name="trackCount" select="true()" />
    </apply-templates>
  </if>

  <apply-templates select="." mode="gen-assert-group-tail" />
</template>


<template match="assert:*" mode="gen-assert">
  <param name="question_id_default" select="if ( ../@id ) then ../@id else ../@ref" />
  <param name="expected">
    <call-template name="parse-expected">
      <with-param name="with-diff" select="true()" />
      <with-param name="for-each" select="@forEach" />
    </call-template>
  </param>
  <param name="name" select="local-name(.)" />
  <param name="trackCount" select="false()" />
  <param name="failIndex" />

  <!-- used for cmatch checks -->
  <param name="result-var" />

  <!-- TODO: There's better ways of doing this; this will simply allow us to
       suppress the semicolon insertion at the end of the generated block so
       that the assertions may be chained -->
  <param name="semicolon" select="true()" />

  <param name="ref" select="@ref" />
  <param name="question_id" select="if ( $ref ) then $ref else $question_id_default" />
  <param name="root_question_id" select="ancestor::lv:question/@id|ancestor::lv:question-copy/@ref" />

  <!-- generate question id to reference on failure (@failOn can be used on an
       assertion to override this) -->
  <param name="failOn" select="@failOn" />
  <param name="failure_question_id" select="$root_question_id" />

  <param name="givenPrefix" select="''" />
  <param name="givenSuffix" select="''" />

  <param name="is-cref" select="starts-with( $question_id, 'c:' )" />
  <param name="given">
    <choose>
      <when test="$is-cref">
        <text>(((cmatch||{__classes:{}}).__classes['</text>
          <value-of select="substring-after( $question_id, ':' )" />
        <text>']||{}).indexes||[])</text>
      </when>

      <otherwise>
        <!-- if we're looking at a specific index, we need to ensure the result is
             still an array -->
        <if test="contains( $question_id, '[' )">
          <text>[</text>
        </if>

        <value-of select="$givenPrefix" />
        <call-template name="parse-expected">
          <with-param name="expected" select="$question_id" />
          <with-param name="with-diff" select="true()" />
          <with-param name="bracket" select="false()" />
        </call-template>
        <value-of select="$givenSuffix" />

        <!-- if we're looking at a specific index, we need to ensure the result is
             still an array -->
        <if test="contains( $question_id, '[' )">
          <text>]</text>
        </if>
      </otherwise>
    </choose>
  </param>

  <!-- make debugging a little easier -->
  <variable name="marker">
    <copy-of select="name()" />

    <for-each select="@*">
      <text> </text>

      <value-of select="local-name()" />
      <text>=</text>
      <value-of select="." />
    </for-each>
  </variable>

  <text>/***begin </text>
    <value-of select="$marker" />
  <text>***/</text>

  <!-- whether to do assertion value by value -->
  <variable name="forEach" select="if ( @forEach = 'true' ) then true() else false()" />

  <!-- whether the assertion is internal only -->
  <variable name="internalOnly" select="if ( @lv:internal = 'true' ) then true() else false()" />

  <!-- classification to which this assertion applies -->
  <variable name="when-ignore" select="@whenIgnore" />

  <!-- message to display on error -->
  <variable name="message">
    <if test="./assert:message">
      <apply-templates select="./assert:message" />
    </if>
    <if test="not(./assert:message)">
      <text>The value for "</text>
        <value-of select="if ( $ref ) then //lv:question[@id=$ref]/@label else ../@label" />
      <text>" </text>
      <apply-templates select="." mode="assert-default-message" />
    </if>
  </variable>

  <!-- whether the message is dynamic -->
  <variable name="message-dynamic" select="./assert:message/lv:*" />

  <!-- the assertion we'll be calling -->
  <variable name="assertion">
    <text>BaseAssertions.</text><value-of select="$name" />
  </variable>

  <!-- success group callback -->
  <variable name="success">
    <text>/***s </text>
      <value-of select="$marker" />
    <text>***/</text>

    <choose>
      <when test="./assert:success">
        <text>function(){</text>
          <apply-templates select="./assert:success" mode="gen-assert-group">
            <with-param name="question_id" select="$question_id" />
          </apply-templates>
        <text>}</text>
      </when>

      <!-- no success group -->
      <otherwise>
        <text>null</text>
      </otherwise>
    </choose>
  </variable>

  <!-- failure group callback -->
  <variable name="failure">
    <text>/***f </text>
      <value-of select="$marker" />
    <text>***/</text>

    <choose>
      <when test="./assert:failure">
        <text>function(){</text>
          <apply-templates select="./assert:failure" mode="gen-assert-group">
            <with-param name="question_id" select="$question_id" />
          </apply-templates>
        <text>}</text>
      </when>

      <!-- no failure group -->
      <otherwise>
        <text>null</text>
      </otherwise>
    </choose>
  </variable>

  <!-- some assertions should be performed only for users logged in internally -->
  <if test="$internalOnly">
    <text>if(this.isInternal){</text>
  </if>

  <text>(function(assertion){</text>
      <if test="$trackCount">
        <text>count++;</text>
      </if>

      <!-- if forEach was given, we need to loop through them individually -->
      <if test="$forEach = true()">
        <text>var given_data=</text>
        <value-of select="$given" />
        <text>;for(var gi in given_data){</text>
          <text>var given_val=given_data[gi];</text>
      </if>
      <!-- Otherwise, we have to define gi so we don't get a ReferenceError,
           UNLESS we have a previous assertion, in which case it's already
           defined. We do *not* want to clear this out if it's already defined
           because it will destroy nested assertions. (See FS#6304)
      -->
      <if test="$forEach != true() and local-name(..)='question'">
        <text>var gi=undefined;</text>
      </if>

      <!-- Stores failure id so that it can be overridden by @failOn. This does
           not get set (so that failures will set on the parent assertion if
           @recordFailure is false -->
      <if test="not( @recordFailure = false() )">
        <text>var failid='</text>
        <value-of select="if (@failOn) then @failOn else $failure_question_id" />
        <text>';</text>
      </if>

      <!-- allow ignoring cmatch @when's -->
      <text>var when_ignore=</text>
        <choose>
          <when test="$when-ignore = 'true'">
            <text>true</text>
          </when>

          <otherwise>
            <text>false</text>
          </otherwise>
        </choose>
      <text>;</text>

      <if test="not( ancestor::assert:* )">
        <text>var causes=[];</text>
      </if>

      <!-- we only wish to perform the assertions if the field matches its
           given classification (using the provided cmatch object);
           specifically, skip all assertions on this field unless there is at
           least one match (note also that we default to an any:true object,
           with the assumption being that, if no cmatch is found, then no rules
           exist for that field and we should proceed as normal) -->
      <text>if(when_ignore||(cmatch['</text>
        <value-of select="$question_id" />
      <text>']||{any:true}).any){</text>

        <text>causes.push('</text>
          <value-of select="$question_id" />
        <text>');</text>

        <!-- compile assertion logic -->
        <text>if(this.doAssertion(assertion,'</text>
          <value-of select="$question_id" />
          <text>',</text>
          <value-of select="$expected" />
          <text>,</text>
          <if test="$forEach = true()">
            <!-- must be passed in as an array -->
            <text>[given_val]</text>
          </if>
          <if test="$forEach != true()">
            <value-of select="$given" />
          </if>
          <text>,</text><value-of select="$success" />
          <text>,</text><value-of select="$failure" />
          <text>,</text>
          <value-of select="if ( @recordFailure = false() ) then 'false' else 'true'" />
          <text>)===false){</text>
            <if test="not( @recordFailure = false() )">
              <text>var r=</text>
                <value-of select="
                    if ( $forEach = true() ) then
                      '[gi]'
                    else if ( string-length( $result-var ) > 0 ) then
                      concat( '[', $result-var, ']' )
                    else
                      'assertion.getFailures()'
                  " />
              <text>;</text>

              <!-- at this point, filter out all indexes that do not match the
                   given classification -->
              <text>var indexes=this.cmatchCheck((cmatch['</text>
                <value-of select="$root_question_id" />
              <text>']||{}).indexes,r);</text>

              <!-- proceed only if there's valid indexes remaining -->
              <text>if((indexes===true)||indexes.length){</text>
                  <choose>
                    <!-- if the message is dynamic, then loop through each
                         individual index so that the message can be properly
                         generated for each -->
                    <when test="$message-dynamic">
                      <text>for(var i in indexes){</text>
                        <text>var index=indexes[i];</text>

                        <text>this.addFailure(fail,failid,</text>
                        <text>[index],'</text>
                          <value-of select="$message" />
                        <text>',causes);</text>
                      <text>}</text>
                    </when>

                    <!-- message is not dynamic; add all indexes at once -->
                    <otherwise>
                      <text>this.addFailure(fail,failid,</text>
                      <text>((indexes===true)?r:indexes),'</text>
                        <value-of select="$message" />
                      <text>',causes);</text>
                    </otherwise>
                  </choose>

                <text>failed=true;</text>
              <text>}</text>

              <text>retval=false;</text>
            </if>

            <!-- if we specified an id to return as the failure id, set it -->
            <if test="$failOn">
              <text>failid='</text>
              <value-of select="$failOn" />
              <text>';</text>
            </if>

            <if test="$forEach = false()">
              <text>return false;</text>
            </if>
        <text>}</text>
      <text>}</text>

    <!-- end of forEach -->
    <if test="$forEach = true()">
      <text>}</text>
      <text>return retval;</text>
    </if>
    <if test="$forEach != true()">
      <text>return true;</text>
    </if>
  <text>}).call(this,</text>
  <value-of select="$assertion" />
  <text>)</text>

  <if test="$semicolon">
    <text>;</text>
  </if>

  <!-- end of internal if stmt -->
  <if test="$internalOnly">
    <text>}</text>
  </if>
</template>


<template match="lv:trigger" mode="gen-trigger">
  <param name="question_id_default" select="../../@id" />
  <param name="indexes" select="'[]'" />

  <variable name="question_id_full" select="if ( @ref ) then @ref else $question_id_default" />

  <variable name="question_id">
    <choose>
      <when test="ends-with( $question_id_full, '*' )">
        <value-of select="substring-before( $question_id_full, '*' )" />
      </when>

      <when test="ends-with( $question_id_full, ']' )">
        <value-of select="substring-before( $question_id_full, '[' )" />
      </when>

      <otherwise>
        <value-of select="$question_id_full" />
      </otherwise>
    </choose>
  </variable>

  <variable name="use_indexes">
    <!-- if the question id ends in an asterisk, they want 'em all regardless
         of what we were given for our success list, so generate a full success
         list -->
    <choose>
      <!-- glob notation -->
      <when test="ends-with( $question_id_full, '*' )">
        <text>(function(){</text>
        <text>var len=(diff['</text>
          <value-of select="$question_id" />
        <text>']||bucket.getDataByName('</text>
          <value-of select="$question_id" />
        <text>')).length,</text>
        <text>ret=[];</text>
        <text>for(var i=0;i&lt;len;i++){ret.push(i);}</text>
        <text>return ret;})()</text>
      </when>

      <!-- index notation -->
      <when test="ends-with( $question_id_full, ']' )">
        <variable name="index" select="
            substring-before( substring-after( $question_id_full, '[' ), ']' )
          " />

        <text>[</text>
          <value-of select="$index" />
        <text>]</text>
      </when>

      <!-- otherwise, just use what we were given -->
      <otherwise>
        <value-of select="$indexes" />
      </otherwise>
    </choose>
  </variable>

  <!-- determine the value -->
  <variable name="value">
    <choose>
      <!-- string literal -->
      <when test="starts-with( @value, &quot;'&quot; )">
        <text>'</text>
          <!-- remove single quotes from the string -->
          <value-of select="translate( @value, &quot;'&quot;, '' )" />
        <text>'</text>
      </when>

      <!-- no value -->
      <when test="string-length( @value ) = 0">
        <text>''</text>
      </when>

      <!-- bucket value references -->
      <otherwise>
        <text>(diff['</text>
          <value-of select="@value" />
        <text>']||bucket.getDataByName('</text>
          <value-of select="@value" />
        <text>'))</text>
      </otherwise>
    </choose>
  </variable>

  <text>trigger_callback.call(this,'</text>
  <value-of select="@event" />
  <text>','</text>
  <value-of select="$question_id" />
  <text>',</text>
  <value-of select="$value" />
  <text>,</text>
  <value-of select="$use_indexes" />
  <text>);</text>
</template>


<template name="safe-value">
  <param name="value">
    <if test="starts-with( @value, &quot;'&quot; )">
      <value-of select="@value" />
    </if>

    <!-- if the value is a reference, then use the label of that question -->
    <if test="not( starts-with( @value, &quot;'&quot; ) )">
      <variable name="ref" select="@value" />

      <text>"</text>
      <value-of select="//lv:question[@id=$ref]/@label" />
      <text>"</text>
    </if>
  </param>

  <!-- escape single quotes -->
  <value-of select="replace( $value, &quot;'&quot;, &quot;\\'&quot; )" />
</template>


<!-- default assertion messages -->
<template match="assert:*" mode="assert-default-message">
  <text>is invalid</text>
</template>

<template match="assert:equals" mode="assert-default-message" priority="2">
  <text>must be equal to </text>
  <call-template name="safe-value" />
</template>

<template match="assert:notEqual" mode="assert-default-message" priority="2">
  <text>must not be equal to </text>
  <call-template name="safe-value" />
</template>

<template match="assert:in" mode="assert-default-message" priority="2">
  <text>must not be equal to any of the following values: </text>
  <call-template name="safe-value" />
</template>

<template match="assert:any" mode="assert-default-message" priority="2">
  <text>must be equal to one of the following values: </text>
  <call-template name="safe-value" />
</template>

<template match="assert:lessThan" mode="assert-default-message" priority="2">
  <text>must be less than </text>
  <call-template name="safe-value" />
</template>

<template match="assert:greaterThan" mode="assert-default-message" priority="2">
  <text>must be greater than </text>
  <call-template name="safe-value" />
</template>

<template match="assert:range" mode="assert-default-message" priority="2">
  <text>must be within the range </text>
  <call-template name="safe-value" />
</template>

<template match="assert:regex" mode="assert-default-message" priority="2">
  <text>must match the following regular expression: </text>
  <call-template name="safe-value" />
</template>

<template match="assert:empty" mode="assert-default-message" priority="2">
  <text>must be empty</text>
  <call-template name="safe-value" />
</template>

<template match="assert:notEmpty" mode="assert-default-message" priority="2">
  <text>must not be empty</text>
  <call-template name="safe-value" />
</template>

<template match="assert:message/text()">
  <value-of select="normalize-space(.)" />
</template>

<template match="assert:message/assert:value">
  <call-template name="safe-value">
    <with-param name="value" select="../../@value" />
  </call-template>
</template>

<template match="assert:message/lv:answer">
  <param name="bucketVar" select="'bucket'" />
  <param name="indexVar" select="'index'" />

  <text>'+</text>
  <value-of select="$bucketVar" />
  <text>.getDataByName('</text>
  <value-of select="@ref" />
  <text>')[</text>
  <value-of select="$indexVar" />
  <text>]+'</text>
</template>


<!--
    Builds an associative array of help text for each question, if help
    text was provided
-->
<template name="build-help">
  <for-each select="//lv:question/lv:help">
    <!-- add delimiter -->
    <if test="position() > 1">
      <text>,</text>
    </if>

    <value-of select="../@id" /><text>:'</text>
    <!-- escape single quotes -->
    <value-of select="replace( replace( node(), '\n| +', ' ' ), &quot;'&quot;, &quot;\\'&quot; )" />
    <text>'</text>
  </for-each>
</template>


<template name="build-internal">
  <!-- let's be flexible -->
  <for-each select="
      //lv:*[not(local-name()='item')][
        @internal='true'
        and ( @id or @ref )
      ]
    ">
    <!-- add delimiter -->
    <if test="position() > 1">
      <text>,</text>
    </if>
    <text>'</text>
    <value-of select="@id|@ref" />
    <text>':1</text>
  </for-each>
</template>


<!--
    Builds object containing question defaults
-->
<template name="build-defaults">
  <for-each select="
      //lv:question,
      //lv:external[ @type ],
      //lv:calc[ @store = 'true' ]
    ">
    <!-- add delimiter -->
    <if test="position() > 1">
      <text>,</text>
    </if>

    <text>'</text>
    <value-of select="@id" />
    <text>':'</text>
    <apply-templates select="." mode="get-default" />
    <text>'</text>
  </for-each>
</template>


<template name="build-display-defaults">
  <!-- sets have to be handled differently to ensure we generate a default for
       each potential element -->
  <for-each select="//lv:display[ string-length( @default ) > 0 ]">
    <variable name="i" select="position()" />

    <variable name="id" select="@ref" />
    <variable name="default" select="@default" />

    <!-- if this display value is not part of a set, then we have a fairly
         simple job (single id, single default) -->
    <if test="not( ../@each )">
      <!-- output delimiter if this is not our first value -->
      <if test="$i > 1">
        <text>,</text>
      </if>

      <text>'</text>
      <value-of select="$id" />
      <text>':'</text>
      <value-of select="$default" />
      <text>'</text>
    </if>

    <!-- if we have a set, loop through each set item, generate the ids and
         determine the appropriate default -->
    <if test="../@each">
      <for-each select="tokenize( ../@each, ' ' )">
        <variable name="pos" select="position()" />

        <!-- use pipes as delimiters rather than commas or spaces, since
             they're not likely to occur in a default value -->
        <variable name="defaults" select="tokenize( $default, '\|' )" />

        <!-- output delimiter if necessary -->
        <if test="( $i > 1 ) or ( $pos > 1 )">
          <text>,</text>
        </if>

        <!-- prefix id -->
        <text>'</text>
        <value-of select="." /><text>_</text>
        <value-of select="$id" />
        <text>':'</text>
        <!-- if there's a single default, use it for all of them -->
        <value-of select="if ( count( $defaults ) > 1 ) then $defaults[ $pos ] else $defaults[ 1 ]" />
        <text>'</text>
      </for-each>
    </if>
  </for-each>
</template>


<!--
  Determines which field will be used to determine the group index count
-->
<template name="build-group-index-fields">
  <for-each select="//lv:group">
    <!-- add delimiter -->
    <if test="position() > 1">
      <text>,</text>
    </if>

    <text>'</text>
      <value-of select="@id" />
    <text>':</text>

    <text>'</text>
      <choose>
        <!-- if we have been given a field to explicitly use as the index base,
             then use it -->
        <when test="@indexedBy">
          <value-of select="@indexedBy" />
        </when>

        <!-- otherwise, we'll use the first ref in the group -->
        <otherwise>
          <variable name="refs" select="
              lv:question
              |lv:question-copy
              |lv:answer
              |lv:display
            " />
          <variable name="first" select="$refs[1]" />

          <!-- ref takes precedence -->
          <choose>
            <when test="$first/@ref">
              <value-of select="$first/@ref" />
            </when>

            <otherwise>
              <value-of select="$first/@id" />
            </otherwise>
          </choose>
        </otherwise>
      </choose>
    <text>'</text>
  </for-each>
</template>


<!--
    Builds object containing field names for each group
-->
<template name="build-group-fields">
  <param name="linked" select="true()" />
  <param name="visonly" select="false()" />

  <for-each select="//lv:group">
    <!-- add delimiter -->
    <if test="position() > 1">
      <text>,</text>
    </if>

    <text>'</text>
    <value-of select="@id" />
    <text>':[</text>

    <variable name="refs"
                  select="lv:question
                          |lv:question/lv:option[ @id ]
                          |lv:static[ @id ]
                          |lv:question-copy" />

    <for-each select="$refs">
      <!-- add delimiter -->
      <if test="position() > 1">
        <text>,</text>
      </if>

      <text>'</text>
      <value-of select="@id|@ref" />
      <text>'</text>
    </for-each>

    <!-- grab all lv:display's with ids -->
    <for-each select="lv:display[ @id ]|lv:answer[ @id ]|lv:external[ @id and not( $visonly = true() ) ]">
      <!-- add delimiter if necessary -->
      <if test="$refs or position() > 1">
        <text>,</text>
      </if>

      <text>'</text>
      <value-of select="@id" />
      <text>'</text>
    </for-each>

    <variable name="thisId" select="@id" />
    <variable name="link" select="@link" />

    <!-- any links? -->
    <if test="$linked and $link">
      <!-- todo: question-ref -->
      <for-each select="//lv:group[ ( @link = $link ) and ( @id != $thisId ) ]">
        <for-each select="lv:question|lv:static[@id]">
          <!-- add delimiter (since groups must contain at least one question,
               there's always going to be a value before the delimiter from the
               origin group -->
          <text>,</text>

          <text>'</text>
          <value-of select="@id" />
          <text>'</text>
        </for-each>
      </for-each>
    </if>

    <text>]</text>
  </for-each>
</template>


<template name="build-linked-fields">
  <variable name="root" select="/" />

  <!-- build a list of all links -->
  <variable name="links" as="element( lv:links )">
    <lv:links>
      <for-each select="//lv:group[ @link ]">
        <lv:link ref="{@link}" />
      </for-each>
    </lv:links>
  </variable>

  <!-- build a unique list -->
  <variable name="uniq" select="
      $links//lv:link[ not( @ref=preceding-sibling::lv:link/@ref ) ]
    " />

  <for-each select="$uniq">
    <if test="position() > 1">
      <text>,</text>
    </if>

    <text>'</text>
      <value-of select="@ref" />
    <text>':[</text>

      <variable name="ref" select="@ref" />
      <variable name="groups" select="$root//lv:group[ @link=$ref ]" />

      <!-- this has been the cause of some nasty bugs in the past: if only
           one group is part of a link, then it's probably a bug based on a
           misinterpretation of how links work (they're not group refs) -->
      <if test="count( $groups ) = 1">
        <message terminate="yes"
                 select="concat( 'error: group `', $groups[1]/@id,
                                 ''' is the only member of link `',
                                 $ref, '''; either remove or set @link on ',
                                 'other groups' )" />
      </if>

      <for-each select="$groups//lv:question|$groups//lv:question-copy">
        <if test="position() > 1">
          <text>,</text>
        </if>

        <text>'</text>
          <value-of select="@id" />
        <text>'</text>
      </for-each>

    <text>]</text>
  </for-each>
</template>


<!--
  Builds required fields per step

  Produces an object containing the step id (1-index value based on the step's
  position) as the key and a hash of strings representing the question names as
  its value. For example:

  { 1: { "foo": true, "bar": true } }
-->
<template name="build-required-fields">
  <for-each select="//lv:step">
    <!-- add delimiter (required object) -->
    <if test="position() > 1">
      <text>,</text>
    </if>

    <!-- use the current position as the step id (1-indexed) -->
    <text>'</text>
    <value-of select="position()" />
    <text>':{</text>

    <!-- search for required questions that are descendents of this step -->
    <for-each select="*//lv:question[@required='true']">
      <!-- add delimiter (field array) -->
      <if test="position() > 1">
        <text>,</text>
      </if>

      <text>'</text>
      <value-of select="@id" />
      <text>': true</text>
    </for-each>

    <text>}</text>
  </for-each>
</template>


<template name="build-field-classes">
  <for-each select="//lv:question[ @class ]">
    <if test="position() > 1">
      <text>,</text>
    </if>

    <text>'</text>
      <value-of select="@id" />
    <text>':</text>

    <text>{</text>
      <for-each select="tokenize( @class, ' ' )">
        <if test="position() > 1">
          <text>,</text>
        </if>

        <text>'</text>
          <value-of select="." />
        <text>':true</text>
      </for-each>
    <text>}</text>
  </for-each>
</template>

<template name="build-field-retains">
  <for-each select="//lv:question[ @when and @retain='true' ]">
    <if test="position() > 1">
      <text>,</text>
    </if>

    <text>'</text>
      <value-of select="@id" />
    <text>':true</text>
  </for-each>
</template>


<!--
  Compiles @when attributes per field, where multiple classifications are
  separated by spaces, into an object

  Pretty much the same as build-field-classes.
-->
<template name="build-field-when">
  <variable name="root" select="/" />

  <!-- N.B. This permits a @when="", which is intentional and used! -->
  <for-each select="//lv:*[ @when ]">
    <if test="position() > 1">
      <text>,</text>
    </if>

    <variable name="pred-ref"
                  select="if ( @ref and not( @when ) ) then
                            @ref
                          else
                            @id" />

    <text>'</text>
      <value-of select="@id" />
    <text>':</text>

    <!-- TODO: calc-dsl repo progui-pkg.xsl has lvp:qid-to-class -->
    <text>["--vis-</text>
      <sequence select="translate(
                            $pred-ref,
                            '_ABCDEFGHIJKLMNOPQRSTUVWXYZ',
                            '-abcdefghijklmnopqrstuvwxyz' )" />
    <text>"]</text>
  </for-each>
</template>


<!--
  Builds a list of fields that are used directly for whens
-->
<template name="build-qwhen-list">
  <!-- ignore comma requirements -->
  <text>'':false</text>

  <for-each select="//lv:*[ starts-with( @when, 'q:' ) ]">
    <for-each select="tokenize( @when, ' ' )">
      <text>,'</text>
      <value-of select="substring-after( ., 'q:' )"/>
      <text>':true</text>
    </for-each>
  </for-each>

  <!-- TODO: clean this up -->
  <for-each select="//lv:*[ starts-with( @when, '!q:' ) ]">
    <for-each select="tokenize( @when, ' ' )">
      <text>,'</text>
      <value-of select="substring-after( ., '!q:' )"/>
      <text>':false</text>
    </for-each>
  </for-each>
</template>


<!-- kickback clear -->
<template name="build-kbclear">
  <for-each select="//lv:question[ @kickback='clear' ]">
    <if test="position() > 1">
      <text>,</text>
    </if>

    <text>'</text>
      <value-of select="@id" />
    <text>':true</text>
  </for-each>
</template>


<template name="build-secure-fields">
  <for-each select="//lv:question[@secure=true()]">
    <!-- add delimiter -->
    <if test="position() > 1">
      <text>,</text>
    </if>

    <text>'</text>
    <value-of select="@id" />
    <text>'</text>
  </for-each>
</template>


<template name="build-discard">
  <for-each select="/lv:program/lv:step">
    <!-- unconditional delimiter because there is no step 0 -->
    <text>,</text>

    <!-- default true -->
    <value-of select="
        if ( @allowDiscard='false' ) then
          'false'
        else
          'true'
      " />
  </for-each>
</template>


<!-- Any step that triggers the "rate" event is considered to be a rating step
     -->
<template name="build-rate-steps">
  <for-each select="/lv:program/lv:step">
    <!-- unconditional delimiter because there is no step 0 -->
    <text>,</text>

    <!-- default true -->
    <value-of select="
        if ( lv:trigger/@event='rate' ) then
          'true'
        else
          'false'
      " />
  </for-each>
</template>


<template name="build-sidebar-overview">
  <for-each select="lv:sidebar/lv:overview/lv:item[@ref]">
    <if test="position() > 1">
      <text>,</text>
    </if>

    <text>'</text>
    <value-of select="replace( @title, &quot;'&quot;, &quot;\\'&quot; )" />
    <text>':{ref:'</text>
    <value-of select="@ref" />
    <text>',internal:</text>
    <value-of select="if ( @internal = 'true' ) then 'true' else 'false'" />
    <text>}</text>
  </for-each>
</template>


<template name="build-init">
  <text>function(bucket,store_only){</text>

  <text>if(store_only===true){</text>
    <apply-templates select="//lv:calc[ @store = true() ]" mode="gen-calc">
      <with-param name="deps" select="true()" />
      <!-- diff data isn't applicable in this context -->
      <with-param name="with-diff" select="false()" />
      <with-param name="method" select="'setCommittedValues'" />
    </apply-templates>
  <text>return;}</text>

  <!-- run all calculated values on init -->
  <apply-templates select="//lv:calc" mode="gen-calc">
    <!-- diff data isn't applicable in this context -->
    <with-param name="with-diff" select="false()" />
    <with-param name="method" select="'setCommittedValues'" />
  </apply-templates>

  <text>}</text>
</template>


<template name="get-fist-step-id">
  <variable name="manages" select="//lv:step[ @type='manage' ]" />
  <variable name="manage-last" select="$manages[ count( $manages ) ]" />

  <choose>
    <!-- if we have management steps, calculate the first step id after all of them -->
    <when test="$manages">
      <value-of select="count( $manage-last/preceding-sibling::lv:step ) + 2" />
    </when>

    <otherwise>
      <!-- 1's a pretty good place to start! -->
      <text>1</text>
    </otherwise>
  </choose>
</template>


<template name="compiler:gen-sorted-groups">
  <for-each select="//lv:step">
    <!-- step 0 doesn't exist, so always add -->
    <text>,</text>

    <text>{</text>
      <for-each select=".//preproc:sorted-groups">
        <if test="position() > 1">
          <text>,</text>
        </if>

        <text>'</text>
          <value-of select="@id" />
        <text>':[</text>

          <for-each select="preproc:group">
            <if test="position() > 1">
              <text>,</text>
            </if>

            <!-- [ group id, [ sort fields ] ] -->
            <text>[</text>
              <text>'</text>
                <value-of select="@ref" />
              <text>',[</text>

                <for-each select="preproc:sort">
                  <if test="position() > 1">
                    <text>,</text>
                  </if>

                  <text>'</text>
                    <value-of select="@by" />
                  <text>'</text>
                </for-each>

              <text>]</text>
            <text>]</text>
          </for-each>

        <text>]</text>
      </for-each>
    <text>}</text>
  </for-each>
</template>

<template match="lv:static" mode="generate-static">
  <apply-templates mode="generate-static" />
</template>
<!-- simply coopy static nodes -->
<template match="*" mode="generate-static">
  <value-of select="concat('&lt;',name())"/>
    <apply-templates select="@*" mode="generate-static" />
    <text>&gt;</text>
    <apply-templates mode="generate-static" />
  <value-of select="concat('&lt;/',name(),'&gt;')"/>
</template>

<template match="@*" mode="generate-static">
  <value-of select="concat(' ',name(),'=&quot;')"/>
    <value-of select="." />
  <text>"</text>
</template>

<template match="text()" mode="generate-static">
  <value-of select="translate(.,'&#xA;',' ')"/>
</template>

</stylesheet>

