<?xml version="1.0"?>
<!--
  Builds Program JavaScript classes to be used both server and client side

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
  xmlns:lv="http://www.lovullo.com"
  xmlns:compiler="http://www.lovullo.com/program/compiler"
  xmlns:assert="http://www.lovullo.com/assert"
  xmlns:preproc="http://www.lovullo.com/program/preprocessor"

  xmlns:exsl="http://exslt.org/common"
  extension-element-prefixes="exsl">

<xsl:output
  method="text"
  indent="yes"
  omit-xml-declaration="yes"
  />

<!-- todo: way to remove? Needed by questions -->
<xsl:variable name="debug" select="false()" />

<!-- metadata -->
<xsl:include href="program-build-meta.xsl" />

<!-- calculated value methods -->
<xsl:include href="program-calc-methods.xsl" />

<!-- data APIs -->
<xsl:include href="program-data-api.xsl" />

<!-- questions -->
<xsl:include href="question/question.xsl" />

<xsl:param name="include-path" />


<!--
  Compilation entry point
-->
<xsl:template match="/lv:program">
  <xsl:apply-templates select="." mode="compiler:compile" />
</xsl:template>


<!--
  Prevent compilation in the event of preprocessor errors

  This will output all preprocessor errors to stdout and terminate, failing compilation.
-->
<xsl:template match="/lv:program[ .//preproc:error ]" mode="compiler:compile" priority="9">
  <!-- terminate with the preprocessor error messages -->
  <xsl:for-each select=".//preproc:error">
    <xsl:message>
      <xsl:text>[Preprocessor error] </xsl:text>
      <xsl:value-of select="." />
    </xsl:message>
  </xsl:for-each>

  <!-- finally, abort -->
  <!-- Yes, this is incredibly obnoxious! However, due to all the other build
       output, it's likely that it may not even be seen otherwise. -->
  <xsl:message>***********************************************</xsl:message>
  <xsl:message>*** Terminating due to preprocessor errors. ***</xsl:message>
  <xsl:message>***********************************************</xsl:message>
  <xsl:message terminate="yes">Compilation failed.</xsl:message>
</xsl:template>


<!--
  Compile source tree (kicked off after preprocessing)

  Note that this has a low priority, so it will only kick off if there are no
  other matches (e.g. matches for preprocessor errors)
-->
<xsl:template match="/lv:program" mode="compiler:compile" priority="1">
  <!-- require XSLT 2.0 parser -->
  <xsl:if test="number(system-property('xsl:version')) &lt; 2.0">
    <xsl:message terminate="yes">XSLT 2.0 processor required</xsl:message>
  </xsl:if>

  <!-- generate program path name -->
  <xsl:variable name="path-program" select="lower-case(@id)"/>

  <!-- includes must be kept separate from the program file, as they are not
       intended for the server. The program file is shared with both the server
       and the client. -->
  <!-- TODO: separate into sepaate build; we can't add a Makefile
       target for this -->
  <xsl:result-document href="include.js">
    <xsl:apply-templates select="lv:include" mode="build-pre" />
  </xsl:result-document>

  <!-- generate program file -->
  <xsl:apply-templates select="." mode="build-program-class" />
</xsl:template>


<xsl:template match="/lv:program/lv:include" mode="build-pre">
  <xsl:variable name="path"
                select="concat( $include-path, '/', @src )" />
  <xsl:variable name="module"
                select="if ( @as ) then
                          @as
                        else
                          replace( @src, '.js', '' )" />

  <!-- include script, wrapping it as a CommonJS module with the same name as
       the path, sans the .js extension -->
  <xsl:text>(function(require,module){var exports=module.exports={};</xsl:text>
  <xsl:value-of select="unparsed-text( $path, 'iso-8859-1' )" disable-output-escaping="yes" />
  <xsl:text>})(require,modules['</xsl:text>
  <xsl:value-of select="$module" />
  <xsl:text>']={});</xsl:text>
</xsl:template>


<xsl:template match="/lv:program" mode="build-program-class">
  <xsl:text>var Calc=require('program/Calc');</xsl:text>
  <xsl:text>var BaseAssertions=require('assert/BaseAssertions');</xsl:text>
  <xsl:text>var Program=require('program/Program').Program;</xsl:text>

  <xsl:text>module.exports=Program.extend({</xsl:text>
    <xsl:text>id:'</xsl:text><xsl:value-of select="@id" /><xsl:text>',</xsl:text>
    <xsl:text>version:'</xsl:text><xsl:value-of select="@version" /><xsl:text>',</xsl:text>
    <xsl:text>title:'</xsl:text><xsl:value-of select="@title" /><xsl:text>',</xsl:text>
    <xsl:text>steps:[</xsl:text><xsl:call-template name="build-steps" /><xsl:text>],</xsl:text>
    <xsl:text>help:{</xsl:text><xsl:call-template name="build-help" /><xsl:text>},</xsl:text>
    <xsl:text>internal:{</xsl:text><xsl:call-template name="build-internal" /><xsl:text>},</xsl:text>
    <xsl:text>defaults:{</xsl:text><xsl:call-template name="build-defaults" /><xsl:text>},</xsl:text>
    <xsl:text>displayDefaults:{</xsl:text><xsl:call-template name="build-display-defaults" /><xsl:text>},</xsl:text>
    <xsl:text>groupIndexField:{</xsl:text><xsl:call-template name="build-group-index-fields" /><xsl:text>},</xsl:text>
    <xsl:text>groupFields:{</xsl:text><xsl:call-template name="build-group-fields" /><xsl:text>},</xsl:text>
    <xsl:text>groupUserFields:{</xsl:text>
      <xsl:call-template name="build-group-fields">
        <xsl:with-param name="linked" select="false()" />
        <xsl:with-param name="visonly" select="true()" />
      </xsl:call-template>
    <xsl:text>},</xsl:text>
    <xsl:text>groupExclusiveFields:{</xsl:text><xsl:call-template name="build-group-fields"><xsl:with-param name="linked" select="false()" /></xsl:call-template><xsl:text>},</xsl:text>
    <xsl:text>links:{</xsl:text><xsl:call-template name="build-linked-fields" /><xsl:text>},</xsl:text>
    <xsl:text>classes:{</xsl:text><xsl:call-template name="build-field-classes" /><xsl:text>},</xsl:text>
    <xsl:text>cretain:{</xsl:text><xsl:call-template name="build-field-retains" /><xsl:text>},</xsl:text>
    <xsl:text>whens:{</xsl:text><xsl:call-template name="build-field-when" /><xsl:text>},</xsl:text>
    <xsl:text>qwhens:{</xsl:text><xsl:call-template name="build-qwhen-list" /><xsl:text>},</xsl:text>
    <xsl:text>kbclear:{</xsl:text><xsl:call-template name="build-kbclear" /><xsl:text>},</xsl:text>
    <xsl:text>requiredFields:{</xsl:text><xsl:call-template name="build-required-fields" /><xsl:text>},</xsl:text>
    <xsl:text>meta:</xsl:text><xsl:call-template name="build-meta" /><xsl:text>,</xsl:text>
    <xsl:text>secureFields:[</xsl:text><xsl:call-template name="build-secure-fields" /><xsl:text>],</xsl:text>
    <xsl:text>unlockable:</xsl:text><xsl:value-of select="if ( @unlockable ) then 'true' else 'false'" /><xsl:text>,</xsl:text>
    <xsl:text>discardable:[</xsl:text><xsl:call-template name="build-discard" /><xsl:text>],</xsl:text>
    <xsl:text>rateSteps:[</xsl:text><xsl:call-template name="build-rate-steps" /><xsl:text>],</xsl:text>
    <xsl:text>ineligibleLockCount:</xsl:text>
      <xsl:value-of select="if ( @ineligibleLockCount ) then @ineligibleLockCount else '0'" />
      <xsl:text>,</xsl:text>
    <xsl:text>isInternal:false,</xsl:text>

    <!-- determine an appropriate first step id -->
    <xsl:text>firstStepId:</xsl:text><xsl:call-template name="get-fist-step-id" /><xsl:text>,</xsl:text>

    <xsl:text>sidebar:{</xsl:text>
      <xsl:text>static_content: '</xsl:text>
      <xsl:for-each select="lv:sidebar/lv:static">
          <xsl:apply-templates select="." mode="generate-static" />
      </xsl:for-each>
      <xsl:text>',</xsl:text>
      <xsl:text>overview:{</xsl:text>
        <xsl:call-template name="build-sidebar-overview" />
    <xsl:text>}},</xsl:text>

    <!-- data APIs -->
    <xsl:text>apis:</xsl:text>
      <xsl:apply-templates select="." mode="compiler:compile-apis" />
      <xsl:text>,</xsl:text>
    <xsl:text>qapis:</xsl:text>
      <xsl:apply-templates select="." mode="compiler:compile-question-apis" />
      <xsl:text>,</xsl:text>

    <xsl:text>initQuote:</xsl:text><xsl:call-template name="build-init" /><xsl:text>,</xsl:text>

    <!-- classifier module -->
    <xsl:text>'protected classifier':</xsl:text>'<xsl:value-of select="@classifier" /><xsl:text>',</xsl:text>

    <!-- export services -->
    <xsl:text>export_path: {</xsl:text>
    <xsl:text>c1: '</xsl:text>
      <xsl:value-of select="@c1-import-path" />
    <xsl:text>'},</xsl:text>

    <!-- sorted group sets -->
    <xsl:text>sortedGroups:[</xsl:text><xsl:call-template name="compiler:gen-sorted-groups" /><xsl:text>],</xsl:text>

    <!-- build the event data for each step -->
    <xsl:text>eventData:(function(){</xsl:text>
      <xsl:text>var ret_data=[];</xsl:text>
      <xsl:apply-templates select="lv:step" mode="build-program-class">
        <xsl:with-param name="ret" select="'ret_data'" />
      </xsl:apply-templates>

      <xsl:text>return ret_data;</xsl:text>
    <xsl:text>})()</xsl:text>
  <xsl:text>});</xsl:text>
</xsl:template>


<!--
  Generates array containing step titles
-->
<xsl:template name="build-steps">
  <xsl:for-each select="//lv:step">
    <!-- since there is no step 0, always add delimiter -->
    <xsl:text>,</xsl:text>

    <xsl:text>{title:'</xsl:text>
    <xsl:value-of select="@title" />
    <xsl:text>',type:'</xsl:text>
    <xsl:value-of select="@type" />
    <xsl:text>'}</xsl:text>
  </xsl:for-each>
</xsl:template>


<xsl:template match="lv:step" mode="build-program-class">
  <xsl:param name="ret" />

  <!-- represents the event data we'll be updating -->
  <xsl:variable name="eventData">
    <xsl:value-of select="$ret" /><xsl:text>[</xsl:text>
      <xsl:value-of select="position()" />
    <xsl:text>]</xsl:text>
  </xsl:variable>

  <xsl:variable name="step" select="current()" />

  <xsl:text>
/*step</xsl:text><xsl:value-of select="position()" />
    <xsl:text>(</xsl:text><xsl:value-of select="@title" />
    <xsl:text>)*/</xsl:text>

  <!-- initialize the variable -->
  <xsl:value-of select="$eventData" /><xsl:text>={};</xsl:text>

  <!-- question-based assertion events -->
  <xsl:for-each select="('submit', 'change', 'forward', 'dapi')">
    <xsl:call-template name="parse-assert-events">
      <xsl:with-param name="eventData" select="$eventData" />
      <xsl:with-param name="type" select="." />
      <xsl:with-param name="step" select="$step" />

      <xsl:with-param name="default" select="if ( current() = 'submit' ) then true() else false()" />
      <xsl:with-param name="perQuestion"
                      select="( current() = 'change' )
                              or ( current() = 'dapi' )" />
    </xsl:call-template>
  </xsl:for-each>

  <!-- non-question (and non-assertion) events -->
  <xsl:for-each select="('beforeLoad', 'postSubmit', 'visit')">
    <xsl:call-template name="parse-events">
      <xsl:with-param name="eventData" select="$eventData" />
      <xsl:with-param name="type" select="." />
      <xsl:with-param name="step" select="$step" />
    </xsl:call-template>
  </xsl:for-each>

  <!-- actions -->
  <xsl:value-of select="$eventData" />
  <xsl:text>.action={</xsl:text>
    <xsl:for-each select=".//lv:question[ ./lv:action ]">
      <xsl:if test="position() > 1">
        <xsl:text>,</xsl:text>
      </xsl:if>

      <xsl:apply-templates select="." mode="build-actions">
        <xsl:with-param name="eventData" select="$eventData" />
      </xsl:apply-templates>
    </xsl:for-each>
  <xsl:text>};</xsl:text>
</xsl:template>


<xsl:template match="lv:question[ ./lv:action ]" mode="build-actions">
  <xsl:param name="eventData" />

  <xsl:text>'</xsl:text>
    <xsl:value-of select="@id" />
  <xsl:text>':{</xsl:text>

    <!-- build each action -->
    <xsl:for-each select="./lv:action">
      <xsl:if test="position() > 1">
        <xsl:text>,</xsl:text>
      </xsl:if>

      <xsl:apply-templates select="." mode="build-actions" />
    </xsl:for-each>

  <xsl:text>}</xsl:text>
</xsl:template>


<xsl:template match="lv:question/lv:action" mode="build-actions">
  <xsl:text>'</xsl:text>
    <xsl:value-of select="@on" />
  <xsl:text>':function(trigger_callback,bucket,index){</xsl:text>
    <!-- no diff support yet (doesn't make sense at the time of writing) -->
    <xsl:text>var diff={};</xsl:text>

    <!-- compile triggers -->
    <xsl:apply-templates select="./lv:trigger" mode="gen-trigger">
      <xsl:with-param name="question_id_default" select="ancestor::lv:question/@id" />
      <!-- the triggers expect an array of indexes, so just create an array
           from the single index that we were given (actions will never be
           performed on more than one index...at least not with the current
           implementation) -->
      <xsl:with-param name="indexes" select="'[index]'" />
    </xsl:apply-templates>

  <xsl:text>}</xsl:text>
</xsl:template>


<xsl:template name="parse-script-events">
  <xsl:param name="type" />
  <xsl:param name="step" />

  <!-- simply inject the script (whoopie!) -->
  <xsl:variable name="script"
    select="$step/lv:script[ contains( @onEvent, $type ) ]" />

  <!-- if a script was found, enclose it in a closure (so that the vars we
       define don't screw with the remainder of the script) and inject it
  -->
  <xsl:if test="$script">
    <xsl:text>(function(){</xsl:text>
    <xsl:value-of select="$script" />
    <xsl:text>})();</xsl:text>
  </xsl:if>
</xsl:template>


<!--
  Generates assertions for the given event (non-assertion)

  @param xs:string type        event type
  @param xs:string eventData   string representing the variable to assign
                               generated function to
  @param node      step        step node
  @param xs:bool   default     whether this event is the default (can be blank)
-->
<xsl:template name="parse-events">
  <xsl:param name="type" />
  <xsl:param name="eventData" />
  <xsl:param name="step" />
  <xsl:param name="default" select="false()" />

  <!-- locate all assertion-less triggers that are direct descendants of the step node -->
  <xsl:variable name="triggerdata">
    <xsl:for-each select="$step/lv:trigger[ ( $default = true() and not(@onEvent) ) or contains(@onEvent, $type) ]">
      <xsl:apply-templates select="." mode="gen-trigger">
        <xsl:with-param name="question_id_default" select="''" />
      </xsl:apply-templates>
    </xsl:for-each>
  </xsl:variable>

  <!-- parse scripts for this event -->
  <xsl:variable name="scriptdata">
    <xsl:for-each select="$step/lv:script[ contains(@onEvent, $type) ]">
      <xsl:call-template name="parse-script-events">
        <xsl:with-param name="type" select="$type" />
        <xsl:with-param name="step" select="$step" />
      </xsl:call-template>
    </xsl:for-each>
  </xsl:variable>

  <!-- append data, if we generated anything (IMPORTANT: we must not output
       anything if it is not necessary, as this is a crucial assumption made by
       the system) -->
  <xsl:if test="( string-length( $triggerdata ) > 0 ) or ( string-length( $scriptdata ) > 0 )">
    <xsl:value-of select="$eventData" />.<xsl:value-of select="$type" />
    <xsl:text>=function(trigger_callback,bucket){</xsl:text>
    <xsl:value-of select="$triggerdata" />
    <xsl:value-of select="$scriptdata" />
    <xsl:text>};</xsl:text>
  </xsl:if>
</xsl:template>


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
<xsl:template name="parse-assert-events">
  <xsl:param name="type" />
  <xsl:param name="eventData" />
  <xsl:param name="step" />
  <xsl:param name="default" select="false()" />
  <xsl:param name="perQuestion" select="false()" />

  <xsl:variable name="funcTop">
    <xsl:text>=function(bucket,diff,cmatch,trigger_callback){</xsl:text>
      <xsl:text>var fail={},failed=false,causes=[];</xsl:text>
      <xsl:text>var retval=true;</xsl:text>
  </xsl:variable>

  <xsl:variable name="scripts">
    <!-- process scripts within the XML -->
    <xsl:call-template name="parse-script-events">
      <xsl:with-param name="type" select="$type" />
      <xsl:with-param name="step" select="$step" />
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="funcBottom">
      <!-- if we have no failures, return null to indicate that everything
           looks good -->
      <xsl:text>return (failed)?fail:null;</xsl:text>
    <xsl:text>};</xsl:text>
  </xsl:variable>

  <!-- normal, big chuncks -->
  <xsl:if test="not($perQuestion)">
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
    <xsl:variable name="assertions"
      select="( $step//*[local-name()='question' or local-name()='question-copy']
              | $step/..//lv:question[ @id = $step//lv:question-copy/@ref ]
              )/assert:*[ ( $default = true() and not(@lv:onEvent) ) or contains(@lv:onEvent, $type) ]
              "
      />

    <!-- only add the function if we have assertions to put into it -->
    <xsl:if test="$assertions or $scripts">
      <xsl:value-of select="$eventData" />.<xsl:value-of select="$type" />
      <xsl:value-of select="$funcTop" />

      <xsl:value-of select="$scripts" />

      <!-- generate each of the assertions -->
      <xsl:for-each select="$assertions">
        <xsl:apply-templates select="." mode="gen-assert" />
      </xsl:for-each>

      <xsl:value-of select="$funcBottom" />
    </xsl:if>
  </xsl:if>
  <!-- otherwise, per-question chunks -->
  <xsl:if test="$perQuestion">
    <xsl:value-of select="$eventData" />
    <xsl:text>.</xsl:text>
    <xsl:value-of select="$type" />
    <xsl:text>={};</xsl:text>

    <xsl:for-each select="$step//lv:question | $step//lv:question-copy
                          | $step//lv:external">
      <xsl:call-template name="gen-per-question">
        <xsl:with-param name="eventData" select="$eventData" />
        <xsl:with-param name="funcTop" select="$funcTop" />
        <xsl:with-param name="funcBottom" select="$funcBottom" />
        <xsl:with-param name="type" select="$type" />
      </xsl:call-template>
    </xsl:for-each>
  </xsl:if>
</xsl:template>


<!--
  Post-parse question-based events

  This template is used in the event that certain events wish to add additional
  data to an event *before* the assertions are performed. For example,
  calculated values are tied to the 'change' event and we wish for their values
  to be available to the assertions.

  @param string type event type
  @param string id   question id (optional)
-->
<xsl:template name="pre-parse-question-event">
  <xsl:param name="type" />
  <xsl:param name="id" select="@id" />

  <!-- if we don't calculate the calculated values before assertions, then
       their values may lag behind in undefined circumstances -->
  <xsl:if test="$type = 'change'">
    <xsl:call-template name="gen-calc-for-id">
      <xsl:with-param name="id" select="$id" />
    </xsl:call-template>
  </xsl:if>
</xsl:template>


<xsl:template name="gen-calc-for-id">
  <xsl:param name="id" />

  <xsl:apply-templates select="//lv:calc[@ref=$id or @value=$id]" mode="gen-calc">
    <xsl:with-param name="deps" select="true()" />
    <xsl:with-param name="children" select="true()" />
  </xsl:apply-templates>
</xsl:template>


<!--
  Post-parse question-based events

  This template is used in the event that certain events wish to add additional
  data to an event.

  @param string type event type
  @param string id   question id (optional)
-->
<xsl:template name="post-parse-question-event">
  <xsl:param name="type" />
  <xsl:param name="id" select="@id" />
  <xsl:param name="eventData" />

  <xsl:apply-templates select="//lv:question[ @id=$id ]" mode="post-parse-question-event">
    <xsl:with-param name="type"      select="$type" />
    <xsl:with-param name="id"        select="$id" />
    <xsl:with-param name="eventData" select="$eventData" />
  </xsl:apply-templates>
</xsl:template>

<xsl:template match="*" mode="post-parse-question-event" priority="1">
  <!-- catch-all; do nothing -->
</xsl:template>


<xsl:template name="gen-per-question">
  <xsl:param name="eventData" />
  <xsl:param name="funcTop" />
  <xsl:param name="funcBottom" />
  <xsl:param name="type" />
  <xsl:param name="id" select="@id | @ref" />

  <xsl:variable name="assertions"
    select="assert:*[ contains(@lv:onEvent, $type) ]" />

  <xsl:variable name="preParse">
    <!-- certain things should be done before assertions -->
    <xsl:call-template name="pre-parse-question-event">
      <xsl:with-param name="type" select="$type" />
      <xsl:with-param name="id" select="$id" />
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="postParse">
    <!-- we may want to append some code to the function -->
    <xsl:call-template name="post-parse-question-event">
      <xsl:with-param name="type"      select="$type" />
      <xsl:with-param name="id"        select="$id" />
      <xsl:with-param name="eventData" select="$eventData" />
    </xsl:call-template>

    <!-- add any dynamic defaults -->
    <xsl:call-template name="gen-dynamic-defaults">
      <xsl:with-param name="change_id" select="$id" />
    </xsl:call-template>
  </xsl:variable>

  <!-- only add the function if we have some assertions or post-parse data -->
  <xsl:if test="
      $assertions
      or ( string-length( $preParse ) > 0 )
      or ( string-length( $postParse ) > 0 )
    ">

    <xsl:value-of select="$eventData" />.<xsl:value-of select="$type" />
    <xsl:text>['</xsl:text>
    <xsl:value-of select="$id" />
    <xsl:text>']</xsl:text>

    <xsl:value-of select="$funcTop" />

    <xsl:value-of select="$preParse" />

    <xsl:for-each select="$assertions">
      <xsl:apply-templates select="." mode="gen-assert" />
    </xsl:for-each>

    <!-- add assertions that reference this question -->
    <xsl:for-each select="../../lv:group/*[local-name()='question' or local-name()='question-copy']/assert:*[ contains(@lv:onEvent, $type) and @value = $id ]">
      <xsl:apply-templates select="." mode="gen-assert" />
    </xsl:for-each>

    <xsl:value-of select="$postParse" />

    <xsl:value-of select="$funcBottom" />
  </xsl:if>
</xsl:template>


<!-- XXX: Refactor into a common function which can simply be called here -->
<xsl:template name="gen-dynamic-defaults">
  <xsl:param name="change_id" />

  <xsl:for-each select="//lv:question[@defaultTo = $change_id]">
    <!-- get default and current data and initialize an array to store the new
         data to be set -->
    <xsl:text>(function(){</xsl:text>
      <xsl:text>var ddata=</xsl:text>
        <xsl:call-template name="parse-expected">
          <xsl:with-param name="expected" select="$change_id" />
          <xsl:with-param name="with-diff" select="true()" />
        </xsl:call-template>
      <xsl:text>,</xsl:text>
      <xsl:text>curdata=</xsl:text>
        <xsl:call-template name="parse-expected">
          <xsl:with-param name="expected" select="@id" />
          <xsl:with-param name="with-diff" select="true()" />
        </xsl:call-template>
      <xsl:text>,newdata=[],chgi=0;</xsl:text>

      <!-- replace only empty values -->
      <xsl:text>for(var i in ddata){</xsl:text>
        <xsl:text>if(curdata[i]){newdata[i]=curdata[i];continue;}</xsl:text>
        <xsl:text>if(!ddata[i])continue;</xsl:text>
        <xsl:text>newdata[i]=ddata[i];chgi++;</xsl:text>
      <xsl:text>}</xsl:text>

      <!-- don't bother doing anything if no changes are to be made -->
      <xsl:text>if(chgi===0)return;</xsl:text>

      <!-- perform overwrite with new data -->
      <xsl:text>bucket.overwriteValues({'</xsl:text>
      <xsl:value-of select="@id" />
      <xsl:text>':newdata});</xsl:text>
    <xsl:text>})();</xsl:text>
  </xsl:for-each>
</xsl:template>


<xsl:template name="parse-expected">
  <xsl:param name="expected">
    <!-- use value attribute if available -->
    <xsl:if test="@value">
      <xsl:value-of select="@value" />
    </xsl:if>
    <!-- otherwise attempt to use value list -->
    <xsl:if test="not( @value )">
      <xsl:text>'</xsl:text>
      <xsl:for-each select="assert:value">
        <xsl:if test="position() > 1 ">
          <xsl:text>,</xsl:text>
        </xsl:if>
        <xsl:value-of select="replace( node(), &quot;'&quot;, &quot;\\'&quot; )" />
      </xsl:for-each>
      <xsl:text>'</xsl:text>
    </xsl:if>
  </xsl:param>
  <xsl:param name="with-diff" select="false()" />
  <xsl:param name="merge-diff" select="false()" />
  <xsl:param name="bracket" select="true()" />
  <xsl:param name="for-each" />

  <xsl:choose>
    <!-- explicit value -->
    <xsl:when test="starts-with( $expected, &quot;'&quot; )">
      <xsl:text>[</xsl:text><xsl:value-of select="$expected" /><xsl:text>]</xsl:text>
    </xsl:when>

    <!-- cmatch reference -->
    <xsl:when test="starts-with( $expected, 'c:' )">
      <xsl:text>((cmatch['</xsl:text>
        <xsl:value-of select="substring-after( $expected, ':' )" />
      <xsl:text>']||{}).indexes||[])</xsl:text>
    </xsl:when>

    <!-- bucket reference -->
    <xsl:otherwise>
      <!-- we'll need to make this an array, since we'll be selecting a single index -->
      <xsl:if test="@forEach and $bracket">
        <xsl:text>[</xsl:text>
      </xsl:if>

      <!-- get the value without any index included -->
      <xsl:variable name="field-id" select="
          if ( contains( $expected, '[' ) ) then
            substring-before( $expected, '[' )
          else
            $expected
        " />

      <xsl:text>(</xsl:text>
      <xsl:choose>
        <xsl:when test="$merge-diff">
          <xsl:text>bucket.getPendingDataByName('</xsl:text>
            <xsl:value-of select="$field-id" />
          <xsl:text>',diff)</xsl:text>
        </xsl:when>

        <xsl:otherwise>
          <xsl:if test="$with-diff">
            <xsl:text>diff['</xsl:text>
            <xsl:value-of select="$field-id" />
            <xsl:text>'] || </xsl:text>
          </xsl:if>
          <xsl:text>bucket.getDataByName('</xsl:text>
            <xsl:value-of select="$field-id" />
          <xsl:text>')</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:text>)</xsl:text>

      <xsl:choose>
        <!-- if an index was provided, use it -->
        <xsl:when test="contains( $expected, '[' )">
          <xsl:text>[</xsl:text>
          <xsl:value-of select="substring-after( $expected, '[' )" />
        </xsl:when>

        <!-- if a forEach was provided, ensure we check the associated index -->
        <xsl:when test="$for-each">
          <xsl:text>[gi]</xsl:text>
        </xsl:when>

        <xsl:otherwise>
          <!-- nothing -->
        </xsl:otherwise>
      </xsl:choose>

      <xsl:if test="@forEach and $bracket">
        <xsl:text>]</xsl:text>
      </xsl:if>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<xsl:template match="assert:success" mode="gen-assert-expected-result">
  <xsl:text>true</xsl:text>
</xsl:template>
<xsl:template match="assert:failure" mode="gen-assert-expected-result">
  <xsl:text>false</xsl:text>
</xsl:template>

<xsl:template match="assert:success" mode="gen-assert-getset">
  <xsl:text>Successes</xsl:text>
</xsl:template>
<xsl:template match="assert:failure" mode="gen-assert-getset">
  <xsl:text>Failures</xsl:text>
</xsl:template>


<!--
  Success/failure group header

  This should be output only on the first of a set of success/failure groups,
  otherwise the values for the contained variables would be reset for each
  group.
-->
<xsl:template match="
  assert:success[ not( preceding-sibling::assert:success ) ]
  |assert:failure[ not( preceding-sibling::assert:failure) ]
" mode="gen-assert-group-head">

  <xsl:text>var count=0;</xsl:text>
  <xsl:text>var retval=true;</xsl:text>

  <!-- this var will hold the successes or failures -->
  <xsl:text>var results=(gi!==undefined)?[gi]:assertion.get</xsl:text>
    <xsl:apply-templates select="." mode="gen-assert-getset" />
  <xsl:text>();</xsl:text>
</xsl:template>

<!--
  Success/failure group footer

  This should be output only on the last of a set of success/failure groups,
  otherwise the compiled function will return prematurely.
-->
<xsl:template match="
  assert:success[ not( following-sibling::assert:success ) ]
  |assert:failure[ not( following-sibling::assert:failure) ]
" mode="gen-assert-group-tail">

  <!-- if there were no assertions, default to returning the value associated
       with the type of group -->
  <xsl:text>return(count==0)?</xsl:text>
    <xsl:apply-templates select="." mode="gen-assert-expected-result" />
  <xsl:text>:retval;</xsl:text>
</xsl:template>


<!--
  Compile sub-assertions and triggers associated with a particular
  success/failure group.
-->
<xsl:template match="assert:success|assert:failure" mode="gen-assert-group">
  <xsl:param name="question_id" />

  <xsl:variable name="self" select="." />

  <!-- e.g. Successes/Failures to be translated into get*/set* -->
  <xsl:variable name="result-getset">
    <xsl:apply-templates select="." mode="gen-assert-getset" />
  </xsl:variable>

  <!-- Boolean value representing what result we would expected to be a "good
       thing" for this group with regards to sub-assertions; that is, in a
       success group, if we have all succeeding sub-assertions, then we need
       not do anything. However, in a failure group, succeeding sub-assertions
       would require that we take another action (since failure is no longer
       the case). -->
  <xsl:variable name="expected-result">
    <xsl:apply-templates select="." mode="gen-assert-expected-result" />
  </xsl:variable>

  <xsl:apply-templates select="." mode="gen-assert-group-head" />

  <xsl:if test="@associative">
    <!-- if we are NOT nested inside a previous associative assertion,
         then get the list of failed items.

         otherwise, use the previously failed index to ensure we do not
         break the mapping (FS#5769) -->
    <xsl:if test="not( ../@associative )">
      <!-- get results from the previous (failed) assertion -->
      <xsl:text>var i=0,len=results.length;</xsl:text>
    </xsl:if>

      <!-- triggers (must be done before looping to ensure the original
           results are triggered ) -->
      <xsl:apply-templates select="./lv:trigger" mode="gen-trigger">
        <xsl:with-param name="question_id_default" select="$question_id" />
        <xsl:with-param name="indexes" select="'results'" />
      </xsl:apply-templates>

    <xsl:if test="not( ../@associative )">
      <!-- loop over all the results -->
      <xsl:text>for(var i=0,len=results.length;i&lt;len;i++){</xsl:text>
    </xsl:if>

        <xsl:text>var index=results[i];</xsl:text>

        <!-- We can only break out of the loop if we're actually in the
             loop. This check is unnecessary if we're not. -->
        <xsl:if test="not( ../@associative )">
          <xsl:text>if(index===undefined){</xsl:text>
              <xsl:text>continue;</xsl:text>
          <xsl:text>}</xsl:text>
        </xsl:if>

        <!-- generates success array for this index -->
        <xsl:text>var this_result = [];this_result[i]=i;</xsl:text>

        <xsl:if test="./assert:*">
          <xsl:text>var result=</xsl:text>
            <xsl:for-each select="./assert:*">
              <!-- join siblings with a logical and -->
              <xsl:if test="position() > 1">
                <xsl:text>&amp;&amp;</xsl:text>
              </xsl:if>

              <!-- XXX: we'll need to do a bit more refactoring to resolve this mess -->
              <xsl:variable name="fail-index">
                <xsl:if test="local-name( $self ) = 'failure'">
                  <xsl:text>this_result</xsl:text>
                </xsl:if>
              </xsl:variable>

              <xsl:apply-templates select="." mode="gen-assert">
                <xsl:with-param name="question_id_default" select="$question_id" />
                <xsl:with-param name="trackCount" select="true()" />
                <xsl:with-param name="failIndex" select="$fail-index" />
                <xsl:with-param name="result-var" select="'index'" />
                <xsl:with-param name="givenPrefix">
                  <xsl:text>[</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="givenSuffix">
                  <xsl:text>[index]]</xsl:text>
                </xsl:with-param>
                <!-- suppress semicolon at the end of the block so that
                     they may be chained -->
                <xsl:with-param name="semicolon" select="false()" />
              </xsl:apply-templates>
            </xsl:for-each>
            <xsl:text>;</xsl:text>

          <!-- remove from success list if failed -->
          <xsl:text>if(result!==</xsl:text>
            <xsl:value-of select="$expected-result" />
          <xsl:text>){</xsl:text>
              <xsl:text>delete results[i];</xsl:text>
          <xsl:text>}else{retval=false;}</xsl:text>
       </xsl:if>

    <!-- we will have only looped if we aren't a nested associative
         success -->
    <xsl:if test="not( ../@associative )">
      <xsl:text>}</xsl:text>
    </xsl:if>

    <xsl:text>assertion.set</xsl:text>
      <xsl:value-of select="$result-getset" />
    <xsl:text>(results);</xsl:text>
  </xsl:if>

  <!-- non-associative triggers -->
  <xsl:if test="not( @associative )">
    <xsl:apply-templates select="./lv:trigger" mode="gen-trigger">
      <xsl:with-param name="question_id_default" select="$question_id" />
      <xsl:with-param name="indexes" select="'results'" />
    </xsl:apply-templates>

    <xsl:apply-templates select="./assert:*" mode="gen-assert">
      <xsl:with-param name="question_id_default" select="$question_id" />
      <xsl:with-param name="trackCount" select="true()" />
    </xsl:apply-templates>
  </xsl:if>

  <xsl:apply-templates select="." mode="gen-assert-group-tail" />
</xsl:template>


<xsl:template match="assert:*" mode="gen-assert">
  <xsl:param name="question_id_default" select="if ( ../@id ) then ../@id else ../@ref" />
  <xsl:param name="expected">
    <xsl:call-template name="parse-expected">
      <xsl:with-param name="with-diff" select="true()" />
      <xsl:with-param name="for-each" select="@forEach" />
    </xsl:call-template>
  </xsl:param>
  <xsl:param name="name" select="local-name(.)" />
  <xsl:param name="trackCount" select="false()" />
  <xsl:param name="failIndex" />

  <!-- used for cmatch checks -->
  <xsl:param name="result-var" />

  <!-- TODO: There's better ways of doing this; this will simply allow us to
       suppress the semicolon insertion at the end of the generated block so
       that the assertions may be chained -->
  <xsl:param name="semicolon" select="true()" />

  <xsl:param name="ref" select="@ref" />
  <xsl:param name="question_id" select="if ( $ref ) then $ref else $question_id_default" />
  <xsl:param name="root_question_id" select="ancestor::lv:question/@id|ancestor::lv:question-copy/@ref" />

  <!-- generate question id to reference on failure (@failOn can be used on an
       assertion to override this) -->
  <xsl:param name="failOn" select="@failOn" />
  <xsl:param name="failure_question_id" select="$root_question_id" />

  <xsl:param name="givenPrefix" select="''" />
  <xsl:param name="givenSuffix" select="''" />

  <xsl:param name="is-cref" select="starts-with( $question_id, 'c:' )" />
  <xsl:param name="given">
    <xsl:choose>
      <xsl:when test="$is-cref">
        <xsl:text>(((cmatch||{__classes:{}}).__classes['</xsl:text>
          <xsl:value-of select="substring-after( $question_id, ':' )" />
        <xsl:text>']||{}).indexes||[])</xsl:text>
      </xsl:when>

      <xsl:otherwise>
        <!-- if we're looking at a specific index, we need to ensure the result is
             still an array -->
        <xsl:if test="contains( $question_id, '[' )">
          <xsl:text>[</xsl:text>
        </xsl:if>

        <xsl:value-of select="$givenPrefix" />
        <xsl:call-template name="parse-expected">
          <xsl:with-param name="expected" select="$question_id" />
          <xsl:with-param name="with-diff" select="true()" />
          <xsl:with-param name="bracket" select="false()" />
        </xsl:call-template>
        <xsl:value-of select="$givenSuffix" />

        <!-- if we're looking at a specific index, we need to ensure the result is
             still an array -->
        <xsl:if test="contains( $question_id, '[' )">
          <xsl:text>]</xsl:text>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:param>

  <!-- make debugging a little easier -->
  <xsl:variable name="marker">
    <xsl:copy-of select="name()" />

    <xsl:for-each select="@*">
      <xsl:text> </xsl:text>

      <xsl:value-of select="local-name()" />
      <xsl:text>=</xsl:text>
      <xsl:value-of select="." />
    </xsl:for-each>
  </xsl:variable>

  <xsl:text>/***begin </xsl:text>
    <xsl:value-of select="$marker" />
  <xsl:text>***/</xsl:text>

  <!-- whether to do assertion value by value -->
  <xsl:variable name="forEach" select="if ( @forEach = 'true' ) then true() else false()" />

  <!-- whether the assertion is internal only -->
  <xsl:variable name="internalOnly" select="if ( @lv:internal = 'true' ) then true() else false()" />

  <!-- classification to which this assertion applies -->
  <xsl:variable name="when-ignore" select="@whenIgnore" />

  <!-- message to display on error -->
  <xsl:variable name="message">
    <xsl:if test="./assert:message">
      <xsl:apply-templates select="./assert:message" />
    </xsl:if>
    <xsl:if test="not(./assert:message)">
      <xsl:text>The value for "</xsl:text>
        <xsl:value-of select="if ( $ref ) then //lv:question[@id=$ref]/@label else ../@label" />
      <xsl:text>" </xsl:text>
      <xsl:apply-templates select="." mode="assert-default-message" />
    </xsl:if>
  </xsl:variable>

  <!-- whether the message is dynamic -->
  <xsl:variable name="message-dynamic" select="./assert:message/lv:*" />

  <!-- the assertion we'll be calling -->
  <xsl:variable name="assertion">
    <xsl:text>BaseAssertions.</xsl:text><xsl:value-of select="$name" />
  </xsl:variable>

  <!-- success group callback -->
  <xsl:variable name="success">
    <xsl:text>/***s </xsl:text>
      <xsl:value-of select="$marker" />
    <xsl:text>***/</xsl:text>

    <xsl:choose>
      <xsl:when test="./assert:success">
        <xsl:text>function(){</xsl:text>
          <xsl:apply-templates select="./assert:success" mode="gen-assert-group">
            <xsl:with-param name="question_id" select="$question_id" />
          </xsl:apply-templates>
        <xsl:text>}</xsl:text>
      </xsl:when>

      <!-- no success group -->
      <xsl:otherwise>
        <xsl:text>null</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- failure group callback -->
  <xsl:variable name="failure">
    <xsl:text>/***f </xsl:text>
      <xsl:value-of select="$marker" />
    <xsl:text>***/</xsl:text>

    <xsl:choose>
      <xsl:when test="./assert:failure">
        <xsl:text>function(){</xsl:text>
          <xsl:apply-templates select="./assert:failure" mode="gen-assert-group">
            <xsl:with-param name="question_id" select="$question_id" />
          </xsl:apply-templates>
        <xsl:text>}</xsl:text>
      </xsl:when>

      <!-- no failure group -->
      <xsl:otherwise>
        <xsl:text>null</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- some assertions should be performed only for users logged in internally -->
  <xsl:if test="$internalOnly">
    <xsl:text>if(this.isInternal){</xsl:text>
  </xsl:if>

  <xsl:text>(function(assertion){</xsl:text>
      <xsl:if test="$trackCount">
        <xsl:text>count++;</xsl:text>
      </xsl:if>

      <!-- if forEach was given, we need to loop through them individually -->
      <xsl:if test="$forEach = true()">
        <xsl:text>var given_data=</xsl:text>
        <xsl:value-of select="$given" />
        <xsl:text>;for(var gi in given_data){</xsl:text>
          <xsl:text>var given_val=given_data[gi];</xsl:text>
      </xsl:if>
      <!-- Otherwise, we have to define gi so we don't get a ReferenceError,
           UNLESS we have a previous assertion, in which case it's already
           defined. We do *not* want to clear this out if it's already defined
           because it will destroy nested assertions. (See FS#6304)
      -->
      <xsl:if test="$forEach != true() and local-name(..)='question'">
        <xsl:text>var gi=undefined;</xsl:text>
      </xsl:if>

      <!-- Stores failure id so that it can be overridden by @failOn. This does
           not get set (so that failures will set on the parent assertion if
           @recordFailure is false -->
      <xsl:if test="not( @recordFailure = false() )">
        <xsl:text>var failid='</xsl:text>
        <xsl:value-of select="if (@failOn) then @failOn else $failure_question_id" />
        <xsl:text>';</xsl:text>
      </xsl:if>

      <!-- allow ignoring cmatch @when's -->
      <xsl:text>var when_ignore=</xsl:text>
        <xsl:choose>
          <xsl:when test="$when-ignore = 'true'">
            <xsl:text>true</xsl:text>
          </xsl:when>

          <xsl:otherwise>
            <xsl:text>false</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      <xsl:text>;</xsl:text>

      <xsl:if test="not( ancestor::assert:* )">
        <xsl:text>var causes=[];</xsl:text>
      </xsl:if>

      <!-- we only wish to perform the assertions if the field matches its
           given classification (using the provided cmatch object);
           specifically, skip all assertions on this field unless there is at
           least one match (note also that we default to an any:true object,
           with the assumption being that, if no cmatch is found, then no rules
           exist for that field and we should proceed as normal) -->
      <xsl:text>if(when_ignore||(cmatch['</xsl:text>
        <xsl:value-of select="$question_id" />
      <xsl:text>']||{any:true}).any){</xsl:text>

        <xsl:text>causes.push('</xsl:text>
          <xsl:value-of select="$question_id" />
        <xsl:text>');</xsl:text>

        <!-- compile assertion logic -->
        <xsl:text>if(this.doAssertion(assertion,'</xsl:text>
          <xsl:value-of select="$question_id" />
          <xsl:text>',</xsl:text>
          <xsl:value-of select="$expected" />
          <xsl:text>,</xsl:text>
          <xsl:if test="$forEach = true()">
            <!-- must be passed in as an array -->
            <xsl:text>[given_val]</xsl:text>
          </xsl:if>
          <xsl:if test="$forEach != true()">
            <xsl:value-of select="$given" />
          </xsl:if>
          <xsl:text>,</xsl:text><xsl:value-of select="$success" />
          <xsl:text>,</xsl:text><xsl:value-of select="$failure" />
          <xsl:text>,</xsl:text>
          <xsl:value-of select="if ( @recordFailure = false() ) then 'false' else 'true'" />
          <xsl:text>)===false){</xsl:text>
            <xsl:if test="not( @recordFailure = false() )">
              <xsl:text>var r=</xsl:text>
                <xsl:value-of select="
                    if ( $forEach = true() ) then
                      '[gi]'
                    else if ( string-length( $result-var ) > 0 ) then
                      concat( '[', $result-var, ']' )
                    else
                      'assertion.getFailures()'
                  " />
              <xsl:text>;</xsl:text>

              <!-- at this point, filter out all indexes that do not match the
                   given classification -->
              <xsl:text>var indexes=this.cmatchCheck((cmatch['</xsl:text>
                <xsl:value-of select="$root_question_id" />
              <xsl:text>']||{}).indexes,r);</xsl:text>

              <!-- proceed only if there's valid indexes remaining -->
              <xsl:text>if((indexes===true)||indexes.length){</xsl:text>
                  <xsl:choose>
                    <!-- if the message is dynamic, then loop through each
                         individual index so that the message can be properly
                         generated for each -->
                    <xsl:when test="$message-dynamic">
                      <xsl:text>for(var i in indexes){</xsl:text>
                        <xsl:text>var index=indexes[i];</xsl:text>

                        <xsl:text>this.addFailure(fail,failid,</xsl:text>
                        <xsl:text>[index],'</xsl:text>
                          <xsl:value-of select="$message" />
                        <xsl:text>',causes);</xsl:text>
                      <xsl:text>}</xsl:text>
                    </xsl:when>

                    <!-- message is not dynamic; add all indexes at once -->
                    <xsl:otherwise>
                      <xsl:text>this.addFailure(fail,failid,</xsl:text>
                      <xsl:text>((indexes===true)?r:indexes),'</xsl:text>
                        <xsl:value-of select="$message" />
                      <xsl:text>',causes);</xsl:text>
                    </xsl:otherwise>
                  </xsl:choose>

                <xsl:text>failed=true;</xsl:text>
              <xsl:text>}</xsl:text>

              <xsl:text>retval=false;</xsl:text>
            </xsl:if>

            <!-- if we specified an id to return as the failure id, set it -->
            <xsl:if test="$failOn">
              <xsl:text>failid='</xsl:text>
              <xsl:value-of select="$failOn" />
              <xsl:text>';</xsl:text>
            </xsl:if>

            <xsl:if test="$forEach = false()">
              <xsl:text>return false;</xsl:text>
            </xsl:if>
        <xsl:text>}</xsl:text>
      <xsl:text>}</xsl:text>

    <!-- end of forEach -->
    <xsl:if test="$forEach = true()">
      <xsl:text>}</xsl:text>
      <xsl:text>return retval;</xsl:text>
    </xsl:if>
    <xsl:if test="$forEach != true()">
      <xsl:text>return true;</xsl:text>
    </xsl:if>
  <xsl:text>}).call(this,</xsl:text>
  <xsl:value-of select="$assertion" />
  <xsl:text>)</xsl:text>

  <xsl:if test="$semicolon">
    <xsl:text>;</xsl:text>
  </xsl:if>

  <!-- end of internal if stmt -->
  <xsl:if test="$internalOnly">
    <xsl:text>}</xsl:text>
  </xsl:if>
</xsl:template>


<xsl:template match="lv:trigger" mode="gen-trigger">
  <xsl:param name="question_id_default" select="../../@id" />
  <xsl:param name="indexes" select="'[]'" />

  <xsl:variable name="question_id_full" select="if ( @ref ) then @ref else $question_id_default" />

  <xsl:variable name="question_id">
    <xsl:choose>
      <xsl:when test="ends-with( $question_id_full, '*' )">
        <xsl:value-of select="substring-before( $question_id_full, '*' )" />
      </xsl:when>

      <xsl:when test="ends-with( $question_id_full, ']' )">
        <xsl:value-of select="substring-before( $question_id_full, '[' )" />
      </xsl:when>

      <xsl:otherwise>
        <xsl:value-of select="$question_id_full" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="use_indexes">
    <!-- if the question id ends in an asterisk, they want 'em all regardless
         of what we were given for our success list, so generate a full success
         list -->
    <xsl:choose>
      <!-- glob notation -->
      <xsl:when test="ends-with( $question_id_full, '*' )">
        <xsl:text>(function(){</xsl:text>
        <xsl:text>var len=(diff['</xsl:text>
          <xsl:value-of select="$question_id" />
        <xsl:text>']||bucket.getDataByName('</xsl:text>
          <xsl:value-of select="$question_id" />
        <xsl:text>')).length,</xsl:text>
        <xsl:text>ret=[];</xsl:text>
        <xsl:text>for(var i=0;i&lt;len;i++){ret.push(i);}</xsl:text>
        <xsl:text>return ret;})()</xsl:text>
      </xsl:when>

      <!-- index notation -->
      <xsl:when test="ends-with( $question_id_full, ']' )">
        <xsl:variable name="index" select="
            substring-before( substring-after( $question_id_full, '[' ), ']' )
          " />

        <xsl:text>[</xsl:text>
          <xsl:value-of select="$index" />
        <xsl:text>]</xsl:text>
      </xsl:when>

      <!-- otherwise, just use what we were given -->
      <xsl:otherwise>
        <xsl:value-of select="$indexes" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- determine the value -->
  <xsl:variable name="value">
    <xsl:choose>
      <!-- string literal -->
      <xsl:when test="starts-with( @value, &quot;'&quot; )">
        <xsl:text>'</xsl:text>
          <!-- remove single quotes from the string -->
          <xsl:value-of select="translate( @value, &quot;'&quot;, '' )" />
        <xsl:text>'</xsl:text>
      </xsl:when>

      <!-- no value -->
      <xsl:when test="string-length( @value ) = 0">
        <xsl:text>''</xsl:text>
      </xsl:when>

      <!-- bucket value references -->
      <xsl:otherwise>
        <xsl:text>(diff['</xsl:text>
          <xsl:value-of select="@value" />
        <xsl:text>']||bucket.getDataByName('</xsl:text>
          <xsl:value-of select="@value" />
        <xsl:text>'))</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:text>trigger_callback.call(this,'</xsl:text>
  <xsl:value-of select="@event" />
  <xsl:text>','</xsl:text>
  <xsl:value-of select="$question_id" />
  <xsl:text>',</xsl:text>
  <xsl:value-of select="$value" />
  <xsl:text>,</xsl:text>
  <xsl:value-of select="$use_indexes" />
  <xsl:text>);</xsl:text>
</xsl:template>


<xsl:template name="safe-value">
  <xsl:param name="value">
    <xsl:if test="starts-with( @value, &quot;'&quot; )">
      <xsl:value-of select="@value" />
    </xsl:if>

    <!-- if the value is a reference, then use the label of that question -->
    <xsl:if test="not( starts-with( @value, &quot;'&quot; ) )">
      <xsl:variable name="ref" select="@value" />

      <xsl:text>"</xsl:text>
      <xsl:value-of select="//lv:question[@id=$ref]/@label" />
      <xsl:text>"</xsl:text>
    </xsl:if>
  </xsl:param>

  <!-- escape single quotes -->
  <xsl:value-of select="replace( $value, &quot;'&quot;, &quot;\\'&quot; )" />
</xsl:template>


<!-- default assertion messages -->
<xsl:template match="assert:*" mode="assert-default-message">
  <xsl:text>is invalid</xsl:text>
</xsl:template>

<xsl:template match="assert:equals" mode="assert-default-message" priority="2">
  <xsl:text>must be equal to </xsl:text>
  <xsl:call-template name="safe-value" />
</xsl:template>

<xsl:template match="assert:notEqual" mode="assert-default-message" priority="2">
  <xsl:text>must not be equal to </xsl:text>
  <xsl:call-template name="safe-value" />
</xsl:template>

<xsl:template match="assert:in" mode="assert-default-message" priority="2">
  <xsl:text>must not be equal to any of the following values: </xsl:text>
  <xsl:call-template name="safe-value" />
</xsl:template>

<xsl:template match="assert:any" mode="assert-default-message" priority="2">
  <xsl:text>must be equal to one of the following values: </xsl:text>
  <xsl:call-template name="safe-value" />
</xsl:template>

<xsl:template match="assert:lessThan" mode="assert-default-message" priority="2">
  <xsl:text>must be less than </xsl:text>
  <xsl:call-template name="safe-value" />
</xsl:template>

<xsl:template match="assert:greaterThan" mode="assert-default-message" priority="2">
  <xsl:text>must be greater than </xsl:text>
  <xsl:call-template name="safe-value" />
</xsl:template>

<xsl:template match="assert:range" mode="assert-default-message" priority="2">
  <xsl:text>must be within the range </xsl:text>
  <xsl:call-template name="safe-value" />
</xsl:template>

<xsl:template match="assert:regex" mode="assert-default-message" priority="2">
  <xsl:text>must match the following regular expression: </xsl:text>
  <xsl:call-template name="safe-value" />
</xsl:template>

<xsl:template match="assert:empty" mode="assert-default-message" priority="2">
  <xsl:text>must be empty</xsl:text>
  <xsl:call-template name="safe-value" />
</xsl:template>

<xsl:template match="assert:notEmpty" mode="assert-default-message" priority="2">
  <xsl:text>must not be empty</xsl:text>
  <xsl:call-template name="safe-value" />
</xsl:template>

<xsl:template match="assert:message/text()">
  <xsl:value-of select="normalize-space(.)" />
</xsl:template>

<xsl:template match="assert:message/assert:value">
  <xsl:call-template name="safe-value">
    <xsl:with-param name="value" select="../../@value" />
  </xsl:call-template>
</xsl:template>

<xsl:template match="assert:message/lv:answer">
  <xsl:param name="bucketVar" select="'bucket'" />
  <xsl:param name="indexVar" select="'index'" />

  <xsl:text>'+</xsl:text>
  <xsl:value-of select="$bucketVar" />
  <xsl:text>.getDataByName('</xsl:text>
  <xsl:value-of select="@ref" />
  <xsl:text>')[</xsl:text>
  <xsl:value-of select="$indexVar" />
  <xsl:text>]+'</xsl:text>
</xsl:template>


<!--
    Builds an associative array of help text for each question, if help
    text was provided
-->
<xsl:template name="build-help">
  <xsl:for-each select="//lv:question/lv:help">
    <!-- add delimiter -->
    <xsl:if test="position() > 1">
      <xsl:text>,</xsl:text>
    </xsl:if>

    <xsl:value-of select="../@id" /><xsl:text>:'</xsl:text>
    <!-- escape single quotes -->
    <xsl:value-of select="replace( replace( node(), '\n| +', ' ' ), &quot;'&quot;, &quot;\\'&quot; )" />
    <xsl:text>'</xsl:text>
  </xsl:for-each>
</xsl:template>


<xsl:template name="build-internal">
  <!-- let's be flexible -->
  <xsl:for-each select="
      //lv:*[not(local-name()='item')][
        @internal='true'
        and ( @id or @ref )
      ]
    ">
    <!-- add delimiter -->
    <xsl:if test="position() > 1">
      <xsl:text>,</xsl:text>
    </xsl:if>
    <xsl:text>'</xsl:text>
    <xsl:value-of select="@id|@ref" />
    <xsl:text>':1</xsl:text>
  </xsl:for-each>
</xsl:template>


<!--
    Builds object containing question defaults
-->
<xsl:template name="build-defaults">
  <xsl:for-each select="
      //lv:question
      |//lv:external[ @type ]
    ">
    <!-- add delimiter -->
    <xsl:if test="position() > 1">
      <xsl:text>,</xsl:text>
    </xsl:if>

    <xsl:text>'</xsl:text>
    <xsl:value-of select="@id" />
    <xsl:text>':'</xsl:text>
    <xsl:apply-templates select="." mode="get-default" />
    <xsl:text>'</xsl:text>
  </xsl:for-each>
</xsl:template>


<xsl:template name="build-display-defaults">
  <!-- sets have to be handled differently to ensure we generate a default for
       each potential element -->
  <xsl:for-each select="//lv:display[ string-length( @default ) > 0 ]">
    <xsl:variable name="i" select="position()" />

    <xsl:variable name="id" select="@ref" />
    <xsl:variable name="default" select="@default" />

    <!-- if this display value is not part of a set, then we have a fairly
         simple job (single id, single default) -->
    <xsl:if test="not( ../@each )">
      <!-- output delimiter if this is not our first value -->
      <xsl:if test="$i > 1">
        <xsl:text>,</xsl:text>
      </xsl:if>

      <xsl:text>'</xsl:text>
      <xsl:value-of select="$id" />
      <xsl:text>':'</xsl:text>
      <xsl:value-of select="$default" />
      <xsl:text>'</xsl:text>
    </xsl:if>

    <!-- if we have a set, loop through each set item, generate the ids and
         determine the appropriate default -->
    <xsl:if test="../@each">
      <xsl:for-each select="tokenize( ../@each, ' ' )">
        <xsl:variable name="pos" select="position()" />

        <!-- use pipes as delimiters rather than commas or spaces, since
             they're not likely to occur in a default value -->
        <xsl:variable name="defaults" select="tokenize( $default, '\|' )" />

        <!-- output delimiter if necessary -->
        <xsl:if test="( $i > 1 ) or ( $pos > 1 )">
          <xsl:text>,</xsl:text>
        </xsl:if>

        <!-- prefix id -->
        <xsl:text>'</xsl:text>
        <xsl:value-of select="." /><xsl:text>_</xsl:text>
        <xsl:value-of select="$id" />
        <xsl:text>':'</xsl:text>
        <!-- if there's a single default, use it for all of them -->
        <xsl:value-of select="if ( count( $defaults ) > 1 ) then $defaults[ $pos ] else $defaults[ 1 ]" />
        <xsl:text>'</xsl:text>
      </xsl:for-each>
    </xsl:if>
  </xsl:for-each>
</xsl:template>


<!--
  Determines which field will be used to determine the group index count
-->
<xsl:template name="build-group-index-fields">
  <xsl:for-each select="//lv:group">
    <!-- add delimiter -->
    <xsl:if test="position() > 1">
      <xsl:text>,</xsl:text>
    </xsl:if>

    <xsl:text>'</xsl:text>
      <xsl:value-of select="@id" />
    <xsl:text>':</xsl:text>

    <xsl:text>'</xsl:text>
      <xsl:choose>
        <!-- if we have been given a field to explicitly use as the index base,
             then use it -->
        <xsl:when test="@indexedBy">
          <xsl:value-of select="@indexedBy" />
        </xsl:when>

        <!-- otherwise, we'll use the first ref in the group -->
        <xsl:otherwise>
          <xsl:variable name="refs" select="
              lv:question
              |lv:question-copy
              |lv:answer
              |lv:display
            " />
          <xsl:variable name="first" select="$refs[1]" />

          <!-- ref takes precedence -->
          <xsl:choose>
            <xsl:when test="$first/@ref">
              <xsl:value-of select="$first/@ref" />
            </xsl:when>

            <xsl:otherwise>
              <xsl:value-of select="$first/@id" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    <xsl:text>'</xsl:text>
  </xsl:for-each>
</xsl:template>


<!--
    Builds object containing field names for each group
-->
<xsl:template name="build-group-fields">
  <xsl:param name="linked" select="true()" />
  <xsl:param name="visonly" select="false()" />

  <xsl:for-each select="//lv:group">
    <!-- add delimiter -->
    <xsl:if test="position() > 1">
      <xsl:text>,</xsl:text>
    </xsl:if>

    <xsl:text>'</xsl:text>
    <xsl:value-of select="@id" />
    <xsl:text>':[</xsl:text>

    <xsl:variable name="refs"
                  select="lv:question
                          |lv:question/lv:option[ @id ]
                          |lv:static[ @id ]
                          |lv:question-copy" />

    <xsl:for-each select="$refs">
      <!-- add delimiter -->
      <xsl:if test="position() > 1">
        <xsl:text>,</xsl:text>
      </xsl:if>

      <xsl:text>'</xsl:text>
      <xsl:value-of select="@id|@ref" />
      <xsl:text>'</xsl:text>
    </xsl:for-each>

    <!-- grab all lv:display's with ids -->
    <xsl:for-each select="lv:display[ @id ]|lv:answer[ @id ]|lv:external[ @id and not( $visonly = true() ) ]">
      <!-- add delimiter if necessary -->
      <xsl:if test="$refs or position() > 1">
        <xsl:text>,</xsl:text>
      </xsl:if>

      <xsl:text>'</xsl:text>
      <xsl:value-of select="@id" />
      <xsl:text>'</xsl:text>
    </xsl:for-each>

    <xsl:variable name="thisId" select="@id" />
    <xsl:variable name="link" select="@link" />

    <!-- any links? -->
    <xsl:if test="$linked and $link">
      <!-- todo: question-ref -->
      <xsl:for-each select="//lv:group[ ( @link = $link ) and ( @id != $thisId ) ]">
        <xsl:for-each select="lv:question|lv:static[@id]">
          <!-- add delimiter (since groups must contain at least one question,
               there's always going to be a value before the delimiter from the
               origin group -->
          <xsl:text>,</xsl:text>

          <xsl:text>'</xsl:text>
          <xsl:value-of select="@id" />
          <xsl:text>'</xsl:text>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:if>

    <xsl:text>]</xsl:text>
  </xsl:for-each>
</xsl:template>


<xsl:template name="build-linked-fields">
  <xsl:variable name="root" select="/" />

  <!-- build a list of all links -->
  <xsl:variable name="links">
    <links>
      <xsl:for-each select="//lv:group[ @link ]">
        <lv:link ref="{@link}" />
      </xsl:for-each>
    </links>
  </xsl:variable>

  <!-- build a unique list -->
  <xsl:variable name="uniq" select="
      $links//lv:link[ not( @ref=preceding-sibling::lv:link/@ref ) ]
    " />

  <xsl:for-each select="$uniq">
    <xsl:if test="position() > 1">
      <xsl:text>,</xsl:text>
    </xsl:if>

    <xsl:text>'</xsl:text>
      <xsl:value-of select="@ref" />
    <xsl:text>':[</xsl:text>

      <xsl:variable name="ref" select="@ref" />
      <xsl:variable name="groups" select="$root//lv:group[ @link=$ref ]" />

      <xsl:for-each select="$groups//lv:question|$groups//lv:question-copy">
        <xsl:if test="position() > 1">
          <xsl:text>,</xsl:text>
        </xsl:if>

        <xsl:text>'</xsl:text>
          <xsl:value-of select="@id" />
        <xsl:text>'</xsl:text>
      </xsl:for-each>

    <xsl:text>]</xsl:text>
  </xsl:for-each>
</xsl:template>


<!--
  Builds required fields per step

  Produces an object containing the step id (1-index value based on the step's
  position) as the key and a hash of strings representing the question names as
  its value. For example:

  { 1: { "foo": true, "bar": true } }
-->
<xsl:template name="build-required-fields">
  <xsl:for-each select="//lv:step">
    <!-- add delimiter (required object) -->
    <xsl:if test="position() > 1">
      <xsl:text>,</xsl:text>
    </xsl:if>

    <!-- use the current position as the step id (1-indexed) -->
    <xsl:text>'</xsl:text>
    <xsl:value-of select="position()" />
    <xsl:text>':{</xsl:text>

    <!-- search for required questions that are descendents of this step -->
    <xsl:for-each select="*//lv:question[@required='true']">
      <!-- add delimiter (field array) -->
      <xsl:if test="position() > 1">
        <xsl:text>,</xsl:text>
      </xsl:if>

      <xsl:text>'</xsl:text>
      <xsl:value-of select="@id" />
      <xsl:text>': true</xsl:text>
    </xsl:for-each>

    <xsl:text>}</xsl:text>
  </xsl:for-each>
</xsl:template>


<xsl:template name="build-field-classes">
  <xsl:for-each select="//lv:question[ @class ]">
    <xsl:if test="position() > 1">
      <xsl:text>,</xsl:text>
    </xsl:if>

    <xsl:text>'</xsl:text>
      <xsl:value-of select="@id" />
    <xsl:text>':</xsl:text>

    <xsl:text>{</xsl:text>
      <xsl:for-each select="tokenize( @class, ' ' )">
        <xsl:if test="position() > 1">
          <xsl:text>,</xsl:text>
        </xsl:if>

        <xsl:text>'</xsl:text>
          <xsl:value-of select="." />
        <xsl:text>':true</xsl:text>
      </xsl:for-each>
    <xsl:text>}</xsl:text>
  </xsl:for-each>
</xsl:template>

<xsl:template name="build-field-retains">
  <xsl:for-each select="//lv:question[ @when and @retain='true' ]">
    <xsl:if test="position() > 1">
      <xsl:text>,</xsl:text>
    </xsl:if>

    <xsl:text>'</xsl:text>
      <xsl:value-of select="@id" />
    <xsl:text>':true</xsl:text>
  </xsl:for-each>
</xsl:template>


<!--
  Compiles @when attributes per field, where multiple classifications are
  separated by spaces, into an object

  Pretty much the same as build-field-classes.
-->
<xsl:template name="build-field-when">
  <xsl:variable name="root" select="/" />

  <!-- N.B. This permits a @when="", which is intentional and used! -->
  <xsl:for-each select="//lv:*[ @when ]">
    <xsl:if test="position() > 1">
      <xsl:text>,</xsl:text>
    </xsl:if>

    <xsl:variable name="pred-ref"
                  select="if ( @ref and not( @when ) ) then
                            @ref
                          else
                            @id" />

    <xsl:text>'</xsl:text>
      <xsl:value-of select="@id" />
    <xsl:text>':</xsl:text>

    <!-- TODO: calc-dsl repo progui-pkg.xsl has lvp:qid-to-class -->
    <xsl:text>["--vis-</xsl:text>
      <xsl:sequence select="translate(
                            $pred-ref,
                            '_ABCDEFGHIJKLMNOPQRSTUVWXYZ',
                            '-abcdefghijklmnopqrstuvwxyz' )" />
    <xsl:text>"]</xsl:text>
  </xsl:for-each>
</xsl:template>


<!--
  Builds a list of fields that are used directly for whens
-->
<xsl:template name="build-qwhen-list">
  <!-- ignore comma requirements -->
  <xsl:text>'':false</xsl:text>

  <xsl:for-each select="//lv:*[ starts-with( @when, 'q:' ) ]">
    <xsl:for-each select="tokenize( @when, ' ' )">
      <xsl:text>,'</xsl:text>
      <xsl:value-of select="substring-after( ., 'q:' )"/>
      <xsl:text>':true</xsl:text>
    </xsl:for-each>
  </xsl:for-each>

  <!-- TODO: clean this up -->
  <xsl:for-each select="//lv:*[ starts-with( @when, '!q:' ) ]">
    <xsl:for-each select="tokenize( @when, ' ' )">
      <xsl:text>,'</xsl:text>
      <xsl:value-of select="substring-after( ., '!q:' )"/>
      <xsl:text>':false</xsl:text>
    </xsl:for-each>
  </xsl:for-each>
</xsl:template>


<!-- kickback clear -->
<xsl:template name="build-kbclear">
  <xsl:for-each select="//lv:question[ @kickback='clear' ]">
    <xsl:if test="position() > 1">
      <xsl:text>,</xsl:text>
    </xsl:if>

    <xsl:text>'</xsl:text>
      <xsl:value-of select="@id" />
    <xsl:text>':true</xsl:text>
  </xsl:for-each>
</xsl:template>


<xsl:template name="build-secure-fields">
  <xsl:for-each select="//lv:question[@secure=true()]">
    <!-- add delimiter -->
    <xsl:if test="position() > 1">
      <xsl:text>,</xsl:text>
    </xsl:if>

    <xsl:text>'</xsl:text>
    <xsl:value-of select="@id" />
    <xsl:text>'</xsl:text>
  </xsl:for-each>
</xsl:template>


<xsl:template name="build-discard">
  <xsl:for-each select="/lv:program/lv:step">
    <!-- unconditional delimiter because there is no step 0 -->
    <xsl:text>,</xsl:text>

    <!-- default true -->
    <xsl:value-of select="
        if ( @allowDiscard='false' ) then
          'false'
        else
          'true'
      " />
  </xsl:for-each>
</xsl:template>


<!-- Any step that triggers the "rate" event is considered to be a rating step
     -->
<xsl:template name="build-rate-steps">
  <xsl:for-each select="/lv:program/lv:step">
    <!-- unconditional delimiter because there is no step 0 -->
    <xsl:text>,</xsl:text>

    <!-- default true -->
    <xsl:value-of select="
        if ( lv:trigger/@event='rate' ) then
          'true'
        else
          'false'
      " />
  </xsl:for-each>
</xsl:template>


<xsl:template name="build-sidebar-overview">
  <xsl:for-each select="lv:sidebar/lv:overview/lv:item[@ref]">
    <xsl:if test="position() > 1">
      <xsl:text>,</xsl:text>
    </xsl:if>

    <xsl:text>'</xsl:text>
    <xsl:value-of select="replace( @title, &quot;'&quot;, &quot;\\'&quot; )" />
    <xsl:text>':{ref:'</xsl:text>
    <xsl:value-of select="@ref" />
    <xsl:text>',internal:</xsl:text>
    <xsl:value-of select="if ( @internal = 'true' ) then 'true' else 'false'" />
    <xsl:text>}</xsl:text>
  </xsl:for-each>
</xsl:template>


<xsl:template name="build-init">
  <xsl:text>function(bucket,store_only){</xsl:text>

  <xsl:text>if(store_only===true){</xsl:text>
    <xsl:apply-templates select="//lv:calc[ @store = true() ]" mode="gen-calc">
      <xsl:with-param name="deps" select="true()" />
      <!-- diff data isn't applicable in this context -->
      <xsl:with-param name="with-diff" select="false()" />
      <xsl:with-param name="method" select="'setCommittedValues'" />
    </xsl:apply-templates>
  <xsl:text>return;}</xsl:text>

  <!-- run all calculated values on init -->
  <xsl:apply-templates select="//lv:calc" mode="gen-calc">
    <!-- diff data isn't applicable in this context -->
    <xsl:with-param name="with-diff" select="false()" />
    <xsl:with-param name="method" select="'setCommittedValues'" />
  </xsl:apply-templates>

  <xsl:text>}</xsl:text>
</xsl:template>


<xsl:template name="get-fist-step-id">
  <xsl:variable name="manages" select="//lv:step[ @type='manage' ]" />
  <xsl:variable name="manage-last" select="$manages[ count( $manages ) ]" />

  <xsl:choose>
    <!-- if we have management steps, calculate the first step id after all of them -->
    <xsl:when test="$manages">
      <xsl:value-of select="count( $manage-last/preceding-sibling::lv:step ) + 2" />
    </xsl:when>

    <xsl:otherwise>
      <!-- 1's a pretty good place to start! -->
      <xsl:text>1</xsl:text>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<xsl:template name="compiler:gen-sorted-groups">
  <xsl:for-each select="//lv:step">
    <!-- step 0 doesn't exist, so always add -->
    <xsl:text>,</xsl:text>

    <xsl:text>{</xsl:text>
      <xsl:for-each select=".//preproc:sorted-groups">
        <xsl:if test="position() > 1">
          <xsl:text>,</xsl:text>
        </xsl:if>

        <xsl:text>'</xsl:text>
          <xsl:value-of select="@id" />
        <xsl:text>':[</xsl:text>

          <xsl:for-each select="preproc:group">
            <xsl:if test="position() > 1">
              <xsl:text>,</xsl:text>
            </xsl:if>

            <!-- [ group id, [ sort fields ] ] -->
            <xsl:text>[</xsl:text>
              <xsl:text>'</xsl:text>
                <xsl:value-of select="@ref" />
              <xsl:text>',[</xsl:text>

                <xsl:for-each select="preproc:sort">
                  <xsl:if test="position() > 1">
                    <xsl:text>,</xsl:text>
                  </xsl:if>

                  <xsl:text>'</xsl:text>
                    <xsl:value-of select="@by" />
                  <xsl:text>'</xsl:text>
                </xsl:for-each>

              <xsl:text>]</xsl:text>
            <xsl:text>]</xsl:text>
          </xsl:for-each>

        <xsl:text>]</xsl:text>
      </xsl:for-each>
    <xsl:text>}</xsl:text>
  </xsl:for-each>
</xsl:template>

<xsl:template match="lv:static" mode="generate-static">
  <xsl:apply-templates mode="generate-static" />
</xsl:template>
<!-- simply coopy static nodes -->
<xsl:template match="*" mode="generate-static">
  <xsl:value-of select="concat('&lt;',name())"/>
    <xsl:apply-templates select="@*" mode="generate-static" />
    <xsl:text>&gt;</xsl:text>
    <xsl:apply-templates mode="generate-static" />
  <xsl:value-of select="concat('&lt;/',name(),'&gt;')"/>
</xsl:template>

<xsl:template match="@*" mode="generate-static">
  <xsl:value-of select="concat(' ',name(),'=&quot;')"/>
    <xsl:value-of select="." />
  <xsl:text>"</xsl:text>
</xsl:template>

<xsl:template match="text()" mode="generate-static">
  <xsl:value-of select="translate(.,'&#xA;',' ')"/>
</xsl:template>

</xsl:stylesheet>

