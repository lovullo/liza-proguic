<?xml version="1.0" encoding="ISO-8859-1"?>
<!--
  Collapse table group

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

<xsl:template match="/lv:program/lv:step/lv:group[@style='collapsetable']"
  mode="group-select"
  priority="2">

  <xsl:variable name="self" select="." />

  <xsl:variable name="tableTitle" select="lv:prop[@name='tableTitle']" />
  <xsl:variable name="columns" select="lv:prop[@name='columns']" />
  <xsl:variable name="subcolumns" select="lv:prop[@name='subcolumns']" />
  <xsl:variable name="prefixes" select="lv:prop[@name='prefixes']" />
  <xsl:variable name="columnSuffix" select="lv:prop[@name='columnSuffix']" />
  <xsl:variable name="blockFlag" select="lv:prop[@name='blockFlag']" />
  <xsl:variable name="blockDisplay" select="lv:prop[@name='blockDisplay']" />
  <xsl:variable name="blockFlagSummary" select="lv:prop[@name='blockFlagSummary']" />
  <xsl:variable name="columnClasses" select="lv:prop[@name='columnClasses']" />
  <xsl:variable name="colclass" select="tokenize( $columnClasses, ',' )" />
  <xsl:variable name="use_footer" select="if ( lv:prop[@name='useFooter'] = 'true' ) then true() else false()" />

  <xsl:variable name="colcount">
    <xsl:if test="$debug or not( $subcolumns )">1</xsl:if>
    <xsl:if test="not( $debug ) and $subcolumns">
      <xsl:value-of select="count( tokenize( $subcolumns, ',' ) )" />
    </xsl:if>
  </xsl:variable>

  <table>
    <xsl:attribute name="class">
      <xsl:text>groupTable collapseTable</xsl:text>
      <xsl:if test="@locked">
        <xsl:text> locked</xsl:text>
      </xsl:if>
    </xsl:attribute>

    <thead>
      <tr class="groupTableHead">
        <th class="groupTableSide">
          <xsl:if test="$subcolumns">
            <xsl:attribute name="rowspan">2</xsl:attribute>
          </xsl:if>

          <xsl:value-of select="$tableTitle" />
        </th>
        <xsl:for-each select="tokenize( $columns, ',' )">
          <xsl:variable name="colpos" select="position()" />

          <th>
            <xsl:attribute name="columnIndex" select="$colpos - 1" />

            <xsl:if test="$subcolumns and not( $debug )">
              <xsl:attribute name="colspan">
                <xsl:value-of select="count( tokenize( $subcolumns, ',' ) )" />
              </xsl:attribute>
            </xsl:if>

            <xsl:attribute name="class" select="$colclass[ $colpos ]" />

            <!-- the actual text, wrapped in a div tag to make it easily
                 selectable and stylable with CSS -->
            <div>
              <xsl:value-of select="." />

              <!-- place header contents -->
              <xsl:for-each select="$self/lv:set[ @header='true' ]">
                <xsl:variable name="set" select="." />

                <div class="header-content">
                  <xsl:variable name="cols" select="tokenize( @each, ' ' )" />
                  <xsl:variable name="prefix" select="$cols[ $colpos ]" />

                  <xsl:apply-templates select="$set">
                    <!-- set the prefix on the element -->
                    <xsl:with-param name="prefix" select="$prefix" />
                  </xsl:apply-templates>
                </div>
              </xsl:for-each>
            </div>
          </th>
        </xsl:for-each>
      </tr>

      <xsl:if test="$subcolumns">
        <tr class="groupTableSubHead">
          <xsl:for-each select="tokenize( $columns, ',' )">
            <xsl:variable name="colpos" select="position()" />
            <!-- for debug (and XSLT 1.0 ) -->
            <xsl:if test="$debug">
              <th><xsl:value-of select="$subcolumns" /></th>
            </xsl:if>

            <!-- actually generate the subcolumns if not debug mode -->
            <xsl:if test="not( $debug )">
              <xsl:for-each select="tokenize( $subcolumns, ',' )">
                <th>
                    <xsl:attribute name="columnIndex" select="$colpos - 1" />
                    <xsl:attribute name="class" select="$colclass[ $colpos ]" />
                    <xsl:value-of select="." />
                </th>
              </xsl:for-each>
            </xsl:if>
          </xsl:for-each>
        </tr>
      </xsl:if>
    </thead>

    <tbody>
      <!-- will be parsed client-side -->
      <xsl:attribute name="blockFlags" select="$blockFlag" />
      <xsl:attribute name="blockFlagSummary" select="$blockFlagSummary" />

      <!-- process each set -->
      <xsl:for-each select="lv:set[ not( @header ) ]">
        <xsl:variable name="node" select="." />

        <!-- processed (non-debug, XSLT 2.0) output -->
        <xsl:if test="not( $debug )">
          <!-- output the side column as the first cell -->
          <xsl:if test="position() gt 1">
            <xsl:text disable-output-escaping="yes">&lt;/tr&gt;</xsl:text>
            <xsl:if test="not( $use_footer ) or ( position() lt last() )">
              <xsl:text disable-output-escaping="yes">&lt;tr class="</xsl:text>

              <xsl:if test="position() mod 2 != 1">
                <!-- alternate class for zebra striping -->
                <xsl:text disable-output-escaping="yes">alt </xsl:text>
              </xsl:if>

              <xsl:if test="$use_footer and ( position() = last() )">
                <!-- mark as footer -->
                <xsl:text disable-output-escaping="yes">footer </xsl:text>
              </xsl:if>

              <xsl:if test="$self/lv:set[ @class ]">
                <xsl:value-of select="@class" />
              </xsl:if>

              <xsl:text disable-output-escaping="yes">"&gt;</xsl:text>
            </xsl:if>

          </xsl:if>

          <!-- the first row (the parent row) will consume the first set -->
          <xsl:if test="position() = 1">
            <xsl:text disable-output-escaping="yes">&lt;tr class="unit"&gt;</xsl:text>
            <td class="groupTableSide">
              <xsl:value-of select="../@prefix" />
              <span class="rowindex"></span>

              <xsl:if test="$columnSuffix">
                <xsl:apply-templates select="$columnSuffix" />
              </xsl:if>
            </td>
          </xsl:if>

          <!-- side column -->
          <xsl:if test="position() gt 1">
            <td class="groupTableSide">
              <xsl:variable name="ref" select="*[1]/@ref" />
              <xsl:variable name="label" select="*[1]/@label" />
              <xsl:if test="$label">
                <xsl:value-of select="$label" />
              </xsl:if>
              <xsl:if test="not( $label ) and $ref">
                <xsl:value-of select="//lv:question[@id=$ref]/@label" />
              </xsl:if>
            </td>
          </xsl:if>
        </xsl:if>

        <xsl:for-each select="tokenize( @each, ' ' )">
          <xsl:variable name="i" select="position()" />
          <xsl:variable name="prefix" select="." />
          <xsl:variable name="matches"
            select="$node/lv:question | $node/lv:answer | $node/lv:display | $node/lv:static | $node/lv:question-copy" />
          <xsl:variable name="maxi" select="count( $matches )" />

          <xsl:for-each select="$matches">
            <xsl:variable name="subi" select="position()" />

            <!-- processed (non-debug, XSLT 2.0) output -->
            <xsl:if test="not( $debug )">
              <!-- output element -->
              <td>
                <!-- apply class to this element as well to permit proper
                     styling (e.g. text centering) -->
                <xsl:attribute name="class">
                  <xsl:if test="@type">
                    <xsl:value-of select="@type" />
                    <xsl:text> </xsl:text>
                  </xsl:if>
                  <xsl:if test="string-length( @class ) > 0">
                    <xsl:value-of select="@class" />
                  </xsl:if>

                  <!-- used for sectioning (CSS) -->
                  <xsl:if test="$subi = 1">
                    <xsl:text> columnLeft</xsl:text>
                  </xsl:if>
                  <xsl:if test="$subi = $maxi">
                    <xsl:text> columnRight</xsl:text>
                  </xsl:if>

                  <xsl:text> </xsl:text>
                  <xsl:value-of select="$colclass[ $i ]" />
                </xsl:attribute>

                <!-- output the column it is a part of for quick reference
                     (convert to 0-index) -->
                <xsl:attribute name="columnIndex" select="$i - 1" />
                <xsl:attribute name="subColumnIndex" select="$subi - 1" />

                <xsl:apply-templates select=".">
                  <!-- set the prefix on the element -->
                  <xsl:with-param name="prefix" select="$prefix" />
                </xsl:apply-templates>
              </td>
            </xsl:if>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:for-each>
      <xsl:text disable-output-escaping="yes">&lt;/tr&gt;</xsl:text>
    </tbody>
  </table>

  <!-- Block display divs host the content that will be rendered in
       block display mode for each respective column.  The fallback to
       blockFlag is for backwards-compatibility. -->
  <xsl:sequence select="lv:gen-block-display(
                          if ( $blockDisplay ) then
                            $blockDisplay
                          else
                            $blockFlag )" />

  <xsl:if test="not( $debug )">
    <div class="addrow">Add Row</div>
  </xsl:if>
</xsl:template>


<!--
  Render block display.

  The new display format supports anything that a static element
  does.  To maintain backwards-compatibility, we guess whether the old
  style is being used by determining if there is only a single
  property with no child elements.
-->
<xsl:function name="lv:gen-block-display">
  <xsl:param name="block-display" as="element()*" />

  <xsl:choose>
    <xsl:when test="count( $block-display ) = 1
                    and not( $block-display/element() )">
      <xsl:sequence select="lv:gen-block-display-old( $block-display )" />
    </xsl:when>

    <xsl:otherwise>
      <xsl:for-each select="$block-display">
        <div id="block_display_{generate-id(.)}"
             class="block-display">
          <xsl:apply-templates mode="generate-static"
                               select="." />
        </div>
      </xsl:for-each>
    </xsl:otherwise>
  </xsl:choose>
</xsl:function>


<!--
  Backwards-compatibility with legacy blockDisplay property.

  The old format contained a comma-delimited (no whitespace) list of
  refs to display as the block value for each respective column.  We
  simply convert it into a property with a single display element and
  pass it back off for rendering.
-->
<xsl:function name="lv:gen-block-display-old">
  <xsl:param name="block-display" as="element()" />

  <xsl:for-each select="tokenize( $block-display, ',' )">
    <xsl:variable name="gen-block" as="element( lv:prop )">
      <lv:prop name="blockDisplay">
        <lv:display ref="{.}" allow-html="true" />
      </lv:prop>
    </xsl:variable>

    <xsl:sequence select="lv:gen-block-display( $gen-block )" />
  </xsl:for-each>
</xsl:function>

</xsl:stylesheet>

