<?xml version="1.0" encoding="ISO-8859-1"?>
<!--
  Tabbed group

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
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:lv="http://www.lovullo.com">

<xsl:template match="/lv:program/lv:step/lv:group[@style='tabbed']"
  mode="group-select"
  priority="2">

  <div class="groupTabs">
    <xsl:attribute name="class">
      <xsl:text>groupTabs</xsl:text>
      <xsl:if test="@locked">
        <xsl:text> locked</xsl:text>
      </xsl:if>
    </xsl:attribute>
    <ul>
      <li>
        <a href="#group_tab_{@id}">
          <xsl:value-of select="@prefix" />
        </a>
      </li>
    </ul>
    <div id="group_tab_{@id}">
      <xsl:call-template name="group-default" />
      <br class="tabClear" />
    </div>
  </div>

  <xsl:if test="not( $debug )">
    <div class="addTab">Add <xsl:value-of select="@prefix" /></div>
  </xsl:if>
</xsl:template>

</xsl:stylesheet>

