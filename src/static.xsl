<?xml version="1.0" encoding="ISO-8859-1"?>
<!--
  Single-page template used when XSL version doesn't support result-document,
  which is added in version 2.0

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

  TODO: use system-property('xsl:vendor') to show one page in browsers, unless the
  browser will properly recognize multiple pages

  better TODO: this is no longer used, so get rid of it
-->
<xsl:stylesheet version="2.0"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:lv="http://www.lovullo.com">

<xsl:template match="/lv:program"
  use-when="number(system-property('xsl:version')) = 1.0"
  priority="2">

  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>Program Design: <xsl:value-of select="@title"/></title>
      <script src="../../../src/www/scripts/dojo/dojo.js" type="text/javascript"></script>

      <script type="text/javascript">
          dojo.require( '/djConfig' );
          djConfig.baseUrl = '../../../src/www/scripts/';
          dojo.require( 'dijit.form.CurrencyTextBox' );
      </script>
    </head>
    <body>
      <h1><xsl:value-of select="@title"/></h1>
      <xsl:if test="@description">
        <p class="program-desc">
          <xsl:value-of select="@description"/>
        </p>
      </xsl:if>

      <!-- step navigation -->
      <xsl:call-template name="navigation"/>

      <blockquote id="devnote">
        You are currently viewing the XSL 1.0 HTML representation of the
        <xsl:value-of select="@title"/> XML document, which is generated to aid
        in development. This is <em>not</em> what the production HTML will look
        like. To see that, please apply the XSL transformation using an XSL 2.0
        compatiable parser. This will be automatically done during the build
        processes.
      </blockquote>

      <xsl:apply-templates select="lv:step" mode="static"/>
    </body>
  </html>
</xsl:template>


<!--
  static step

  Outputs step in a separate div with an anchor and a title. This is intended to
  be output in a single page with the rest of the steps.
-->
<xsl:template match="lv:step" mode="static">
  <xsl:variable name="anchor" select="translate( @title, ' ', '_' )"/>

  <xsl:message>Generating static step for <xsl:value-of select="$anchor"/>...</xsl:message>

  <div>
    <xsl:attribute name="id">step_<xsl:value-of select="$anchor"/></xsl:attribute>
    <xsl:attribute name="class">step-content</xsl:attribute>

    <!-- anchor / heading (may want to hide with navigation properly displayed
         and when we have jQuery magic -->
    <a>
      <xsl:attribute name="name"><xsl:value-of select="$anchor"/></xsl:attribute>
      <h2><xsl:value-of select="@title"/></h2>
    </a>

    <xsl:apply-templates select="lv:group"/>

    <p class="top"><a href="#">Top</a></p>
  </div>
</xsl:template>

</xsl:stylesheet>

