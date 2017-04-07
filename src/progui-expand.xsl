<?xml version="1.0" encoding="ISO-8859-1"?>
<!--
  Preproces source program XML

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
<stylesheet version="2.0"
  xmlns="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:lv="http://www.lovullo.com/rater"
  xmlns:lvp="http://www.lovullo.com"
  xmlns:assert="http://www.lovullo.com/assert"
  xmlns:c="http://www.lovullo.com/calc"
  xmlns:t="http://www.lovullo.com/rater/apply-template">

<import href="expand.xsl" />


<output method="xml"
        indent="yes" />

<!--
  A package will be generated representing a respective UI
  definition.  The purpose of this package is to provide tight
  integration with the rest of the system, taking advantage of its
  functionality and built-in error checking.
-->
<template match="lvp:program"
          as="element( lvp:program )"
          priority="5">
  <copy>
    <sequence select="@*" />

    <!-- intentional whitespace -->
    <comment>
      WARNING: Do NOT modify this file!
      It is auto-generated by progui-expand.
    </comment>

    <!-- this variable exists purely for type/sanity checking -->
    <variable name="expanded" as="element( lvp:program )"
              select="lvp:expand( . )/lvp:program" />

    <sequence select="$expanded/node()" />
  </copy>
</template>

</stylesheet>

