<?xml version="1.0"?>
<!--
  Builds JSON-formatted program metadata

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
            xmlns:luic="http://www.lovullo.com/liza/program/compiler"
            xmlns:struct="http://www.lovullo.com/liza/proguic/util/struct"
            xmlns:qtype="http://www.lovullo.com/program/ui/meta/qtypes"
            xmlns:lv="http://www.lovullo.com">


<output method="text"
        indent="yes"
        omit-xml-declaration="yes"
        />

<include href="meta/qtypes.xsl" />
<include href="meta.xsl" />


<template name="build-meta">
  <text>{qtypes:{</text>
  <!-- XXX: qtype:parse-element doesn't accept lv:answer; research! -->
  <apply-templates mode="qtype:parse-element"
                   select="//lv:question,
                           //lv:question/lv:option[ @id ],
                           //lv:answer,
                           //lv:display[ @type ],
                           //lv:external,
                           //lv:calc[ @store = 'true' ]" />

  <text>},qdata:{</text>
  <apply-templates select="//lv:question[@type='select']" mode="meta-qdata" />

  <text>},arefs:{</text>
  <apply-templates select="//lv:answer|//lv:display" mode="meta-aref" />

  <text>},groups:{</text>
  <apply-templates select="//lv:group[@style]" mode="meta" />

  <text>},fields:</text>
    <!-- TODO: this is glue code; move it to a proper place -->
    <sequence select="luic:serialize-meta( /lv:program/lv:meta )" />
  <text>}</text>
</template>


<template match="//lv:question" mode="meta-qdata">
  <if test="position() > 1">
    <text>,</text>
  </if>

  <text></text>
  <value-of select="@id" />
  <text>:{</text>

  <!-- add each of the options -->
  <for-each select="lv:option">
    <if test="position() > 1">
      <text>,</text>
    </if>

    <text>'</text>
    <value-of select="replace( @value, &quot;'&quot;, &quot;\\'&quot; )" />
    <text>':'</text>
    <value-of select="normalize-space( . )" />
    <text>'</text>
  </for-each>

  <text>}</text>
</template>


<template match="lv:answer|lv:display" mode="meta-aref">
  <if test="position() > 1">
    <text>,</text>
  </if>

  <text>'</text>
    <value-of select="@id" />
  <text>':'</text>
    <value-of select="@ref" />
  <text>'</text>
</template>


<template match="//lv:group" mode="meta">
  <if test="position() > 1">
    <text>,</text>
  </if>

  <text>"</text>
  <value-of select="@id" />
  <text>":{max:</text>
  <value-of select="if ( @maxRows ) then number( @maxRows ) else '0'" />
  <text>,min:</text>
  <value-of select="if ( @minRows ) then number( @minRows ) else '0'" />
  <text>}</text>
</template>


<!-- TODO: this is glue code; move it to a proper place -->
<function name="luic:serialize-meta" as="xs:string">
  <param name="element" as="element( lv:meta )?" />

  <variable name="result" as="element( struct:dict )?">
    <apply-templates select="$element" mode="luic:serialize" />
  </variable>

  <sequence select="struct:to-json(
                      if ( empty( $result ) ) then
                          struct:dict( () )
                        else
                          $result )" />
</function>


<template mode="luic:serialize" priority="1"
          match="node()">
  <!-- ignore -->
</template>

</stylesheet>

