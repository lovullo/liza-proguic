<?xml version="1.0" encoding="ISO-8859-1"?>
<!--
  Package map generation

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
<stylesheet version="2.0"
  xmlns="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:lv="http://www.lovullo.com/rater"
  xmlns:lvm="http://www.lovullo.com/rater/map"
  xmlns:lvp="http://www.lovullo.com"
  xmlns:assert="http://www.lovullo.com/assert"
  xmlns:c="http://www.lovullo.com/calc"
  xmlns:t="http://www.lovullo.com/rater/apply-template">

<import href="expand.xsl" />


<output method="xml"
        indent="yes" />

<template match="lvp:program" as="element( lvm:program-map )"
          priority="5">
  <lvm:program-map src="program.expanded">
    <!-- intentional whitespace -->
    <comment>
      WARNING: Do NOT modify this file!
      It is auto-generated by progui-pkg-map.
    </comment>

    <lv:import package="../rater/core/base" />
    <lv:import package="package-dfns" />

    <variable name="questions" as="element( lvp:question )*"
              select="//lvp:question[ @id ]" />

    <apply-templates select="lvp:question-uniq( $questions )" />
  </lvm:program-map>
</template>


<function name="lvp:question-uniq" as="element( lvp:question )*">
  <param name="questions" as="element( lvp:question )*" />

  <!-- copy to permit sibling comparison -->
  <variable name="copy" as="document-node()">
    <document>
      <for-each select="$questions">
        <copy-of select="." />
      </for-each>
    </document>
  </variable>

  <sequence select="$copy/lvp:question[
                      not( @id =
                        preceding-sibling::lvp:question/@id ) ]" />
</function>


<!-- TODO: some place to indicate that things can be directly represented as
     numeric would be nice -->
<!-- TODO: should we support selects with numeric keys? -->
<template priority="5" match="lvp:question[
                                @type = 'number'
                                or @type = 'currency'
                                or @type = 'dollars'
                                or @type = 'float'
                                or @type = 'percent'
                                or @type = 'year'
                                or @type = 'zip' ]" >

  <variable name="default" select="if ( @default ) then @default else '0'" />

  <lvm:map to="ui_q_{@id}">
    <lvm:from name="{@id}">
      <lvm:translate key="" value="{$default}" />
    </lvm:from>
  </lvm:map>
</template>


<template priority="5" match="lvp:question[ @type = 'select' ]">
  <variable name="default-option" select="lvp:option[ @default='true' ]" />
  <variable name="default" select="if ( $default-option ) then
                                       $default-option
                                     else
                                       lvp:option[1]" />

  <lvm:map to="ui_q_{@id}">
    <lvm:from name="{@id}">
      <lvm:translate key="" value="{$default/@value}" />
    </lvm:from>
  </lvm:map>
</template>


<template match="lvp:question" priority="1">
  <lvm:map to="ui_q_{@id}">
    <lvm:from name="{@id}" default="1">
      <lvm:translate key=""  value="0" />
      <lvm:translate key="0" value="0" />
    </lvm:from>
  </lvm:map>
</template>

</stylesheet>

