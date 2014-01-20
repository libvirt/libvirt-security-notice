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
  xmlns:lsnl="http://security.libvirt.org/xmlns/security-notice-list/1.0"
  exclude-result-prefixes="xsl lsn"
  version="1.0">

  <xsl:output method="xml" indent="yes"/>

  <xsl:template match="/lsnl:security-notice-list">
    <html>
      <head>
	<title>Libvirt Security Notice Index</title>
	<link rel="stylesheet" type="text/css" href="main.css" />
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
      </head>
      <body>
	<h1>Libvirt Security Notice Index</h1>

	<ul>
	  <xsl:apply-templates select="lsnl:security-notice">
	    <xsl:sort select="@name" order="descending" />
	  </xsl:apply-templates>
	</ul>

	<p class="alt">
	  Alternative formats: <a href="index.xml">[xml]</a>
	</p>
      </body>
    </html>
  </xsl:template>

  <xsl:template name="lsnhref">
    <xsl:param name="id"/>

    <xsl:variable name="dir" select="substring-before($id, '-')"/>
    <xsl:variable name="file" select="substring-after($id, '-')"/>

    <xsl:value-of select="concat($dir, '/', $file, '.html')"/>
  </xsl:template>

  <xsl:template match="lsnl:security-notice">
    <xsl:variable name="notice" select="document(concat('../notices/', @name))"/>
    <xsl:variable name="id" select="$notice/lsn:security-notice/lsn:id"/>
    <xsl:variable name="summary" select="$notice/lsn:security-notice/lsn:summary"/>
    <xsl:variable name="href">
      <xsl:call-template name="lsnhref">
	<xsl:with-param name="id" select="$id"/>
      </xsl:call-template>
    </xsl:variable>

    <li><a href="{$href}">LSN-<xsl:value-of select="$id"/>: <xsl:value-of select="$summary"/></a></li>
  </xsl:template>
</xsl:stylesheet>
