<?xml version="1.0" encoding="ISO-8859-1"?>
<!--
  checkbox question type

  Copyright (C) 2018 R-T Specialty, LLC.

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

  <xsl:template match="lv:question[@type='checkbox']">
    <xsl:param name="id" select="@id" />
    <xsl:param name="prefix" />

    <div style="white-space: nowrap">
      <label>
        <input type="checkbox" value="1">
          <xsl:attribute name="data-field-name" select="$id" />
          <xsl:attribute name="data-question-length" select="1" />
          <xsl:attribute name="style">padding: 0;</xsl:attribute>
          <xsl:attribute name="id">
            <xsl:call-template name="qid">
              <xsl:with-param name="id" select="$id" />
              <xsl:with-param name="suffix" select="'_n'" />
              <xsl:with-param name="prefix" select="$prefix" />
            </xsl:call-template>
          </xsl:attribute>

          <xsl:attribute name="class">widget plain</xsl:attribute>

          <xsl:attribute name="name">
            <xsl:call-template name="qname">
              <xsl:with-param name="prefix" select="$prefix" />
            </xsl:call-template>
          </xsl:attribute>
          <xsl:if test="@default = 'checked'">
            <xsl:attribute name="checked">checked</xsl:attribute>
          </xsl:if>
        </input>
      </label>
    </div>
  </xsl:template>

  <!--
    determines the default value

    If 'yes', then default is 1
    If 'no' checked, then default is 0
    Else, default is empty
  -->
  <xsl:template match="lv:*[@type='checkbox']" mode="get-default">
    <xsl:if test="@default='yes'">
      <xsl:text>1</xsl:text>
    </xsl:if>

    <xsl:if test="not( @default='yes' )">
      <xsl:text>0</xsl:text>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>

