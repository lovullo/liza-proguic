<?xml version="1.0" encoding="ISO-8859-1"?>
<!--
  Radio question type

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
  xmlns:lv="http://www.lovullo.com">

<xsl:template match="lv:question[@type='legacyradio']">
  <xsl:param name="id" select="@id" />
  <xsl:param name="prefix" />
  <xsl:param name="value" select="@value" />
  <xsl:param name="elementLabel" select="@elementLabel" />

  <label>
    <input type="radio">
      <xsl:attribute name="data-legacy">legacy</xsl:attribute>
      <xsl:call-template name="generic-attributes">
        <xsl:with-param name="id" select="$id" />
        <xsl:with-param name="prefix" select="$prefix" />
      </xsl:call-template>

      <!-- use value if available, otherwise the HTML default of 'on' -->
      <xsl:attribute name="value" select="if ( $value ) then $value else 'on'" />
    </input>

    <!-- output label if requested -->
    <xsl:if test="$elementLabel">
      <label>
        <xsl:attribute name="for" select="$id" />
        <xsl:value-of select="$elementLabel" />
      </label>
    </xsl:if>
  </label>
</xsl:template>

</xsl:stylesheet>

