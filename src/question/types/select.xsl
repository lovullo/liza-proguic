<?xml version="1.0" encoding="ISO-8859-1"?>
<!--
  Select (dropdown) question type

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
-->
<xsl:stylesheet version="2.0"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:lv="http://www.lovullo.com">

<xsl:template match="lv:question[@type='select']">
  <xsl:param name="id" select="@id" />
  <xsl:param name="prefix" />

  <select>
    <xsl:call-template name="generic-attributes">
      <xsl:with-param name="id" select="$id" />
      <xsl:with-param name="prefix" select="$prefix" />
    </xsl:call-template>

    <xsl:for-each select="lv:option">
      <option>
        <!-- optional id -->
        <xsl:if test="@id">
          <xsl:attribute name="id">
            <xsl:call-template name="qid">
              <xsl:with-param name="prefix" select="$prefix" />
            </xsl:call-template>
          </xsl:attribute>
        </xsl:if>

        <!-- value attribute (required) -->
        <xsl:attribute name="value" select="@value" />

        <!-- optional default attribute -->
        <xsl:if test="@default">
          <xsl:attribute name="selected">selected</xsl:attribute>
        </xsl:if>

        <!-- the value of the node -->
        <xsl:if test=". = '-'">
          <xsl:value-of select="@value"/>
        </xsl:if>
        <xsl:if test="not( . = '-' )">
          <xsl:value-of select="."/>
        </xsl:if>
      </option>
    </xsl:for-each>
  </select>
</xsl:template>


<!--
    determines the default value
-->
<xsl:template match="lv:*[@type='select']" mode="get-default">
  <xsl:variable name="default" select="lv:option[@default='true']" />

  <!-- first attempt to use the value marked as the default -->
  <xsl:choose>
    <!-- a default node was found -->
    <xsl:when test="$default">
      <xsl:value-of select="if ( $default/@value ) then $default/@value else ''" />
    </xsl:when>

    <!-- otherwise, use the first element as the default, since this is what will
         be displayed by default in the client -->
    <xsl:otherwise>
      <xsl:value-of select="lv:option[1]/@value" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet>

