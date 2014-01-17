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
      </head>
      <body>
	<h1>Libvirt Security Notice Index</h1>

	<ul>
	  <xsl:apply-templates select="lsnl:security-notice">
	    <xsl:sort select="@name" order="descending" />
	  </xsl:apply-templates>
	</ul>
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
    <xsl:variable name="notice" select="document(concat('../', @name))"/>
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
