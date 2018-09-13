<?xml version="1.0" encoding="ISO-8859-1"?>
<!--
  CVV2 question type

  Copyright (C) 2017-2018 R-T Specialty, LLC.

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

  This type collects very sensitive PII that may be subject to PCI
  regulations; CVV2 numbers must be processed immediately and must not be
  stored, even if encrypted. Be warned.
-->
<xsl:stylesheet version="2.0"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:lv="http://www.lovullo.com">

<xsl:template match="lv:question[@type='cvv2']">
  <xsl:param name="id" select="@id" />
  <xsl:param name="prefix" />

  <input type="text">
    <xsl:call-template name="generic-attributes">
      <xsl:with-param name="prefix" select="$prefix" />
      <xsl:with-param name="id" select="$id" />
    </xsl:call-template>
  </input>
  <a class="action" data-ref="{$id}_cvv2_dialog_content" data-type="cvv2Dialog" >What is CVV/CSV?</a>
  <div class="cvv2-dialog-box-wrapper" id="{$id}_cvv2_dialog_content" >
    <div class="cvv2-row-clear" >
      <img class="cvv2-image-left" src="/images/cvv_card_back.png" />
      <b>Visa&#x00AE;, Mastercard&#x00AE;, and Discover&#x00AE; cardholders:</b>
      <p>Turn your card over and look at the signature box. You should see either the entire 16-digit credit card
      number or just the last four digits followed by a special 3-digit code. This 3-digit code is your CVV
      number / Card Security Code.</p>
    </div>
    <div class="cvv2-row-clear" >
      <img class="cvv2-image-right" src="/images/cvv_card_front.png" />
      <b>American Express&#x00AE; cardholders:</b>
      <p>Look for the 4-digit code printed on the front of your card just above and to the right of your main
      credit card number. This 4-digit code is your Card Identification Number (CID). The CID is the four-digit
      code printed just above the Account Number.</p>
    </div>
  </div>
</xsl:template>

<!--
    determines the default value
-->
<xsl:template match="lv:*[@type='cvv2']" mode="get-default">
  <xsl:value-of select="if ( @default ) then @default else ''" />
</xsl:template>

</xsl:stylesheet>

