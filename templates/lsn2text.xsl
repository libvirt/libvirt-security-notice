<!--
  - This program is free software; you can redistribute it and/or modify
  - it under the terms of the GNU General Public License as published by
  - the Free Software Foundation; either version 2 of the License, or
  - (at your option) any later version.
  -
  - This program is distributed in the hope that it will be useful,
  - but WITHOUT ANY WARRANTY; without even the implied warranty of
  - MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  - GNU General Public License for more details.
  -
  - You should have received a copy of the GNU General Public License
  - along with this program.  If not, see
  - <http://www.gnu.org/licenses/>.
  -->
<xsl:stylesheet
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:lsn="http://security.libvirt.org/xmlns/security-notice/1.0"
  exclude-result-prefixes="xsl lsn"
  version="1.0">

  <xsl:output method="text"/>

  <xsl:variable name="nl">
    <xsl:text>
</xsl:text>
  </xsl:variable>

  <!-- based on http://plasmasturm.org/log/xslwordwrap/ -->
  <!-- Copyright 2010 Aristotle Pagaltzis; under the MIT licence -->
  <!-- http://www.opensource.org/licenses/mit-license.php -->
  <xsl:template name="wrap-string">
    <xsl:param name="str" />
    <xsl:param name="wrap-col" />
    <xsl:param name="break-mark" />
    <xsl:param name="pos" select="0" />
    <xsl:choose>
      <xsl:when test="contains( $str, ' ' )">
	<xsl:variable name="first-word" select="substring-before( $str, ' ' )" />
	<xsl:variable name="pos-now" select="$pos + 1 + string-length( $first-word )" />
	<xsl:choose>
          <xsl:when test="$pos > 0 and $pos-now >= $wrap-col">
            <xsl:copy-of select="$break-mark" />
            <xsl:call-template name="wrap-string">
              <xsl:with-param name="str" select="$str" />
              <xsl:with-param name="wrap-col" select="$wrap-col" />
              <xsl:with-param name="break-mark" select="$break-mark" />
              <xsl:with-param name="pos" select="0" />
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:if test="$pos > 0">
              <xsl:text> </xsl:text>
            </xsl:if>
            <xsl:value-of select="$first-word" />
            <xsl:call-template name="wrap-string">
              <xsl:with-param name="str" select="substring-after( $str, ' ' )" />
              <xsl:with-param name="wrap-col" select="$wrap-col" />
              <xsl:with-param name="break-mark" select="$break-mark" />
              <xsl:with-param name="pos" select="$pos-now" />
            </xsl:call-template>
          </xsl:otherwise>
	</xsl:choose>
      </xsl:when>
      <xsl:otherwise>
	<xsl:choose>
          <xsl:when test="$pos + string-length( $str ) >= $wrap-col">
            <xsl:copy-of select="$break-mark" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:if test="$pos > 0">
              <xsl:text> </xsl:text>
            </xsl:if>
          </xsl:otherwise>
	</xsl:choose>
	<xsl:value-of select="$str" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="/lsn:security-notice">
    <xsl:text>        Libvirt Security Notice: LSN-</xsl:text>
    <xsl:value-of select="lsn:id"/>
    <xsl:value-of select="$nl"/>
    <xsl:text>        ======================================</xsl:text>
    <xsl:value-of select="$nl"/>

    <xsl:value-of select="$nl"/>


    <xsl:apply-templates select="lsn:summary"/>
    <xsl:apply-templates select="lsn:lifecycle"/>
    <xsl:apply-templates select="lsn:credits"/>
    <xsl:apply-templates select="lsn:reference"/>
    <xsl:apply-templates select="lsn:description"/>
    <xsl:apply-templates select="lsn:impact"/>
    <xsl:apply-templates select="lsn:workaround"/>
    <xsl:apply-templates select="lsn:product"/>
  </xsl:template>

  <xsl:template match="lsn:summary">
    <xsl:text>       Summary: </xsl:text>
    <xsl:call-template name="wrap-string">
      <xsl:with-param name="str" select="normalize-space(.)"/>
      <xsl:with-param name="wrap-col" select="52"/>
      <xsl:with-param name="break-mark" select="concat($nl, '                ')"/>
    </xsl:call-template>
    <xsl:value-of select="$nl"/>
  </xsl:template>

  <xsl:template match="lsn:lifecycle">
    <xsl:text>   Reported on: </xsl:text>
    <xsl:value-of select="lsn:reported"/>
    <xsl:value-of select="$nl"/>

    <xsl:text>  Published on: </xsl:text>
    <xsl:value-of select="lsn:published"/>
    <xsl:value-of select="$nl"/>

    <xsl:text>      Fixed on: </xsl:text>
    <xsl:value-of select="lsn:fixed"/>
    <xsl:value-of select="$nl"/>
  </xsl:template>

  <xsl:template match="lsn:credits">
    <xsl:text>   Reported by: </xsl:text>
    <xsl:for-each select="lsn:reporter">
      <xsl:value-of select="lsn:name"/>
      <xsl:text> &lt;</xsl:text>
      <xsl:value-of select="lsn:email"/>
      <xsl:text>&gt;</xsl:text>
      <xsl:if test="position() > 0">
	<xsl:text>                    </xsl:text>
      </xsl:if>
      <xsl:if test="position() != last()">
	<xsl:value-of select="$nl"/>
      </xsl:if>
    </xsl:for-each>
    <xsl:value-of select="$nl"/>
    <xsl:text>    Patched by: </xsl:text>
    <xsl:for-each select="lsn:patcher">
      <xsl:value-of select="lsn:name"/>
      <xsl:text> &lt;</xsl:text>
      <xsl:value-of select="lsn:email"/>
      <xsl:text>&gt;</xsl:text>
      <xsl:if test="position() != last()">
	<xsl:value-of select="concat(',',$nl)"/>
      </xsl:if>
      <xsl:if test="position() > 0">
	<xsl:text>                </xsl:text>
      </xsl:if>
    </xsl:for-each>
    <xsl:value-of select="$nl"/>
  </xsl:template>

  <xsl:template match="lsn:advisory">
    <xsl:value-of select="@type"/>
    <xsl:text>-</xsl:text>
    <xsl:value-of select="@id"/>
  </xsl:template>

  <xsl:template match="lsn:bug">
    <xsl:value-of select="@tracker"/>
    <xsl:text> bug #</xsl:text>
    <xsl:value-of select="@id"/>
  </xsl:template>

  <xsl:template match="lsn:reference">
    <xsl:text>      See also: </xsl:text>
    <xsl:variable name="refs">
      <xsl:for-each select="lsn:advisory|lsn:bug">
	<xsl:apply-templates select="."/>
	<xsl:if test="position() != last()">
	  <xsl:text>, </xsl:text>
	</xsl:if>
      </xsl:for-each>
    </xsl:variable>
    <xsl:call-template name="wrap-string">
      <xsl:with-param name="str" select="$refs"/>
      <xsl:with-param name="wrap-col" select="52"/>
      <xsl:with-param name="break-mark" select="concat($nl, '                ')"/>
    </xsl:call-template>
    <xsl:value-of select="$nl"/>
    <xsl:value-of select="$nl"/>
  </xsl:template>

  <xsl:template match="lsn:description">
    <xsl:text>Description</xsl:text>
    <xsl:value-of select="$nl"/>
    <xsl:text>-----------</xsl:text>
    <xsl:value-of select="$nl"/>
    <xsl:value-of select="$nl"/>
    <xsl:call-template name="wrap-string">
      <xsl:with-param name="str" select="normalize-space(.)"/>
      <xsl:with-param name="wrap-col" select="70"/>
      <xsl:with-param name="break-mark" select="$nl"/>
    </xsl:call-template>
    <xsl:value-of select="$nl"/>
    <xsl:value-of select="$nl"/>
  </xsl:template>

  <xsl:template match="lsn:impact">
    <xsl:text>Impact</xsl:text>
    <xsl:value-of select="$nl"/>
    <xsl:text>------</xsl:text>
    <xsl:value-of select="$nl"/>
    <xsl:value-of select="$nl"/>
    <xsl:call-template name="wrap-string">
      <xsl:with-param name="str" select="normalize-space(.)"/>
      <xsl:with-param name="wrap-col" select="70"/>
      <xsl:with-param name="break-mark" select="$nl"/>
    </xsl:call-template>
    <xsl:value-of select="$nl"/>
    <xsl:value-of select="$nl"/>
  </xsl:template>

  <xsl:template match="lsn:workaround">
    <xsl:text>Workaround</xsl:text>
    <xsl:value-of select="$nl"/>
    <xsl:text>----------</xsl:text>
    <xsl:value-of select="$nl"/>
    <xsl:value-of select="$nl"/>
    <xsl:call-template name="wrap-string">
      <xsl:with-param name="str" select="normalize-space(.)"/>
      <xsl:with-param name="wrap-col" select="70"/>
      <xsl:with-param name="break-mark" select="$nl"/>
    </xsl:call-template>
    <xsl:value-of select="$nl"/>
    <xsl:value-of select="$nl"/>
  </xsl:template>


  <xsl:template match="lsn:product">
    <xsl:text>Affected product</xsl:text>
    <xsl:value-of select="$nl"/>
    <xsl:text>----------------</xsl:text>
    <xsl:value-of select="$nl"/>
    <xsl:value-of select="$nl"/>
    <xsl:text>        Name: </xsl:text>
    <xsl:value-of select="@name"/>
    <xsl:value-of select="$nl"/>
    <xsl:text>  Repository: git://libvirt.org/git/</xsl:text><xsl:value-of select="lsn:repository"/>
    <xsl:value-of select="$nl"/>
    <xsl:text>              http://libvirt.org/git/?p=</xsl:text><xsl:value-of select="lsn:repository"/>
    <xsl:value-of select="$nl"/>
    <xsl:value-of select="$nl"/>

    <xsl:for-each    select="lsn:branch">
      <xsl:text>      Branch: </xsl:text>
      <xsl:value-of select="lsn:name"/>
      <xsl:value-of select="$nl"/>
      <xsl:if test="count(lsn:tag)">
	<xsl:for-each select="lsn:tag[@state='vulnerable']">
	  <xsl:text>   Broken in: </xsl:text>
	  <xsl:value-of select="."/>
	  <xsl:value-of select="$nl"/>
	</xsl:for-each>
	<xsl:for-each select="lsn:tag[@state='fixed']">
	  <xsl:text>    Fixed in: </xsl:text>
	  <xsl:value-of select="."/>
	  <xsl:value-of select="$nl"/>
	</xsl:for-each>
      </xsl:if>
      <xsl:if test="count(lsn:change)">
	<xsl:for-each select="lsn:change[@state='vulnerable']">
	  <xsl:text>   Broken by: </xsl:text>
	  <xsl:value-of select="."/>
	  <xsl:value-of select="$nl"/>
	</xsl:for-each>
	<xsl:for-each select="lsn:change[@state='fixed']">
	  <xsl:text>    Fixed by: </xsl:text>
	  <xsl:value-of select="."/>
	  <xsl:value-of select="$nl"/>
	</xsl:for-each>
      </xsl:if>
      <xsl:value-of select="$nl"/>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
