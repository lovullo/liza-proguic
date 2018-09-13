<?xml version="1.0"?>
<!--
  Generates code for calculated values

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
<xsl:stylesheet version="2.0"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:lv="http://www.lovullo.com"
  xmlns:assert="http://www.lovullo.com/assert">

<xsl:output
  method="text"
  indent="yes"
  omit-xml-declaration="yes"
  />


<!--
  Generates code for calculating values
-->
<xsl:template match="lv:calc" mode="gen-calc">
  <xsl:param name="deps" select="false()" />
  <xsl:param name="children" select="false()" />
  <xsl:param name="with-diff" select="true()" />
  <xsl:param name="method" select="'overwriteValues'" />

  <xsl:variable name="id" select="@id" />
  <xsl:variable name="ref" select="@ref" />
  <xsl:variable name="value" select="@value" />

  <!-- if we're to handle dependencies, parse them first (recursive) -->
  <xsl:if test="$deps = true()">
    <xsl:apply-templates select="//lv:calc[ @id=$ref or @id=$value ]" mode="gen-calc">
      <xsl:with-param name="deps" select="true()" />
      <xsl:with-param name="with-diff" select="$with-diff" />
    </xsl:apply-templates>
  </xsl:if>

  <!-- recursively search for dependencies (note that we use merge-diff rather
       than simply ignoring the diff entirely because we do not want to trigger
       delayed merging; see DelayedStagingBucket) -->
  <xsl:text>bucket.</xsl:text>
  <xsl:value-of select="$method" />
  <xsl:text>({</xsl:text>
  <xsl:value-of select="@id" />
  <xsl:text>:Calc['</xsl:text>
    <xsl:value-of select="@method" />
  <xsl:text>']</xsl:text>
  <xsl:text>(</xsl:text>
    <xsl:call-template name="parse-expected">
      <xsl:with-param name="expected" select="@ref" />
      <xsl:with-param name="merge-diff" select="$with-diff" />
    </xsl:call-template>
  <xsl:text>,</xsl:text>
    <xsl:call-template name="parse-expected">
      <xsl:with-param name="expected" select="@value" />
      <xsl:with-param name="merge-diff" select="$with-diff" />
    </xsl:call-template>
  <xsl:text>)});</xsl:text>

  <!-- any that depend on us? -->
  <xsl:if test="$children = true()">
    <xsl:apply-templates select="//lv:calc[ @ref=$id or @value=$id ]" mode="gen-calc">
      <xsl:with-param name="children" select="true()" />
    </xsl:apply-templates>
  </xsl:if>
</xsl:template>

</xsl:stylesheet>

