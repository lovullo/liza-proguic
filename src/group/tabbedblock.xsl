<?xml version="1.0" encoding="ISO-8859-1"?>
<!--
  Block tabbed group

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

<xsl:template match="lv:group[@style='tabbedblock']"
  mode="group-select"
  priority="2">

  <xsl:variable name="logo"     select="lv:prop[@name='logo']" />
  <xsl:variable name="tabTitle" select="lv:prop[@name='tabTitle']" />
  <xsl:variable name="supplier" select="lv:prop[@name='supplier']" />
  <xsl:variable name="lengthField" select="lv:prop[@name='lengthField']" />
  <xsl:variable name="selectedField" select="lv:prop[@name='selectedField']" />

  <xsl:variable name="tabextract-src" select="lv:prop[@name='tabextractSrc']" />
  <xsl:variable name="tabextract-dest"   select="lv:prop[@name='tabextractDest']" />

  <xsl:variable name="disableFlags">
    <xsl:for-each select="lv:prop[@name='disableFlag']">
      <xsl:if test="position() > 1">
        <xsl:text>;</xsl:text>
      </xsl:if>

      <xsl:value-of select="." />
    </xsl:for-each>
  </xsl:variable>

  <div data-disable-flags="{$disableFlags}"
    data-tabextract-src="{$tabextract-src}"
    data-tabextract-dest="{$tabextract-dest}"
    data-length-field="{$lengthField}"
    data-default-selected-field="{$selectedField}">

    <xsl:attribute name="class">
      <xsl:text>groupTabbedBlock</xsl:text>

      <xsl:if test="@locked='true'">
        <xsl:text> locked</xsl:text>
      </xsl:if>
    </xsl:attribute>

    <img class="raterLogo">
      <xsl:attribute name="src">
        <xsl:apply-templates select="$logo" />
      </xsl:attribute>
      <xsl:attribute name="alt">
        <xsl:apply-templates select="$supplier"/>
      </xsl:attribute>
    </img>

    <!-- tab selection -->
    <div class="tabs">
      <ul class="tabs">
        <li>
          <a href="#group_tab_{@id}">
            <xsl:apply-templates select="$tabTitle" />
          </a>
        </li>
      </ul>
    </div>

    <!-- tab content -->
    <div id="group_tab_{@id}" class="tab-content">
      <!-- generate default content; we're simply enclosing an otherwise
           "normal" group into a tabbed environment -->
      <xsl:call-template name="group-default" />
      <xsl:if test="@compare">
        <div class="compareOptions navbtns">
          <input type="checkbox" >
            <xsl:attribute name="value" select="$supplier" />
            <xsl:attribute name="class">
              <xsl:text>compareOption</xsl:text>
            </xsl:attribute>
          </input><span>Compare</span>
        </div>
      </xsl:if>

       <xsl:for-each select="lv:prop[@name='button']">
        <input type="button" >
            <xsl:attribute name="name" select="$supplier" />
            <xsl:attribute name="value" select="." />
            <xsl:if test="@class">
              <xsl:attribute name="class">
                <xsl:value-of select="@class" />
              </xsl:attribute>
            </xsl:if>
        </input>
       </xsl:for-each>
    </div>

    <br class="tabClear" />
  </div>

  <!-- permits adding tabs (this may be hidden by the group if it is locked, but
       we still want to output it in case it needs to be shown) -->
  <div class="addTab">
    <xsl:text>Add </xsl:text>
    <xsl:value-of select="@prefix" />
  </div>
</xsl:template>

</xsl:stylesheet>

