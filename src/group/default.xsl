<?xml version="1.0" encoding="ISO-8859-1"?>
<!--
  Default group (a simple list of questions)

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

<xsl:template match="/lv:program/lv:step/lv:group"
  name="group-default"
  mode="group-select"
  priority="1">

  <dl>
    <!-- misc. styles will just be applied as classes -->
    <xsl:if test="@style">
      <xsl:attribute name="class" select="@style" />
    </xsl:if>

    <xsl:apply-templates mode="generate"/>
  </dl>
</xsl:template>

</xsl:stylesheet>

