<?xml version="1.0" encoding="ISO-8859-1"?>
<!--
  Side-table group

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

<xsl:template match="/lv:program/lv:step/lv:group[@style='sidetable']"
  mode="group-select"
  priority="2">

  <xsl:variable name="tableTitle" select="lv:prop[@name='tableTitle']" />
  <xsl:variable name="columns" select="lv:prop[@name='columns']" />
  <xsl:variable name="columnSuffix" select="lv:prop[@name='columnSuffix']" />
  <xsl:variable name="staticHead" select="lv:prop[@name='staticHead']" />
  <xsl:variable name="columnClasses" select="lv:prop[@name='columnClasses']" />
  <xsl:variable name="colclass" select="tokenize( $columnClasses, ',' )" />

  <xsl:variable name="colcount">
    <xsl:if test="$debug or not( $columns )">1</xsl:if>
    <xsl:if test="not( $debug ) and $columns">
      <xsl:value-of select="count( tokenize( $columns, ',' ) )" />
    </xsl:if>
  </xsl:variable>


  <table>
    <xsl:attribute name="class">
      <xsl:text>groupTable</xsl:text>
      <xsl:if test="@locked">
        <xsl:text> locked</xsl:text>
      </xsl:if>
    </xsl:attribute>

    <thead>
      <tr>
        <th class="groupTableSide">
          <xsl:if test="$columns">
            <xsl:attribute name="rowspan">2</xsl:attribute>
          </xsl:if>

          <xsl:value-of select="$tableTitle" />
        </th>
        <th>
          <xsl:if test="$columns and not( $debug )">
            <xsl:attribute name="colspan">
              <xsl:value-of select="count( tokenize( $columns, ',' ) )" />
            </xsl:attribute>
          </xsl:if>

          <xsl:value-of select="@prefix" />

          <!-- if static text was given for the head, we don't want to display
               an index -->
          <xsl:if test="$staticHead">
            <xsl:value-of select="$staticHead" />
          </xsl:if>
          <xsl:if test="not( $staticHead )">
            <span class="colindex"></span>
          </xsl:if>

          <xsl:if test="$columnSuffix">
            <xsl:apply-templates select="$columnSuffix" />
          </xsl:if>
        </th>
      </tr>

      <xsl:if test="$columns">
        <tr>
          <!-- for debug (and XSLT 1.0 ) -->
          <xsl:if test="$debug">
            <th><xsl:value-of select="$columns" /></th>
          </xsl:if>

          <!-- actually generate the columns if not debug mode -->
          <xsl:if test="not( $debug )">
            <xsl:for-each select="tokenize( $columns, ',' )">
              <xsl:variable name="i" select="position()" />
              <th>
                <xsl:attribute name="columnIndex" select="$i - 1" />
                <xsl:attribute name="class" select="$colclass[ $i ]" />
                <xsl:value-of select="." />
              </th>
            </xsl:for-each>
          </xsl:if>
        </tr>
      </xsl:if>
    </thead>

    <tbody>
      <xsl:for-each select="lv:question | lv:answer | lv:display | lv:static | lv:question-copy">
        <xsl:variable name="i" select="position()" />

        <!-- output the side column as the first cell -->
        <xsl:if test="( position() - 1 ) mod $colcount = 0">
          <xsl:if test="position() gt 1">
            <xsl:text disable-output-escaping="yes">&lt;/tr&gt;</xsl:text>
          </xsl:if>
          <xsl:text disable-output-escaping="yes">&lt;tr&gt;</xsl:text>

          <!-- side column -->
          <td class="groupTableSide">
            <xsl:if test="@ref and not( @label )">
              <xsl:variable name="ref" select="@ref" />
              <xsl:value-of select="//lv:question[@id=$ref]/@label" />
            </xsl:if>
            <xsl:if test="not( @ref ) or @label">
              <xsl:value-of select="@label" />
            </xsl:if>
          </td>
        </xsl:if>

        <!-- output element -->
        <td>
          <xsl:attribute name="columnIndex" select="$i - 1" />
          <xsl:attribute name="class" select="$colclass[ $i ]" />

          <xsl:if test="not(name() = 'lv:static')">
            <xsl:apply-templates select="." />
          </xsl:if>
          <xsl:if test="name() = 'lv:static'">
            <xsl:copy-of select="." />
          </xsl:if>
        </td>
      </xsl:for-each>
      <xsl:text disable-output-escaping="yes">&lt;/tr&gt;</xsl:text>
    </tbody>
  </table>

  <xsl:if test="not( $debug )">
    <div class="addrow">Add Row</div>
  </xsl:if>
</xsl:template>

</xsl:stylesheet>

