<?xml version="1.0" encoding="ISO-8859-1"?>
<!--
  Group HTML generation

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

<!-- supported styles -->
<xsl:include href="default.xsl"/>
<xsl:include href="table.xsl"/>
<xsl:include href="sidetable.xsl"/>
<xsl:include href="collapsetable.xsl"/>
<xsl:include href="stacked.xsl"/>
<xsl:include href="tabbed.xsl"/>
<xsl:include href="tabbedblock.xsl"/>

<xsl:template name="group-id">
  <xsl:text>group_</xsl:text>
  <xsl:if test="@id">
    <xsl:value-of select="@id"/>
  </xsl:if>
  <!-- if no id, then we have a problem -->
  <xsl:if test="not(@id)">
    <xsl:message terminate="yes"
                 select="'Missing group id: ', @*" />
  </xsl:if>
</xsl:template>

<xsl:template match="/lv:program/lv:step/lv:group">
  <fieldset class="stepGroup {@style} {@class}">
    <xsl:attribute name="id">
      <xsl:call-template name="group-id" />
    </xsl:attribute>

    <xsl:if test="@title">
      <legend><span><xsl:value-of select="@title"/></span></legend>
    </xsl:if>

    <xsl:apply-templates select="." mode="group-select" />
  </fieldset>
</xsl:template>

<xsl:template match="lv:prop" mode="generate">
  <!-- do nothing -->
</xsl:template>

</xsl:stylesheet>

