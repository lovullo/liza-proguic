<?xml version="1.0" encoding="utf-8"?>
<!--
  Expand nodes during preprocessing

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
  xmlns:lvp="http://www.lovullo.com"
  xmlns:preproc="http://www.lovullo.com/program/preprocessor"
  xmlns:assert="http://www.lovullo.com/assert"
  xmlns:c="http://www.lovullo.com/calc"
  xmlns:t="http://www.lovullo.com/rater/apply-template">

<import href="program-preprocess.xsl" />

<function name="lvp:expand" as="document-node( element( lvp:program ) )">
  <param name="program" as="element( lvp:program )" />

  <variable name="preproc"
            as="document-node( element( lvp:program ) )">
    <apply-templates select="$program" mode="preprocess" />
  </variable>

  <document>
    <apply-templates mode="lvp:expand"
                     select="$preproc/lvp:program" />
  </document>
</function>


<!--
  Unknown nodes are echoed and processing continues with their
  children; this allows the system to evolve independently from this
  expansion system.
-->
<template mode="lvp:expand"
          match="node()"
          priority="1">
  <copy>
    <sequence select="@*" />
    <apply-templates mode="lvp:expand" />
  </copy>
</template>


<!--
  Text and comments are output verbatim.
-->
<template mode="lvp:expand"
          match="text()|comment()"
          priority="2">
  <copy>
    <copy-of select="@*" />
    <apply-templates mode="lvp:expand" />
  </copy>
</template>


<!--
@node Whens
@section Whens

  ``Whens'' are predicates attached to elements; they state, simply,
  the condition under which the element should be visible.

  They are provided as a space-delimited attribute, which is
  inconvenient to query and work with; we expand them here into nodes.
-->


<!--
  Expand ``when'' predicates into nodes.  The original @code{@@when}
  attribute is retained.

  Predicates are parsed expanded into @code{predicate} nodes
  referencing the the respective identifier.
-->
<template mode="lvp:expand"
          match="element()[ @when ]"
          priority="5">
  <copy>
    <sequence select="@*,
                      lvp:expand-preds(
                        lvp:parse-when( @when ),
                        current() )" />

    <apply-templates mode="lvp:expand" />
  </copy>
</template>


<!--
  Parses the space-delimited ``when'' string @var{when} into a
  sequence of ref strings.
-->
<function name="lvp:parse-when" as="xs:string*">
  <param name="when" as="xs:string" />

  <for-each select="tokenize( $when, ' ' )">
    <sequence select="." />
  </for-each>
</function>


<!--
  Some refs have special meanings in the form of @code{<type>:<ref>};
  otherwise, @code{type} is assumed to be `@code{c}', which references
  a classification.
-->
<function name="lvp:pred-parse" as="xs:string+">
  <param name="pred" as="xs:string" />

  <variable name="is-special" as="xs:boolean"
            select="substring-after( $pred, ':' ) != ''" />

  <sequence select="if ( $is-special ) then
                      ( substring-before( $pred, ':' ),
                        substring-after( $pred, ':' ) )
                    else
                      ( 'c',
                        $pred )" />
</function>


<!--
  Recursively expands predicates into @code{lvp:predicate} nodes.
-->
<function name="lvp:expand-preds" as="element( lvp:predicate )*">
  <param name="seq"     as="xs:string*" />
  <param name="context" as="element()" />

  <if test="exists( $seq )">
    <variable name="cur-pred" as="xs:string"
              select="$seq[ 1 ]" />
    <variable name="parts" as="xs:string+"
              select="lvp:pred-parse( $cur-pred )" />

    <variable name="type" as="xs:string"
              select="$parts[ 1 ]" />
    <variable name="ref" as="xs:string"
              select="$parts[ 2 ]" />

    <lvp:predicate type="{$type}"
                   ref="{$ref}"
                   name="{$cur-pred}" />

    <sequence select="lvp:expand-preds(
                        subsequence( $seq, 2 ),
                        $context )" />
  </if>
</function>

</stylesheet>

