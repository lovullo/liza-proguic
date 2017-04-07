<?xml version="1.0" encoding="ISO-8859-1"?>
<!--
  Table group

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

<xsl:template match="/lv:program/lv:step/lv:group[@style='table']"
  mode="group-select"
  priority="2">

  <!-- allows rows to be locked after they are added (so that they cannot be
       modified), but allows new rows to still be added -->
  <xsl:variable name="rowlock" select="lv:prop[@name='rowlock']" />

  <table>
    <xsl:attribute name="class">
      <xsl:text>groupTable</xsl:text>
      <xsl:if test="@locked">
        <xsl:text> locked</xsl:text>
      </xsl:if>

      <xsl:if test="$rowlock">
        <xsl:text> rowlock</xsl:text>
      </xsl:if>
    </xsl:attribute>
    <thead>
      <xsl:for-each select="lv:question|lv:question-copy|lv:answer|lv:display">
        <th id="qhead_{@id}">
          <!-- if in debug, add an anchor to easily locate questions -->
          <xsl:if test="$debug and @id">
            <xsl:attribute name="title"><xsl:value-of select="@id"/></xsl:attribute>

            <a name="_{@id}"/>
          </xsl:if>

          <xsl:if test="@hidden = true()">
            <xsl:attribute name="class">hidden</xsl:attribute>
          </xsl:if>

          <!-- @label overrides ref label -->
          <xsl:choose>
            <xsl:when test="@label">
              <xsl:value-of select="@label" />
            </xsl:when>

            <xsl:otherwise>
              <xsl:variable name="ref" select="@ref" />
              <xsl:value-of select="//lv:question[@id=$ref]/@label" />
            </xsl:otherwise>
          </xsl:choose>
        </th>
      </xsl:for-each>
      <xsl:if test="not( $rowlock = 'true' )">
        <th class="delrow">Remove</th>
      </xsl:if>
    </thead>

    <tbody>
      <tr>
        <xsl:for-each select="lv:question|lv:question-copy|lv:answer|lv:display">
          <xsl:variable name="i" select="position()" />

          <td>
            <xsl:attribute name="data-contained-field-name" select="@id" />

            <xsl:attribute name="columnIndex" select="$i - 1" />

            <!-- add question id as tooltip for debugging purposes -->
            <xsl:if test="$debug and @id">
              <xsl:attribute name="title"><xsl:value-of select="@id"/></xsl:attribute>
            </xsl:if>

            <xsl:if test="@hidden = true()">
              <xsl:attribute name="class">hidden</xsl:attribute>
            </xsl:if>

            <xsl:apply-templates select="." />
          </td>
        </xsl:for-each>

        <xsl:if test="not( $rowlock = 'true' )">
          <td class="delrow"> </td>
        </xsl:if>
      </tr>
    </tbody>
  </table>

  <xsl:if test="not( $debug )">
    <div class="addrow">Add <xsl:value-of select="@prefix" /></div>
  </xsl:if>
</xsl:template>

</xsl:stylesheet>

