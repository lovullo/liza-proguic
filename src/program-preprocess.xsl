<?xml version="1.0"?>
<!--
  The program XML preprocessor

  Copyright (C) 2017, 2018, 2019 R-T Specialty, LLC.

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

  TODO: Merge with expand.xsl
-->
<stylesheet version="2.0"
            xmlns="http://www.w3.org/1999/XSL/Transform"
            xmlns:lv="http://www.lovullo.com"
            xmlns:assert="http://www.lovullo.com/assert"
            xmlns:preproc="http://www.lovullo.com/program/preprocessor">

<!-- original root before processing -->
<variable name="orig-root" select="." />


<template match="lv:program[ not( @version ) ]" mode="preprocess">
  <!-- TODO: pass into stylesheet as a param -->
  <variable name="path" select="'../.version.xml'" />
  <variable name="version" select="document( $path, /lv:program )/*" />

  <variable name="root">
    <copy>
      <copy-of select="@*" />

      <!-- add version attribute -->
      <attribute name="version" select="$version" />

      <!-- start by processing the fragment includes so that the rest of the
           system can continue working as if it were one giant file , as it
           was originally designed -->
      <apply-templates select="node()" mode="preproc:include">
        <with-param name="rel-root" select="$orig-root" />
      </apply-templates>
    </copy>
  </variable>

  <document>
    <apply-templates select="$root" mode="preprocess" />
  </document>
</template>


<!--
  Recursively replace fragment includes with all child nodes of the fragment.

  This is an include in a similar sense to a C preprocessor macro: the
  contents of the file are placed in place of the include.
-->
<template match="lv:include[ @fragment ]" mode="preproc:include" priority="5">
  <param name="rel-root" select="$orig-root" />

  <variable name="doc" as="element( lv:program-fragment )"
            select="document( concat( @fragment, '.xml' ), $rel-root )/lv:program-fragment" />

  <!-- replace the include node with the children of the fragment, preprocessed -->
  <apply-templates select="$doc/node()" mode="preproc:include">
    <with-param name="rel-root" select="$doc" />
  </apply-templates>
</template>

<template match="element()" mode="preproc:include" priority="1">
  <copy>
    <sequence select="@*" />
    <apply-templates mode="preproc:include" />
  </copy>
</template>

<template match="text()|comment()" mode="preproc:include" priority="1">
  <sequence select="." />
</template>


<!--
  Triggers preprocessing (this is the preprocessor entry point)

  If multiple passes are needed, then they should be added here.
-->
<template match="*" mode="preprocess">
  <!-- currently, we only perform expansions (derivate additional content from
       the existing content) -->
  <variable name="result">
    <apply-templates select="." mode="preproc:expand" />
  </variable>

  <variable name="errors" as="element( preproc:error )*"
            select="$result//preproc:error" />

  <!-- recurse if another pass has been scheduled -->
  <choose>
    <when test="$errors">
      <apply-templates select="$errors" mode="preproc:error" />
      <message terminate="yes"
               select="concat( 'fatal: ', count( $errors ), ' error(s)' )" />
    </when>

    <when test="$result//preproc:repass">
      <apply-templates select="$result" mode="preprocess" />
    </when>

    <otherwise>
      <!-- no re-pass scheduled; return -->
      <copy-of select="$result" />
    </otherwise>
  </choose>
</template>


<!--
  Render errors to stdout
-->
<template mode="preproc:error" priority="1"
          match="preproc:error">
  <message select="concat( 'error: ', text() )" />
</template>


<!-- default expansion; do nothing -->
<template match="*" mode="preproc:expand" priority="1">
  <copy>
    <copy-of select="@*" />

    <apply-templates mode="preproc:expand" />
  </copy>
</template>


<template match="preproc:repass" mode="preproc:expand" priority="5">
  <!-- remove to prevent infinite recursion -->
</template>


<!--
  Copies the given node and appends the given content

  This performs no additional processing on the child nodes; the caller is
  responsible for determining what should be done next.
-->
<template match="*" mode="preproc:inject">
  <param name="content" />

  <copy>
    <!-- copy all existing attributes and nodes in addition to the given
         content -->
    <copy-of select="@*|*|$content" />
  </copy>
</template>


<!--
  Injects content into either the given node or, if the given node does not
  exist, the provided new node

  This simply abstracts "use if exists, otherwise use this", which is otherwise
  very verbose.
-->
<template name="preproc:injectornew">
  <param name="node" />
  <param name="new" />
  <param name="content" />

  <!-- determine the node we will inject into (an existing one, if available,
       otherwise a new node -->
  <variable name="inject-into">
    <choose>
      <!-- if node exists, inject the content into it -->
      <when test="$node">
        <copy-of select="$node" />
      </when>

      <!-- otherwise, create the node anew and inject the content -->
      <otherwise>
        <copy-of select="$new" />
      </otherwise>
    </choose>
  </variable>

  <!-- perform the injection! -->
  <apply-templates select="$inject-into" mode="preproc:inject">
    <with-param name="content">
      <copy-of select="$content" />
    </with-param>
  </apply-templates>
</template>


<!--
  Generate ids for groups that do not have one

  We'll do our best to generate a sane id from the title.

  Group ids are necessary for many operations, but the ids are primarily used
  internally; we shouldn't require that the developer provide one unless he/she
  actually needs to reference the group by its id.
-->
<template match="lv:group[ not( @id ) ]" mode="preproc:expand" priority="5">
  <variable name="title"
                select="if ( @title and not( @title = '' ) ) then
                          @title
                        else
                          generate-id( . )" />

  <copy>
    <!-- copy existing attributes -->
    <copy-of select="@*" />

    <!-- create an id from the title by removing spaces and other permitted
         chars (it is expected that @title is restricted such that we can do
         this without a problem) -->
    <attribute name="id">
      <value-of select="translate( $title, ' ().-*:', '' )" />
    </attribute>

    <apply-templates mode="preproc:expand" />
  </copy>

  <preproc:repass />
</template>


<!--
  Generate ids for statics that do not have one
-->
<template mode="preproc:expand" priority="5"
              match="lv:static[ not( @id ) ]">
  <copy>
    <copy-of select="@*" />
    <attribute name="id" select="generate-id( . )" />

    <apply-templates mode="preproc:expand" />
  </copy>

  <preproc:repass />
</template>


<!--
  Determine group dimensions (either a scalar or a vector) based on
  the group style
-->
<template mode="preproc:expand" priority="4"
              match="lv:group[ not( @dim ) ]">
  <copy>
    <copy-of select="@*" />

    <!-- TODO: store dimensions somewhere; this is a maintenance issue -->
    <attribute name="dim">
      <value-of
          select="if ( not( @style )
                       or @style = 'flat'
                       or @style = 'wide' ) then
                    '0'
                  else
                    '1'" />
    </attribute>

    <apply-templates mode="preproc:expand" />
  </copy>

  <preproc:repass />
</template>


<!--
  Predicate require ids on the elemnts that they are operating on;
  generate option ids if a predicate is present.
-->
<template mode="preproc:expand" priority="5"
              match="lv:option[ @when and not( @id ) ]">
  <copy>
    <copy-of select="@*" />

    <attribute name="id">
      <value-of select="concat( '__',
                                    parent::lv:question/@id,
                                    '_opt_',
                                    generate-id(.) )" />
    </attribute>

    <apply-templates mode="preproc:expand" />
  </copy>

  <preproc:repass />
</template>


<!--
  Inherit dimension from parent group

  This will be populated on a repass once the group/@dim becomes
  available
-->
<template mode="preproc:expand" priority="5"
              match="lv:question[
                       not( @dim )
                       and exists( ancestor::lv:group/@dim ) ]">
  <copy>
    <copy-of select="@*" />

    <attribute name="dim">
      <value-of select="ancestor::lv:group/@dim" />
    </attribute>

    <apply-templates mode="preproc:expand" />
  </copy>

  <preproc:repass />
</template>


<!--
  Generate id for options containing predicates

  Any option that contains a predicate must have an identifier that
  the UI framework can use to operate on it.  The only situation in
  which this is currently applicable is when the option contains a
  predicate.
-->
<template mode="preproc:expand" priority="9"
              match="lv:question/lv:option[ @when
                                            and not( @id ) ]">
  <copy>
    <sequence select="@*" />

    <attribute name="id"
                   select="concat( parent::lv:question/@id,
                                   '__opt__',
                                   generate-id( . ) )" />

    <sequence select="node()" />
  </copy>

  <preproc:repass />
</template>


<!--
  Copy @when from referenced question, unless overridden
-->
<template match="lv:answer[ not( @when ) and @ref=//lv:question[ @when ]/@id ]" mode="preproc:expand" priority="3">
  <copy>
    <copy-of select="@*" />

    <!-- copy @when from referenced question -->
    <variable name="ref" select="@ref" />
    <copy-of select="//lv:question[ @id=$ref ]/@when" />

    <apply-templates mode="preproc:expand" />
  </copy>

  <preproc:repass />
</template>


<template match="lv:answer[ not(@id) ]|lv:display[ not(@id) ]" mode="preproc:expand" priority="7">
  <copy>
    <!-- copy existing attributes -->
    <copy-of select="@*" />

    <!-- create an id from the ref by removing spaces and other permitted
         chars (making it easier to identify), followed by a unique id (to
         ensure that we do not have duplicate ids) -->
    <attribute name="id">
      <value-of select="concat(translate( @ref, ' ().-', '' ), '_', generate-id(.))" />
    </attribute>

    <!-- recurse -->
    <apply-templates mode="preproc:expand" />
  </copy>

  <preproc:repass />
</template>


<!--
  Expand assertion show/hide group triggers

  This trigger will expand into two separate triggers: show and hide. They will
  be added as separate success/failure nodes, even if existing nodes are
  present; the reason for this is that merging can become complicated when the
  nodes contain their own attributes.

  This will trigger another pass of the preprocessor (which is a much simpler
  implementation than the alternative) since content will have been added.
-->
<template match="
    assert:*/lv:trigger[
      @group='showhide'
      or @group='hideshow'
    ]
  "
  mode="preproc:expand" priority="5">

  <!-- How convenient that each event is four characters in length! The first
       four characters will be taken as the success event and the last four as
       the failure (note that XPath expressions are 1-indexed). -->
  <variable name="event-success"
    select="substring( @group, 1, 4 )" />
  <variable name="event-failure"
    select="substring( @group, 5 )" />

  <!-- even though the XSD does not allow multiple success/failure nodes, this
       is the easiest implementation; the compiler will have no trouble with
       this -->
  <assert:success>
    <lv:trigger event="{$event-success}" ref="{@ref}" />
  </assert:success>
  <assert:failure>
    <lv:trigger event="{$event-failure}" ref="{@ref}" />
  </assert:failure>

  <!-- we inserted content, so schedule another pass -->
  <preproc:repass />
</template>


<!--
  CSR consists of three separate fields:
    - id
    - name
    - e-mail

  This implementation is based on the custom Csr fields and class created by
  Shelly for snowmobile. It is designed to be functionally identical.

  This overrides the default question generation template, which will then call
  the default template for new question nodes (instead of the csr one provided).
  This can be thought of like a macro.
-->
<template match="lv:question[@type='csr']" mode="preproc:expand" priority="5">
  <param name="id" select="@id" />

  <lv:question type="select" id="agency_contact_id" required="true" class="csr">
    <attribute name="id" select="string-join( ($id, '_id'), '')" />
    <attribute name="label" select="string-join( (@label, 'Name'), ' ')" />
  </lv:question>

  <lv:question type="text" id="agency_contact_name" required="true" hidden="true">
    <attribute name="id" select="string-join( ($id, '_name'), '')" />
    <attribute name="label" select="string-join( (@label, 'Name'), ' ')" />
  </lv:question>

  <lv:question type="email" id="agency_contact_email" readonly="true" required="true">
    <attribute name="id" select="string-join( ($id, '_email'), '')" />
    <attribute name="label" select="string-join( (@label, 'E-mail'), ' ')" />
  </lv:question>

  <lv:question type="phone" id="agency_contact_phone">
    <attribute name="id" select="string-join( ($id, '_phone'), '')" />
    <attribute name="label" select="string-join( (@label, 'Phone'), ' ')" />
  </lv:question>
</template>


<!--
  This set of templates will perform the following for each lv:question that
  uses the data API to set its label:
    - Generate a *_label ref to store the label
    - Add an lv:map to the lv:data element to populate the label
    - Rewrite the refs of any lv:answer that references the lv:question so that
      it points to the label ref

  This solves the problem of lv:answers displaying unfriendly data if a step is
  loaded before the data API call is made on a previous step.
-->
<template match="lv:question[ lv:data/lv:label and not( @preproc:labeled ) ]"
  mode="preproc:expand" priority="5">

  <!-- copy the question node, preprocessing the lv:data node -->
  <copy>
    <copy-of select="@*" />
    <attribute name="preproc:labeled" select="'true'" />

    <apply-templates mode="preproc:expand" />
  </copy>

  <!-- add our label ref to store the data (this will always be a text type) -->
  <lv:external id="{@id}_label" type="text" />
</template>


<!--
  Error when attempting to use an undefined dapi
-->
<template mode="preproc:expand" priority="7"
          match="lv:question/lv:data[
                   not( @source = ancestor::lv:program/lv:api/@id ) ]">
  <preproc:error>
    <text>Reference to unknown dapi `</text>
      <value-of select="@source" />
    <text>' by question `</text>
      <value-of select="parent::lv:question/@id" />
    <text>'</text>
  </preproc:error>
</template>


<template mode="preproc:expand" priority="5"
          match="lv:question/lv:data[
                   lv:label
                   and not( lv:map[ @preproc:map-label ] ) ]">
  <copy>
    <copy-of select="@*|*" />

    <!-- add a map to our label ref to be populated with the rest of our data -->
    <lv:map param="{lv:label/@from}" into="{parent::lv:question/@id}_label" preproc:map-label="true" />
  </copy>
</template>


<!--
  Answers inherit types of their parent and cannot be overridden

  If an override is needed (not advisable!), display should be used instead.
-->
<template mode="preproc:expand" priority="8"
          match="lv:answer[ @type ]">
  <preproc:error>
    <text>lv:answer/@type is not supported for `</text>
    <value-of select="@ref" />
    <text>'; use lv:display if type overrides are needed</text>
  </preproc:error>
</template>


<!--
  Answers must reference questions

  Displaying arbitrary bucket values requires the use of lv:display.
-->
<template mode="preproc:expand" priority="9"
          match="lv:answer[ not( @ref = //lv:question/@id ) ]">
  <preproc:error>
    <text>lv:answer reference `</text>
    <value-of select="@ref" />
    <text>' is not a question</text>
  </preproc:error>
</template>


<template match="lv:answer[ @ref=//lv:question[ lv:data/lv:label ]/@id ]" mode="preproc:expand" priority="5">
  <!-- convert into an lv:display, since we won't be referencing an lv:question anymore -->
  <lv:display>
    <!-- copy over any of the lv:answer attributes -->
    <copy-of select="@*" />

    <!-- override ref to use our generated label ref -->
    <attribute name="ref" select="concat( @ref, '_label' )" />

    <!-- explicitly add the type -->
    <attribute name="text" select="'text'" />

    <!-- we'll need to add the label of the question as well to ensure proper display -->
    <variable name="ref" select="@ref" />
    <attribute name="label" select="//lv:question[ @id=$ref ]/@label" />
  </lv:display>
</template>


<!-- add lv:external nodes for every permitRef ref to ensure that they are
     initialized with proper defaults -->
<template match="lv:group/lv:set[ @permitRef='true' ]"
              mode="preproc:expand"
              priority="2">
  <sequence select="." />

  <for-each select="lv:*[ @ref ]">
    <lv:external type="{@type}" id="{@ref}">
      <if test="@dim">
        <attribute name="dim" select="@dim" />
      </if>
    </lv:external>
  </for-each>
</template>


<!--
  If both @group and @event were provided, then the developer has done something
  wrong

  Note that this has a higher priority than the other templates
-->
<template match="lv:trigger[ @group and @event ]" mode="preproc:expand" priority="9">
  <preproc:error>
    <text>Trigger cannot have both @group and @event</text>
  </preproc:error>
</template>


<!--
  Catch invalid group triggers

  Currently, we only support group triggers within assertions.
-->
<template match="lv:trigger[ @group ]" mode="preproc:expand" priority="4">
  <preproc:error>
    <text>Misplaced or unknown group trigger: </text>
    <value-of select="@group" />
  </preproc:error>
</template>


<template match="lv:group-set" mode="preproc:expand" priority="5">
  <variable name="self" select="." />

  <!-- will be used as the prefix for each group id -->
  <variable name="id-prefix" select="@id" />

  <for-each select="./lv:group-gen">
    <apply-templates select="following-sibling::lv:group-def" mode="preproc:gen-group">
      <with-param name="id-prefix" select="$id-prefix" />
      <with-param name="gen" select="." />
    </apply-templates>
  </for-each>

  <!-- this data will be useful, but we must ensure that it's ignored by the
       existing processor -->
  <preproc:sorted-groups id="{$id-prefix}">
    <for-each select="lv:group-gen">
      <preproc:group ref="{$id-prefix}_{@name}">
        <apply-templates select="//lv:group-sort" mode="preproc:gen-group">
          <with-param name="name" select="@name" />
        </apply-templates>
      </preproc:group>
    </for-each>
  </preproc:sorted-groups>
</template>

<template match="lv:group-sort" mode="preproc:gen-group" priority="5">
  <param name="name" />
  <variable name="by" select="@by" />
  <!-- TODO: template to generate name; this is duplicate logic -->

  <preproc:sort by="{$name}_{$by}" />
</template>

<template match="lv:group-def" mode="preproc:gen-group" priority="5">
  <param name="id-prefix" />
  <param name="gen" />

  <variable name="name" select="$gen/@name" />

  <lv:group id="{$id-prefix}_{$name}">
    <!-- all attributes on the group-def should be copied to the group itself -->
    <apply-templates select="@*|*" mode="preproc:gen-group">
      <with-param name="gen" select="$gen" />
    </apply-templates>
  </lv:group>

  <preproc:repass />
</template>

<template match="lv:group-prop" mode="preproc:gen-group" priority="5">
  <param name="gen" />

  <!-- retrieve the associated attribute from the group-gen node -->
  <variable name="ref" select="@ref" />
  <variable name="value" select="$gen/@*[ local-name() = $ref ]" />

  <choose>
    <!-- if we didn't find a value, try a default -->
    <when test="not( $value )">
      <variable name="default" select="@default" />
      <value-of select="$gen/@*[ local-name() = $default ]" />
    </when>

    <!-- use the value we found -->
    <otherwise>
      <value-of select="$value" />
    </otherwise>
  </choose>
</template>

<template name="preproc:gen-group-attr" match="@*" mode="preproc:gen-group" priority="9">
  <param name="attr" select="." />
  <param name="gen" />

  <attribute name="{local-name()}">
    <choose>
      <!-- has inline ref -->
      <when test="substring-before( $attr, '}' )">
        <!-- process any attribute data appearing before the first ref -->
        <call-template name="preproc:gen-group-attr">
          <with-param name="attr" select="substring-before( $attr, '{' )" />
          <with-param name="gen" select="$gen" />
        </call-template>

        <!-- process the curly-brace portion of the string -->
        <variable name="ref"
          select="substring-before( substring-after( $attr, '{' ), '}' )" />
        <value-of select="$gen/@*[ local-name() = $ref ]" />

        <!-- process the remainder -->
        <call-template name="preproc:gen-group-attr">
          <with-param name="attr" select="substring-after( $attr, '}' )" />
          <with-param name="gen" select="$gen" />
        </call-template>
      </when>

      <!-- normal attribute -->
      <otherwise>
        <value-of select="$attr" />
      </otherwise>
    </choose>
  </attribute>
</template>

<template match="*" mode="preproc:gen-group" priority="1">
  <param name="gen" />

  <copy>
    <apply-templates select="@*" mode="preproc:gen-group">
      <with-param name="gen" select="$gen" />
    </apply-templates>

    <!-- ensures CDATA is also processed -->
    <apply-templates mode="preproc:gen-group">
      <with-param name="gen" select="$gen" />
    </apply-templates>
  </copy>
</template>

</stylesheet>
