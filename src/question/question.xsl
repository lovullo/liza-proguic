<?xml version="1.0" encoding="ISO-8859-1"?>
<!--
  Generic template used for all text fields

  Copyright (C) 2017, 2018 R-T Specialty, LLC.

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

  The type of the field is added as a class so that styling or other
  JavaScript transformations may take place.
-->

<xsl:stylesheet version="2.0"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:lv="http://www.lovullo.com">

<!-- available question types -->
<xsl:include href="types/all.xsl" />

<xsl:template name="generic-text">
  <xsl:param name="id" select="@id" />
  <xsl:param name="prefix" />
  <xsl:param name="type" select="@type" />
  <xsl:param name="hidden" select="@hidden" />
  <xsl:param name="maxlength" select="@maxlength" />

  <input type="text">
    <xsl:if test="$maxlength and not( $maxlength = '' )">
      <xsl:attribute name="maxlength" select="$maxlength" />
    </xsl:if>

    <xsl:call-template name="generic-attributes">
      <xsl:with-param name="id" select="$id" />
      <xsl:with-param name="type" select="$type" />
      <xsl:with-param name="hidden" select="$hidden" />
      <xsl:with-param name="prefix" select="$prefix" />
    </xsl:call-template>
  </input>
</xsl:template>

<xsl:template name="generic-list">
  <xsl:param name="id" select="@id" />
  <xsl:param name="prefix" />
  <xsl:param name="index" select="''" />
  <xsl:param name="type" select="@type" />
  <xsl:param name="hidden" select="@hidden" />

  <xsl:variable name="genid">
      <xsl:call-template name="generate-id">
          <xsl:with-param name="id" select="$id" />
          <xsl:with-param name="prefix" select="$prefix" />
      </xsl:call-template>
  </xsl:variable>

  <input>
      <xsl:attribute name="list">
          <xsl:call-template name="qid">
              <xsl:with-param name="id" select="concat('datalist-_', $genid)" />
          </xsl:call-template>
      </xsl:attribute>

      <xsl:attribute name="name">
        <xsl:call-template name="qname">
          <xsl:with-param name="index" select="$index" />
          <xsl:with-param name="prefix" select="$prefix" />
        </xsl:call-template>
      </xsl:attribute>

    <xsl:call-template name="generic-attributes">
      <xsl:with-param name="id" select="$id" />
      <xsl:with-param name="type" select="$type" />
      <xsl:with-param name="hidden" select="$hidden" />
      <xsl:with-param name="prefix" select="$prefix" />
    </xsl:call-template>
  </input>
</xsl:template>

<xsl:template name="generic-textarea">
  <xsl:param name="id" select="@id" />
  <xsl:param name="prefix" />
  <xsl:param name="type" select="@type" />
  <xsl:param name="hidden" select="@hidden" />
  <xsl:param name="maxlength"
             select="if ( @maxlength and not( @maxlength = '' ) ) then
                         @maxlength
                       else
                         '1000'" />

  <textarea>
    <xsl:attribute name="maxlength"
                   select="$maxlength" />

    <xsl:call-template name="generic-attributes">
      <xsl:with-param name="id" select="$id" />
      <xsl:with-param name="type" select="$type" />
      <xsl:with-param name="hidden" select="$hidden" />
      <xsl:with-param name="prefix" select="$prefix" />
    </xsl:call-template>
  </textarea>
</xsl:template>

<!--
  Generic attributes to be used for most questions
-->
<xsl:template name="generic-attributes">
  <xsl:param name="id" select="@id" />
  <xsl:param name="type" select="@type" />
  <xsl:param name="index" select="''" />
  <xsl:param name="ignore-required" select="0" />
  <xsl:param name="hidden" select="@hidden" />
  <xsl:param name="prefix" />
  <xsl:param name="ref-id" select="@id" />

  <!-- generate the ref (may contain a prefix) -->
  <xsl:variable name="genid">
      <xsl:call-template name="generate-id">
          <xsl:with-param name="id" select="$id" />
          <xsl:with-param name="prefix" select="$prefix" />
      </xsl:call-template>
  </xsl:variable>

  <xsl:attribute name="id">
    <xsl:call-template name="qid">
      <xsl:with-param name="id" select="$genid" />
    </xsl:call-template>
  </xsl:attribute>

    <xsl:if test="@readonly = true()">
      <xsl:attribute name="readonly">
        <xsl:text>readonly</xsl:text>
      </xsl:attribute>
    </xsl:if>

  <xsl:attribute name="class">
    <xsl:text>widget input </xsl:text>
    <xsl:value-of select="$type"/>
    <xsl:if test="@required">
      <xsl:if test="not($ignore-required)">
        <xsl:text> required</xsl:text>
      </xsl:if>
    </xsl:if>
    <xsl:if test="@readonly = true()">
      <xsl:text> readonly</xsl:text>
    </xsl:if>
    <xsl:if test="$hidden = true()">
      <xsl:text> hidden</xsl:text>
    </xsl:if>
    <xsl:if test="@internal = true()">
      <xsl:text> internal</xsl:text>
    </xsl:if>
    <xsl:if test="@class">
      <xsl:text> </xsl:text>
      <xsl:value-of select="@class" />
    </xsl:if>
  </xsl:attribute>

  <xsl:attribute name="name">
    <xsl:call-template name="qname">
      <xsl:with-param name="index" select="$index" />
      <xsl:with-param name="prefix" select="$prefix" />
    </xsl:call-template>
  </xsl:attribute>

  <xsl:if test="@default">
    <xsl:attribute name="value">
      <xsl:value-of select="@default" />
    </xsl:attribute>
  </xsl:if>

  <!-- include the id as an HTML5 data-* attribute (so we don't need to worry
       about stripping [] off of the end of @name) -->
  <xsl:attribute name="data-field-name" select="$ref-id" />
</xsl:template>

<!--
  Generates question id for the current node
-->
<xsl:template name="qid">
  <xsl:param name="id" select="@id" />
  <xsl:param name="quote" select="false()" />
  <xsl:param name="index" select="0" />
  <xsl:param name="index-var" select="false()" />
  <xsl:param name="suffix" />
  <xsl:param name="prefix" />
  <xsl:param name="prefix_" select="false()" />

  <!-- opening quote -->
  <xsl:if test="$quote"><xsl:text>'</xsl:text></xsl:if>

  <!-- apply prefix -->
  <xsl:if test="string( $prefix ) != ''">
    <xsl:value-of select="$prefix" />
  </xsl:if>
  <xsl:if test="$prefix_ = true()">
    <xsl:text>_</xsl:text>
  </xsl:if>

  <!-- generate qid -->
  <xsl:text>q_</xsl:text><xsl:value-of select="$id" />

  <!-- apply suffix -->
  <xsl:if test="string( $suffix ) != ''">
    <xsl:value-of select="$suffix" />
  </xsl:if>

  <!-- append an index suffix, if provided -->
  <xsl:if test="string($index) != '' and not($index-var)">
    <xsl:text>_</xsl:text><xsl:value-of select="$index" />
  </xsl:if>

  <xsl:if test="$index-var and not($quote)">
    <xsl:message terminate="yes">qid index vars may only be used with quoted qids</xsl:message>
  </xsl:if>

  <xsl:if test="$quote">
    <!-- variable index suffix -->
    <xsl:choose>
      <xsl:when test="$index-var">
        <xsl:text>_' + </xsl:text>
        <xsl:value-of select="$index" />
      </xsl:when>

      <!-- closing quote -->
      <xsl:otherwise>
        <xsl:text>'</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:if>
</xsl:template>

<!--
  Shorthand for generating variable qids
-->
<xsl:template name="qid-var">
  <xsl:param name="id" select="@id" />
  <xsl:param name="index" select="'i'" />
  <xsl:param name="suffix" />
  <xsl:param name="prefix" />

  <xsl:call-template name="qid">
    <xsl:with-param name="id" select="$id" />
    <xsl:with-param name="quote" select="true()" />
    <xsl:with-param name="index" select="$index" />
    <xsl:with-param name="index-var" select="true()" />
    <xsl:with-param name="suffix" select="$suffix" />
    <xsl:with-param name="prefix" select="$prefix" />
  </xsl:call-template>
</xsl:template>

<!--
  Shorthand for generating a qid-var for use in a query

  e.g. #id_0
-->
<xsl:template name="qid-var-query">
  <xsl:param name="id" select="@id" />

  <xsl:call-template name="qid-var">
    <xsl:with-param name="id" select="$id" />
    <xsl:with-param name="prefix" select="'#'" />
  </xsl:call-template>
</xsl:template>

<!--
  Generates a question name with the index
-->
<xsl:template name="qname">
  <xsl:param name="index" select="''" />
  <xsl:param name="quote" select="false()" />
  <xsl:param name="id" select="@id" />
  <xsl:param name="index-var" select="false()" />
  <xsl:param name="prefix" />

  <!-- opening quote -->
  <xsl:if test="$quote"><xsl:text>'</xsl:text></xsl:if>

  <!-- generate name -->
  <xsl:if test="$prefix">
    <xsl:value-of select="$prefix" />
    <xsl:text>_</xsl:text>
  </xsl:if>

  <!-- add on the id -->
  <xsl:value-of select="$id" />

  <xsl:call-template name="qi">
    <xsl:with-param name="index" select="$index" />
    <xsl:with-param name="index-var" select="$index-var" />
  </xsl:call-template>

  <!-- closing quote -->
  <xsl:if test="$quote"><xsl:text>'</xsl:text></xsl:if>
</xsl:template>

<!--
  Shorthand for creating variable qnames
-->
<xsl:template name="qname-var">
  <xsl:param name="id" select="@id" />
  <xsl:param name="index" select="'i'" />

  <xsl:call-template name="qname">
    <xsl:with-param name="id" select="$id" />
    <xsl:with-param name="quote" select="true()" />
    <xsl:with-param name="index" select="$index" />
    <xsl:with-param name="index-var" select="true()" />
  </xsl:call-template>
</xsl:template>

<!--
  Generates question index

  The logic for this is non-existant at present (since multiple indicies are
  generally generated at runtime), however we supply the separate template in
  order to easily modify that logic in the future.
-->
<xsl:template name="qi">
  <xsl:param name="index" select="''" />
  <xsl:param name="index-var" select="false()" />

  <xsl:text>[</xsl:text>

  <xsl:if test="$index-var">' + </xsl:if>
  <xsl:value-of select="$index" />
  <xsl:if test="$index-var"> + '</xsl:if>

  <xsl:text>]</xsl:text>
</xsl:template>

<!--
  Same concept as the "qi" template, but doesn't represent as an array index.

  Ex: "_0"
-->
<xsl:template name="qi-suffix">
  <xsl:param name="index" select="0" />
  <xsl:text>_</xsl:text><xsl:value-of select="$index" />
</xsl:template>

<!--
  Generates a question id with the index
-->
<xsl:template name="qidi">
  <xsl:param name="index" select="0" />

  <xsl:call-template name="qid" />
  <xsl:call-template name="qi-suffix">
    <xsl:with-param name="index" select="$index" />
  </xsl:call-template>
</xsl:template>

<!--
  Generates a query string for a qidi template for use with functions like
  dojo.query or jquery

  Returns something like: '#qid_' + i
-->
<xsl:template name="qidi-query-var">
  <xsl:text>'#</xsl:text>
  <xsl:call-template name="qidi">
    <xsl:with-param name="index">' + i</xsl:with-param>
  </xsl:call-template>
</xsl:template>

<!-- deprecated; forwards to qname -->
<xsl:template name="qnamei">
  <xsl:param name="index" select="0" />

  <xsl:call-template name="qname">
    <xsl:with-param name="index" select="$index" />
  </xsl:call-template>
</xsl:template>

<xsl:template name="qcopy-id">
  <!-- if an id was provided, use that -->
  <xsl:if test="@id">
    <xsl:value-of select="@id" />
  </xsl:if>
  <!-- otherwise generate our own -->
  <xsl:if test="not(@id)">
    <xsl:value-of select="@ref" />_<xsl:value-of select="generate-id(.)" />
  </xsl:if>
</xsl:template>

<!-- copy the referenced question in place -->
<xsl:template match="lv:question-copy" mode="generate">
  <xsl:variable name="ref" select="@ref"/>

  <xsl:apply-templates select="//lv:question[@id=$ref]" mode="generate">
    <xsl:with-param name="id">
      <xsl:call-template name="qcopy-id" />
    </xsl:with-param>
    <xsl:with-param name="ref-id" select="$ref" />
    <xsl:with-param name="value" select="@value" />
    <xsl:with-param name="elementLabel" select="@elementLabel" />

    <!-- overrides (optional) -->
    <xsl:with-param name="class-override" select="@class" />
    <xsl:with-param name="hidden-override" select="@hidden" />
  </xsl:apply-templates>
</xsl:template>

<!-- question-copy for when mode != "generate" -->
<xsl:template match="lv:question-copy">
  <xsl:variable name="ref" select="@ref"/>
  <xsl:apply-templates select="//lv:question[@id=$ref]">
    <xsl:with-param name="id">
      <xsl:call-template name="qcopy-id" />
    </xsl:with-param>
    <xsl:with-param name="value" select="@value" />
    <xsl:with-param name="elementLabel" select="@elementLabel" />
  </xsl:apply-templates>
</xsl:template>

<!-- default template if question type was not found -->
<xsl:template match="lv:question">
  <xsl:variable name="error">
    Unknown element type '<xsl:value-of select="@type"/>'
    for question '<xsl:value-of select="@id"/>'
  </xsl:variable>

  <!-- log the error -->
  <xsl:message>
    <xsl:value-of select="$error"/>
  </xsl:message>

  <!-- display the error in the generated HTML to grab attention -->
  <em class="error" style="color:red">
    <strong>Error:</strong> <xsl:value-of select="$error"/>
  </em>
</xsl:template>

<xsl:template match="lv:question" mode="generate">
  <xsl:param name="id" select="@id" />
  <xsl:param name="class-override" />
  <xsl:param name="hidden-override" />

  <xsl:variable name="class">
    <xsl:choose>
      <xsl:when test="$class-override">
        <xsl:value-of select="$class-override" />
      </xsl:when>

      <xsl:otherwise>
        <xsl:value-of select="@class" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="hidden">
    <xsl:choose>
      <xsl:when test="$hidden-override">
        <xsl:value-of select="$hidden-override" />
      </xsl:when>

      <xsl:otherwise>
        <xsl:value-of select="@hidden" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <dt id="qlabel_{@id}">
    <xsl:attribute name="class">
      <xsl:value-of select="@type" />
      <xsl:if test="$hidden = 'true'">
        <xsl:text> hidden</xsl:text>
      </xsl:if>
      <xsl:if test="$class">
        <xsl:text> </xsl:text>
        <xsl:value-of select="$class" />
      </xsl:if>
      <xsl:if test="@internal = true()">
        <xsl:text> hidden i</xsl:text>
      </xsl:if>
    </xsl:attribute>

    <!-- if in debug, add an anchor to easily locate questions -->
    <xsl:if test="$debug">
      <xsl:attribute name="title"><xsl:value-of select="@id"/></xsl:attribute>

      <a name="_{@id}"/>
    </xsl:if>

    <xsl:value-of select="@label"/>
  </dt>
  <dd id="qcontainer_{@id}">
    <xsl:attribute name="data-contained-field-name" select="@id" />

    <xsl:attribute name="class">
      <xsl:value-of select="@type" />
      <xsl:if test="$hidden = 'true'">
        <xsl:text> hidden</xsl:text>
      </xsl:if>
      <xsl:if test="$class">
        <xsl:text> </xsl:text>
        <xsl:value-of select="$class" />
      </xsl:if>
      <xsl:if test="@internal = true()">
        <xsl:text> hidden i</xsl:text>
      </xsl:if>
    </xsl:attribute>

    <!-- add question id as tooltip for debugging purposes -->
    <xsl:if test="$debug">
      <xsl:attribute name="title"><xsl:value-of select="@id"/></xsl:attribute>
    </xsl:if>

    <!-- allow the templates for the specific question types to be applied -->
    <xsl:apply-templates select=".">
      <xsl:with-param name="id" select="$id" />
    </xsl:apply-templates>

    <!-- generate actions -->
    <xsl:apply-templates select="./lv:action" mode="generate">
      <xsl:with-param name="id" select="$id" />
    </xsl:apply-templates>
  </dd>
</xsl:template>


<xsl:template match="lv:question/lv:action[ @style='button' ]" mode="generate">
  <!-- question id (may vary from the parent id) -->
  <xsl:param name="id" />

  <button class="action" data-type="{@on}" data-ref="{$id}">
    <xsl:value-of select="@desc" />
  </button>
</xsl:template>


<!--
    Default 'default' value, if no implementation is given for the specific
    question type
-->
<xsl:template match="lv:*" mode="get-default">
  <xsl:if test="@default">
    <xsl:value-of select="@default" />
  </xsl:if>
</xsl:template>

<xsl:template name="generate-id">
    <xsl:param name="id" select="@id" />
    <xsl:param name="prefix" />

    <xsl:if test="$prefix">
        <xsl:value-of select="$prefix" />
        <xsl:text>_</xsl:text>
    </xsl:if>

    <!-- add on the id -->
    <xsl:value-of select="$id" />
</xsl:template>

</xsl:stylesheet>

