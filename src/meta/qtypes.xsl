<?xml version="1.0"?>
<!--
  Builds JSON-formatted question type metadata

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
            xmlns:qtype="http://www.lovullo.com/program/ui/meta/qtypes"
            xmlns:lv="http://www.lovullo.com">


<template mode="qtype:parse-element" priority="5" as="xs:string*"
          match="lv:question
                 |lv:question/lv:option
                 |lv:display
                 |lv:external">
  <if test="position() > 1">
    <text>,</text>
  </if>

  <!-- ids may be generated for elements that use @ref, so have @ref
       take precedence -->
  <variable name="id"
            select="if ( @ref ) then @ref else @id" />
  <variable name="type"
            select="qtype:parse-type( @type )" />
  <variable name="dim"
            select="if ( @dim ) then @dim else 1" />


  <choose>
    <when test="ancestor::lv:set">
      <variable name="id"
                select="if ( @ref ) then @ref else @id" />

      <sequence select="qtype:process-set(
                          $id,
                          $type,
                          $dim,
                          ancestor::lv:set )" />
    </when>

    <otherwise>
      <sequence select="qtype:gen-type( $id, $type, $dim )" />
    </otherwise>
  </choose>
</template>


<template mode="qtype:parse-element" priority="4" as="xs:string*"
          match="lv:set">
  <apply-templates mode="qtype:parse-element" />
</template>


<template mode="qtype:parse-element" priority="1" as="xs:string?"
          match="node()">
  <!-- nothing -->
</template>


<!--
  Determine type from the given string @var{type}.  Currently, the
  expression is either the provided string or @t{'undefined'}.
-->
<function name="qtype:parse-type" as="xs:string">
  <param name="type" as="xs:string?" />

  <sequence select="if ( exists( $type )
                         and not( $type = '' ) ) then
                      $type
                    else
                      'undefined'" />
</function>


<!--
  Compile type information for sets.  @t{$set/@each} should be a
  space-delimited string of prefixes for the containing elements; one
  element per prefix will be generated.
-->
<function name="qtype:process-set" as="xs:string*">
  <param name="id"   as="xs:string" />
  <param name="type" as="xs:string" />
  <param name="dim"  as="xs:integer" />
  <param name="set"  as="element( lv:set )" />

  <for-each select="tokenize( $set/@each, ' ' )">
    <if test="position() > 1">
      <text>,</text>
    </if>

    <sequence select="qtype:gen-type(
                        concat( ., '_', $id ),
                        $type,
                        $dim )" />
  </for-each>
</function>


<!--
  Generate key-value JSON pair for a one-dimensional identifier.

  The output is expected to be used as part of an object literal.
-->
<function name="qtype:gen-type" as="xs:string">
  <param name="id"   as="xs:string" />
  <param name="type" as="xs:string" />

  <sequence select="qtype:gen-type( $id, $type, 1 )" />
</function>


<!--
  Generate key-value JSON pair for an identifier.

  The output is expected to be used as part of an object literal.
-->
<function name="qtype:gen-type" as="xs:string">
  <param name="id"   as="xs:string" />
  <param name="type" as="xs:string" />
  <param name="dim"  as="xs:integer" />

  <sequence select="concat(
                      '''',
                      $id,
                      ''':{',
                      'type:''', $type,
                      ''',',
                      'dim:', $dim,
                      '}' )" />
</function>

</stylesheet>

