<?xml version="1.0" encoding="ISO-8859-1"?>
<!--
  Number question type

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

<xsl:template match="lv:question[@type='number']">
  <xsl:param name="id" select="@id" />
  <xsl:param name="prefix" />

  <input type="text">
    <xsl:call-template name="generic-attributes">
      <xsl:with-param name="prefix" select="$prefix" />
      <xsl:with-param name="id" select="$id" />
    </xsl:call-template>
    <xsl:if test="not(@default)">
      <xsl:attribute name="value">0</xsl:attribute>
    </xsl:if>
  </input>
</xsl:template>


<!--
    determines the default value
-->
<xsl:template match="lv:*[@type='number']" mode="get-default">
  <xsl:value-of select="if ( @default ) then @default else '0'" />
</xsl:template>

</xsl:stylesheet>

