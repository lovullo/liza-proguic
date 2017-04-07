<?xml version="1.0"?>
<!--
  The program XML preprocessor

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

  TODO: Merge with expand.xsl
-->
<xsl:stylesheet version="2.0"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:lv="http://www.lovullo.com"
  xmlns:assert="http://www.lovullo.com/assert"
  xmlns:preproc="http://www.lovullo.com/program/preprocessor">


<xsl:template match="lv:program[ not( @version ) ]" mode="preprocess">
  <!-- TODO: pass into stylesheet as a param -->
  <xsl:variable name="path" select="'../.version.xml'" />
  <xsl:variable name="version" select="document( $path, /lv:program )/*" />

  <xsl:variable name="root">
    <xsl:copy>
      <xsl:copy-of select="@*" />

      <!-- add version attribute -->
      <xsl:attribute name="version" select="$version" />

      <xsl:copy-of select="*" />
    </xsl:copy>
  </xsl:variable>

  <xsl:document>
    <xsl:apply-templates select="$root" mode="preprocess" />
  </xsl:document>
</xsl:template>

<!--
  Triggers preprocessing (this is the preprocessor entry point)

  If multiple passes are needed, then they should be added here.
-->
<xsl:template match="*" mode="preprocess">
  <!-- currently, we only perform expansions (derivate additional content from
       the existing content) -->
  <xsl:variable name="result">
    <xsl:apply-templates select="." mode="preproc:expand" />
  </xsl:variable>

  <!-- recurse if another pass has been scheduled -->
  <xsl:choose>
    <xsl:when test="$result//preproc:repass">
      <xsl:apply-templates select="$result" mode="preprocess" />
    </xsl:when>

    <xsl:otherwise>
      <!-- no re-pass scheduled; return -->
      <xsl:copy-of select="$result" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- default expansion; do nothing -->
<xsl:template match="*" mode="preproc:expand" priority="1">
  <xsl:copy>
    <xsl:copy-of select="@*" />

    <xsl:apply-templates mode="preproc:expand" />
  </xsl:copy>
</xsl:template>


<xsl:template match="preproc:repass" mode="preproc:expand" priority="5">
  <!-- remove to prevent infinite recursion -->
</xsl:template>


<!--
  Copies the given node and appends the given content

  This performs no additional processing on the child nodes; the caller is
  responsible for determining what should be done next.
-->
<xsl:template match="*" mode="preproc:inject">
  <xsl:param name="content" />

  <xsl:copy>
    <!-- copy all existing attributes and nodes in addition to the given
         content -->
    <xsl:copy-of select="@*|*|$content" />
  </xsl:copy>
</xsl:template>


<!--
  Injects content into either the given node or, if the given node does not
  exist, the provided new node

  This simply abstracts "use if exists, otherwise use this", which is otherwise
  very verbose.
-->
<xsl:template name="preproc:injectornew">
  <xsl:param name="node" />
  <xsl:param name="new" />
  <xsl:param name="content" />

  <!-- determine the node we will inject into (an existing one, if available,
       otherwise a new node -->
  <xsl:variable name="inject-into">
    <xsl:choose>
      <!-- if node exists, inject the content into it -->
      <xsl:when test="$node">
        <xsl:copy-of select="$node" />
      </xsl:when>

      <!-- otherwise, create the node anew and inject the content -->
      <xsl:otherwise>
        <xsl:copy-of select="$new" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- perform the injection! -->
  <xsl:apply-templates select="$inject-into" mode="preproc:inject">
    <xsl:with-param name="content">
      <xsl:copy-of select="$content" />
    </xsl:with-param>
  </xsl:apply-templates>
</xsl:template>


<!--
  Generate ids for groups that do not have one

  We'll do our best to generate a sane id from the title.

  Group ids are necessary for many operations, but the ids are primarily used
  internally; we shouldn't require that the developer provide one unless he/she
  actually needs to reference the group by its id.
-->
<xsl:template match="lv:group[ not( @id ) ]" mode="preproc:expand" priority="5">
  <xsl:variable name="title"
                select="if ( @title and not( @title = '' ) ) then
                          @title
                        else
                          generate-id( . )" />

  <xsl:copy>
    <!-- copy existing attributes -->
    <xsl:copy-of select="@*" />

    <!-- create an id from the title by removing spaces and other permitted
         chars (it is expected that @title is restricted such that we can do
         this without a problem) -->
    <xsl:attribute name="id">
      <xsl:value-of select="translate( $title, ' ().-*:', '' )" />
    </xsl:attribute>

    <xsl:apply-templates mode="preproc:expand" />
  </xsl:copy>

  <preproc:repass />
</xsl:template>


<!--
  Generate ids for statics that do not have one
-->
<xsl:template mode="preproc:expand" priority="5"
              match="lv:static[ not( @id ) ]">
  <xsl:copy>
    <xsl:copy-of select="@*" />
    <xsl:attribute name="id" select="generate-id( . )" />

    <xsl:apply-templates mode="preproc:expand" />
  </xsl:copy>

  <preproc:repass />
</xsl:template>


<!--
  Determine group dimensions (either a scalar or a vector) based on
  the group style
-->
<xsl:template mode="preproc:expand" priority="4"
              match="lv:group[ not( @dim ) ]">
  <xsl:copy>
    <xsl:copy-of select="@*" />

    <!-- TODO: store dimensions somewhere; this is a maintenance issue -->
    <xsl:attribute name="dim">
      <xsl:value-of
          select="if ( not( @style )
                       or @style = 'flat'
                       or @style = 'wide' ) then
                    '0'
                  else
                    '1'" />
    </xsl:attribute>

    <xsl:apply-templates mode="preproc:expand" />
  </xsl:copy>

  <preproc:repass />
</xsl:template>


<!--
  Predicate require ids on the elemnts that they are operating on;
  generate option ids if a predicate is present.
-->
<xsl:template mode="preproc:expand" priority="5"
              match="lv:option[ @when and not( @id ) ]">
  <xsl:copy>
    <xsl:copy-of select="@*" />

    <xsl:attribute name="id">
      <xsl:value-of select="concat( '__',
                                    parent::lv:question/@id,
                                    '_opt_',
                                    generate-id(.) )" />
    </xsl:attribute>

    <xsl:apply-templates mode="preproc:expand" />
  </xsl:copy>

  <preproc:repass />
</xsl:template>


<!--
  Inherit dimension from parent group

  This will be populated on a repass once the group/@dim becomes
  available
-->
<xsl:template mode="preproc:expand" priority="5"
              match="lv:question[
                       not( @dim )
                       and exists( ancestor::lv:group/@dim ) ]">
  <xsl:copy>
    <xsl:copy-of select="@*" />

    <xsl:attribute name="dim">
      <xsl:value-of select="ancestor::lv:group/@dim" />
    </xsl:attribute>

    <xsl:apply-templates mode="preproc:expand" />
  </xsl:copy>

  <preproc:repass />
</xsl:template>


<!--
  Generate id for options containing predicates

  Any option that contains a predicate must have an identifier that
  the UI framework can use to operate on it.  The only situation in
  which this is currently applicable is when the option contains a
  predicate.
-->
<xsl:template mode="preproc:expand" priority="9"
              match="lv:question/lv:option[ @when
                                            and not( @id ) ]">
  <xsl:copy>
    <xsl:sequence select="@*" />

    <xsl:attribute name="id"
                   select="concat( parent::lv:question/@id,
                                   '__opt__',
                                   generate-id( . ) )" />

    <xsl:sequence select="node()" />
  </xsl:copy>

  <preproc:repass />
</xsl:template>


<!--
  Copy @when from referenced question, unless overridden
-->
<xsl:template match="lv:answer[ not( @when ) and @ref=//lv:question[ @when ]/@id ]" mode="preproc:expand" priority="3">
  <xsl:copy>
    <xsl:copy-of select="@*" />

    <!-- copy @when from referenced question -->
    <xsl:variable name="ref" select="@ref" />
    <xsl:copy-of select="//lv:question[ @id=$ref ]/@when" />

    <xsl:apply-templates mode="preproc:expand" />
  </xsl:copy>

  <preproc:repass />
</xsl:template>


<xsl:template match="lv:answer[ not(@id) ]|lv:display[ not(@id) ]" mode="preproc:expand" priority="7">
  <xsl:copy>
    <!-- copy existing attributes -->
    <xsl:copy-of select="@*" />

    <!-- create an id from the ref by removing spaces and other permitted
         chars (making it easier to identify), followed by a unique id (to
         ensure that we do not have duplicate ids) -->
    <xsl:attribute name="id">
      <xsl:value-of select="concat(translate( @ref, ' ().-', '' ), '_', generate-id(.))" />
    </xsl:attribute>

    <!-- recurse -->
    <xsl:apply-templates mode="preproc:expand" />
  </xsl:copy>

  <preproc:repass />
</xsl:template>


<!--
  Expand assertion show/hide group triggers

  This trigger will expand into two separate triggers: show and hide. They will
  be added as separate success/failure nodes, even if existing nodes are
  present; the reason for this is that merging can become complicated when the
  nodes contain their own attributes.

  This will trigger another pass of the preprocessor (which is a much simpler
  implementation than the alternative) since content will have been added.
-->
<xsl:template match="
    assert:*/lv:trigger[
      @group='showhide'
      or @group='hideshow'
    ]
  "
  mode="preproc:expand" priority="5">

  <!-- How convenient that each event is four characters in length! The first
       four characters will be taken as the success event and the last four as
       the failure (note that XPath expressions are 1-indexed). -->
  <xsl:variable name="event-success"
    select="substring( @group, 1, 4 )" />
  <xsl:variable name="event-failure"
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
</xsl:template>


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
<xsl:template match="lv:question[@type='csr']" mode="preproc:expand" priority="5">
  <xsl:param name="id" select="@id" />

  <lv:question type="select" id="agency_contact_id" required="true" class="csr">
    <xsl:attribute name="id" select="string-join( ($id, '_id'), '')" />
    <xsl:attribute name="label" select="string-join( (@label, 'Name'), ' ')" />
  </lv:question>

  <lv:question type="text" id="agency_contact_name" required="true" hidden="true">
    <xsl:attribute name="id" select="string-join( ($id, '_name'), '')" />
    <xsl:attribute name="label" select="string-join( (@label, 'Name'), ' ')" />
  </lv:question>

  <lv:question type="email" id="agency_contact_email" readonly="true" required="true">
    <xsl:attribute name="id" select="string-join( ($id, '_email'), '')" />
    <xsl:attribute name="label" select="string-join( (@label, 'E-mail'), ' ')" />
  </lv:question>

  <lv:question type="phone" id="agency_contact_phone">
    <xsl:attribute name="id" select="string-join( ($id, '_phone'), '')" />
    <xsl:attribute name="label" select="string-join( (@label, 'Phone'), ' ')" />
  </lv:question>
</xsl:template>


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
<xsl:template match="lv:question[ lv:data/lv:label and not( @preproc:labeled ) ]"
  mode="preproc:expand" priority="5">

  <!-- copy the question node, preprocessing the lv:data node -->
  <xsl:copy>
    <xsl:copy-of select="@*" />
    <xsl:attribute name="preproc:labeled" select="'true'" />

    <xsl:apply-templates mode="preproc:expand" />
  </xsl:copy>

  <!-- add our label ref to store the data (this will always be a text type) -->
  <lv:external id="{@id}_label" type="text" />
</xsl:template>

<xsl:template match="lv:question/lv:data[ lv:label ]" mode="preproc:expand" priority="5">
  <xsl:copy>
    <xsl:copy-of select="@*|*" />

    <!-- add a map to our label ref to be populated with the rest of our data -->
    <lv:map param="{lv:label/@from}" into="{parent::lv:question/@id}_label" />
  </xsl:copy>
</xsl:template>

<xsl:template match="lv:answer[ @ref=//lv:question[ lv:data/lv:label ]/@id ]" mode="preproc:expand" priority="5">
  <!-- convert into an lv:display, since we won't be referencing an lv:question anymore -->
  <lv:display>
    <!-- copy over any of the lv:answer attributes -->
    <xsl:copy-of select="@*" />

    <!-- override ref to use our generated label ref -->
    <xsl:attribute name="ref" select="concat( @ref, '_label' )" />

    <!-- explicitly add the type -->
    <xsl:attribute name="text" select="'text'" />

    <!-- we'll need to add the label of the question as well to ensure proper display -->
    <xsl:variable name="ref" select="@ref" />
    <xsl:attribute name="label" select="//lv:question[ @id=$ref ]/@label" />
  </lv:display>
</xsl:template>


<!-- add lv:external nodes for every permitRef ref to ensure that they are
     initialized with proper defaults -->
<xsl:template match="lv:group/lv:set[ @permitRef='true' ]"
              mode="preproc:expand"
              priority="2">
  <xsl:sequence select="." />

  <xsl:for-each select="lv:*[ @ref ]">
    <lv:external type="{@type}" id="{@ref}">
      <xsl:if test="@dim">
        <xsl:attribute name="dim" select="@dim" />
      </xsl:if>
    </lv:external>
  </xsl:for-each>
</xsl:template>


<!--
  If both @group and @event were provided, then the developer has done something
  wrong

  Note that this has a higher priority than the other templates
-->
<xsl:template match="lv:trigger[ @group and @event ]" mode="preproc:expand" priority="9">
  <preproc:error>
    <xsl:text>Trigger cannot have both @group and @event</xsl:text>
  </preproc:error>
</xsl:template>


<!--
  Catch invalid group triggers

  Currently, we only support group triggers within assertions.
-->
<xsl:template match="lv:trigger[ @group ]" mode="preproc:expand" priority="4">
  <preproc:error>
    <xsl:text>Misplaced or unknown group trigger: </xsl:text>
    <xsl:value-of select="@group" />
  </preproc:error>
</xsl:template>


<xsl:template match="lv:group-set" mode="preproc:expand" priority="5">
  <xsl:variable name="self" select="." />

  <!-- will be used as the prefix for each group id -->
  <xsl:variable name="id-prefix" select="@id" />

  <xsl:for-each select="./lv:group-gen">
    <xsl:apply-templates select="following-sibling::lv:group-def" mode="preproc:gen-group">
      <xsl:with-param name="id-prefix" select="$id-prefix" />
      <xsl:with-param name="gen" select="." />
    </xsl:apply-templates>
  </xsl:for-each>

  <!-- this data will be useful, but we must ensure that it's ignored by the
       existing processor -->
  <preproc:sorted-groups id="{$id-prefix}">
    <xsl:for-each select="lv:group-gen">
      <preproc:group ref="{$id-prefix}_{@name}">
        <xsl:apply-templates select="//lv:group-sort" mode="preproc:gen-group">
          <xsl:with-param name="name" select="@name" />
        </xsl:apply-templates>
      </preproc:group>
    </xsl:for-each>
  </preproc:sorted-groups>
</xsl:template>

<xsl:template match="lv:group-sort" mode="preproc:gen-group" priority="5">
  <xsl:param name="name" />
  <xsl:variable name="by" select="@by" />
  <!-- TODO: template to generate name; this is duplicate logic -->

  <preproc:sort by="{$name}_{$by}" />
</xsl:template>

<xsl:template match="lv:group-def" mode="preproc:gen-group" priority="5">
  <xsl:param name="id-prefix" />
  <xsl:param name="gen" />

  <xsl:variable name="name" select="$gen/@name" />

  <lv:group id="{$id-prefix}_{$name}">
    <!-- all attributes on the group-def should be copied to the group itself -->
    <xsl:apply-templates select="@*|*" mode="preproc:gen-group">
      <xsl:with-param name="gen" select="$gen" />
    </xsl:apply-templates>
  </lv:group>

  <preproc:repass />
</xsl:template>

<xsl:template match="lv:group-prop" mode="preproc:gen-group" priority="5">
  <xsl:param name="gen" />

  <!-- retrieve the associated attribute from the group-gen node -->
  <xsl:variable name="ref" select="@ref" />
  <xsl:variable name="value" select="$gen/@*[ local-name() = $ref ]" />

  <xsl:choose>
    <!-- if we didn't find a value, try a default -->
    <xsl:when test="not( $value )">
      <xsl:variable name="default" select="@default" />
      <xsl:value-of select="$gen/@*[ local-name() = $default ]" />
    </xsl:when>

    <!-- use the value we found -->
    <xsl:otherwise>
      <xsl:value-of select="$value" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="preproc:gen-group-attr" match="@*" mode="preproc:gen-group" priority="9">
  <xsl:param name="attr" select="." />
  <xsl:param name="gen" />

  <xsl:attribute name="{local-name()}">
    <xsl:choose>
      <!-- has inline ref -->
      <xsl:when test="substring-before( $attr, '}' )">
        <!-- process any attribute data appearing before the first ref -->
        <xsl:call-template name="preproc:gen-group-attr">
          <xsl:with-param name="attr" select="substring-before( $attr, '{' )" />
          <xsl:with-param name="gen" select="$gen" />
        </xsl:call-template>

        <!-- process the curly-brace portion of the string -->
        <xsl:variable name="ref"
          select="substring-before( substring-after( $attr, '{' ), '}' )" />
        <xsl:value-of select="$gen/@*[ local-name() = $ref ]" />

        <!-- process the remainder -->
        <xsl:call-template name="preproc:gen-group-attr">
          <xsl:with-param name="attr" select="substring-after( $attr, '}' )" />
          <xsl:with-param name="gen" select="$gen" />
        </xsl:call-template>
      </xsl:when>

      <!-- normal attribute -->
      <xsl:otherwise>
        <xsl:value-of select="$attr" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:attribute>
</xsl:template>

<xsl:template match="*" mode="preproc:gen-group" priority="1">
  <xsl:param name="gen" />

  <xsl:copy>
    <xsl:apply-templates select="@*" mode="preproc:gen-group">
      <xsl:with-param name="gen" select="$gen" />
    </xsl:apply-templates>

    <!-- ensures CDATA is also processed -->
    <xsl:apply-templates mode="preproc:gen-group">
      <xsl:with-param name="gen" select="$gen" />
    </xsl:apply-templates>
  </xsl:copy>
</xsl:template>

</xsl:stylesheet>

