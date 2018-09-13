<?xml version="1.0" encoding="ISO-8859-1"?>
<!--
  Builds the program

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

  This stylesheet is responsible for generating all the templates, classes,
  etc for the given program. It will use transformations from other
  stylesheets, but will process them in a way suitable for a production
  environment.

  AN XSLT 2.0 PARSER IS REQUIRED TO PROCESS THIS STYLESHEET!
-->
<xsl:stylesheet version="2.0"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:lv="http://www.lovullo.com"

  xmlns:exsl="http://exslt.org/common"
  extension-element-prefixes="exsl">

<xsl:output
  method="xml"
  indent="yes"
  omit-xml-declaration="yes"
  />

<!--
  Main program stylesheet

  This stylesheet does the actual transformations. It is also used to generate
  the default HTML displayed when visiting the XML file directly in the
  browser.
-->
<xsl:include href="program.xsl" />

<!-- output directory -->
<xsl:param name="out-path" />

<!--
  Root template that kicks off the build process

  This template has a high priority in order to ensure it overrides any default
  behavior present in any included templates.
-->
<xsl:template match="/lv:program" priority="10">
  <xsl:apply-templates select="." mode="build" />
</xsl:template>


<xsl:template match="/lv:program" mode="build">
  <!-- require XSLT 2.0 parser -->
  <xsl:if test="number(system-property('xsl:version')) &lt; 2.0">
    <xsl:message terminate="yes">XSLT 2.0 processor required</xsl:message>
  </xsl:if>
  <xsl:message>Generating PHP templates...</xsl:message>
  <xsl:message></xsl:message>

  <!-- generate each of the steps -->
  <xsl:apply-templates select="lv:step" mode="build" />

  <!-- generate index page -->
  <xsl:result-document href="{$out-path}/index.phtml">
    <!-- step navigation -->
    <xsl:call-template name="navigation"/>

    <form id="rater-step">
      <noscript>
        <p>
          <strong>
            JavaScript is required by this rater, but is currently disabled.
            Please enable it in your browser settings to continue.
          </strong>
        </p>
      </noscript>
    </form>
  </xsl:result-document>
</xsl:template>


<!--
  Generates separate template file for a given step

  This template will simply take the output of the transformation and place it
  in its own file. The result is a separate PHP template file for each step.
-->
<xsl:template match="/lv:program/lv:step" mode="build">
  <xsl:result-document href="{$out-path}/steps/{position()}.phtml">
    <!-- defer processing to other templates for this step -->
    <xsl:apply-templates select="." />
  </xsl:result-document>
</xsl:template>

</xsl:stylesheet>

