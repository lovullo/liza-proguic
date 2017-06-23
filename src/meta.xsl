<!--
  Handles generation of document metadata

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
            xmlns:lv="http://www.lovullo.com"
            xmlns:luic="http://www.lovullo.com/liza/program/compiler"
            xmlns:st="http://www.lovullo.com/liza/proguic/util/struct"
            xmlns:preproc="http://www.lovullo.com/program/preprocessor">


<import href="util/serialize.xsl" />

<include href="meta.xsl.apply" />

<!--
@node Metadata
@chapter Metadata
@cindex Metadata, Document

@devnotice{This system is rudimentary and subject to change.}

@dfn{Document metadata} is metadata stored outside of the bucket that
  describes certain aspects of the document.@footnote{
    Terminology note: ``document'' and ``quote'' are the same thing;
      the latter is transitioning to the former for generality.}
This should be used in place of a bucket field any time
  the client has no business knowing about the data.

Such metadata are defined within the @progxml
  (@pxref{Program XML,,@progxml{}}) with the @xmlnode{meta} node:

@float Figure, f:doc-meta-xml
@example
  <meta>
    <field id="bound" desc="Whether quote has been bound" />
  </meta>
@end example
@caption{Defining document metadata within the @progxml{}}
@end float

There is not currently any way to assign type information to the
  field.@footnote{
    There ought to be; there just isn't yet.}
These fields are not intended to be presented to the user as questions
  are@mdash{
    }internal systems are responsible for populating the data.
The field description @xmlattr{desc} is intended for both
  documentation and debugging/administrative utilities.


@section Metadata Compilation

Document metadata are only serialized for later use
  during the serialization phase (@pxref{Serialization Phase}):
-->


<!--
  Serialize document metadata.
-->
<template mode="luic:serialize" priority="5"
          match="lv:meta">
  <sequence select="st:dict-from-keyed-elements( 'id',
                                                 lv:field,
                                                 luic:field-meta() )" />
</template>


<!--
  When child nodes of @xmlnode{lv:field} are encountered,
    the function @code{luic:field-meta} will be applied to the
    field containing those childen:
-->


<!--
  Process nested field data.

  This function is applied within the context of a dictionary,
    so we need only return an item for it to be merged with the
    containing dictionary.
-->
<function name="luic:field-meta" as="element( st:item )">
  <param name="field" as="element( lv:field )" />

  <variable name="data" as="element( lv:data )?"
            select="$field/lv:data" />
  <variable name="maps" as="element( lv:map )*"
            select="$data/lv:map" />

  <!-- only generate map from value node if dapi ref exists -->
  <variable name="value-map" as="element( st:item )?"
            select="if ( $data ) then
                        st:item( $field/@id,
                                 $data/lv:value/@from )
                      else
                        ()" />

  <variable name="map-dict" as="element( st:dict )"
            select="st:dict(
                      ( $value-map,
                        st:items-from-keyed-elements(
                          'from', 'into', $maps ) ) )" />

  <sequence select="st:item(
                      st:dict(
                        ( st:item( $data/@source, 'name' ),
                          st:item( $map-dict, 'map' ) ) ),
                      'dapi' )" />
</function>

</stylesheet>
