<!--
  Serialization test helpers

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
            xmlns:struct="http://www.lovullo.com/liza/proguic/util/struct"
            xmlns:foo="http://www.lovullo.com/_junk">


<!-- SUT -->
<import href="../../src/util/serialize.xsl" />

<import href="serialize.xsl.apply" />


<function name="foo:recf" as="element()">
  <param name="element" as="element()" />

  <struct:item key="__rec">
    <sequence select="$element" />
  </struct:item>
</function>


</stylesheet>

