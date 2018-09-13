<?xml version="1.0" encoding="ISO-8859-1"?>
<!--
  Program UI compiler entry point

  Copyright (C) 2017-2018 R-T Specialty, LLC.

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

<xsl:stylesheet version="2.0"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:lv="http://www.lovullo.com">

<xsl:output
  method="xml"
  indent="yes"
  omit-xml-declaration="yes"
  />

<!-- static development transformation -->
<xsl:include href="static.xsl"/>

<!-- contains question type conversion -->
<xsl:include href="question/question.xsl"/>

<!-- contains group styles -->
<xsl:include href="group/group.xsl"/>


<!--
  debug mode if XSLT 2.0 not supported

  When in debug, the static stylesheet will be used. Note that in the future,
  browser detection should be used in addition to this check, so that the
  static development version is always displayed when viewing the XML file
  directly.
-->
<xsl:variable name="debug" select="number(system-property('xsl:version')) = 1.0"/>


<!--
  Outputs navigation

  Should be called from within a root program node
-->
<xsl:template name="navigation">
  <xsl:message>Generating step navigation menu...</xsl:message>

  <ul class="step-nav">
    <xsl:for-each select="lv:step">
      <li class="{@type}">
        <a>
          <xsl:attribute name="href">#<xsl:value-of select="translate( @title, ' ', '_' )"/></xsl:attribute>
          <xsl:value-of select="@title"/>
        </a>
      </li>
    </xsl:for-each>
  </ul>
</xsl:template>


<!--
  generates separate template file for a given step
-->
<xsl:template match="/lv:program/lv:step">
  <xsl:variable name="name" select="lower-case(translate( @title, ' ', '_' ))"/>

  <xsl:message>Generating step template for <xsl:value-of select="$name"/>...</xsl:message>

  <xsl:apply-templates select="lv:group"/>
</xsl:template>


<xsl:template match="/lv:program/lv:step/lv:group/lv:static" mode="generate">
  <dt>
    <xsl:if test="@id">
      <xsl:attribute name="id">
        <xsl:value-of select="@id"/>
      </xsl:attribute>

      <!-- XXX: this is certainly not valid XHTML -->
      <xsl:attribute name="name">
        <xsl:value-of select="@id"/>
        <xsl:text>[]</xsl:text>
      </xsl:attribute>
    </xsl:if>

    <xsl:attribute name="class">
      <xsl:text>static widget</xsl:text>
      <!-- alternating rows (not sure when position() is returning by 2) -->
      <xsl:if test="position() mod 4 != 0"> alt</xsl:if>

      <!-- add any user-defined classes -->
      <xsl:if test="@class">
        <xsl:text> </xsl:text>
        <xsl:value-of select="@class" />
      </xsl:if>
    </xsl:attribute>

    <xsl:apply-templates mode="generate-static" />
  </dt>
</xsl:template>

<xsl:template match="lv:static" mode="generate-static">
  <xsl:apply-templates mode="generate-static" />
</xsl:template>
<xsl:template match="lv:prop" mode="generate-static">
  <xsl:apply-templates mode="generate-static" />
</xsl:template>


<xsl:template match="lv:*" mode="generate-static" priority="5">
  <xsl:apply-templates select="." />
</xsl:template>


<xsl:template match="xhtml:*" mode="generate-static" priority="3">
  <xsl:element name="{local-name(.)}">
    <xsl:apply-templates mode="generate-static"
                         select="@*|node()" />
  </xsl:element>
</xsl:template>

<xsl:template match="xhtml:*/@*" mode="generate-static" priority="3">
  <xsl:attribute name="{local-name(.)}">
    <xsl:value-of select="." />
  </xsl:attribute>
</xsl:template>

<xsl:template match="*" mode="generate-static" priority="1">
  <xsl:message terminate="yes">
    <xsl:text>Invalid static element: </xsl:text>
    <xsl:copy-of select="." />
  </xsl:message>
</xsl:template>



<xsl:template match="/lv:program/lv:step/lv:group/lv:answer|/lv:program/lv:step/lv:group/lv:display" mode="generate">
  <xsl:variable name="class">
    <xsl:text>answer</xsl:text>
    <!-- alternating rows (not sure when position() is returning by 2) -->
    <xsl:if test="position() mod 4 != 0"> alt</xsl:if>
    <xsl:if test="@class">
      <xsl:text> </xsl:text>
      <xsl:value-of select="@class" />
    </xsl:if>
    <xsl:if test="@internal = 'true'">
      <xsl:text> hidden i</xsl:text>
    </xsl:if>
  </xsl:variable>

  <dt>
    <xsl:if test="@id">
      <xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
    </xsl:if>

    <xsl:attribute name="class" select="$class" />

    <!-- explicitly specified label should override the reference label -->
    <xsl:variable name="ref" select="@ref"/>
    <xsl:variable name="reflabel" select="//lv:question[@id=$ref]/@label" />
    <xsl:value-of select="if ( @label ) then @label else $reflabel" />
  </dt>
  <dd>
    <xsl:if test="@id">
      <xsl:attribute name="id"><xsl:value-of select="@id"/>_value</xsl:attribute>
    </xsl:if>

    <xsl:attribute name="class" select="$class" />

    <xsl:apply-templates select="." />
  </dd>
</xsl:template>

<!--
    Answer and display are essentially the same thing. Answer simply gets most
    of its information from an existing question.
-->
<xsl:template match="lv:answer|lv:display">
  <xsl:param name="prefix" />

  <!-- generate the ref (may contain a prefix) -->
  <xsl:variable name="ref">
    <xsl:if test="$prefix">
      <xsl:value-of select="$prefix" />
      <xsl:text>_</xsl:text>
    </xsl:if>

    <!-- add on the id -->
    <xsl:value-of select="@ref" />
  </xsl:variable>

  <!-- this names allows it to be transparently selected by the framework as any
       other element would -->
  <span data-index="0" name="{@id}[]" id="{@id}">
    <xsl:attribute name="class">
      <xsl:text>answer </xsl:text>
      <xsl:value-of select="@type" />

      <xsl:if test="@class">
        <xsl:text> </xsl:text>
        <xsl:value-of select="@class" />
      </xsl:if>

      <xsl:if test="@internal = 'true'">
        <xsl:text> hidden i</xsl:text>
      </xsl:if>
    </xsl:attribute>

    <xsl:attribute name="data-answer-ref">
      <xsl:value-of select="$ref" />
    </xsl:attribute>

    <xsl:if test="@id">
      <xsl:attribute name="data-field-name" select="@id" />
    </xsl:if>

    <xsl:if test="@index">
      <xsl:attribute name="data-answer-static-index">
        <xsl:value-of select="@index" />
      </xsl:attribute>
    </xsl:if>

    <xsl:if test="@allow-html">
      <xsl:attribute name="data-field-allow-html"
                     select="'true'" />
    </xsl:if>

    <xsl:value-of select="$ref" />
  </span>
</xsl:template>

</xsl:stylesheet>

