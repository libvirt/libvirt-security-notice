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

  <xsl:output method="xml" indent="yes"/>

  <xsl:template name="selfhref">
    <xsl:param name="id"/>
    <xsl:param name="ext"/>

    <xsl:variable name="dir" select="substring-before($id, '-')"/>
    <xsl:variable name="file" select="substring-after($id, '-')"/>

    <xsl:value-of select="concat('../', $dir, '/', $file, '.', $ext)"/>
  </xsl:template>

  <xsl:template match="/lsn:security-notice">
    <html>
      <head>
	<title>Libvirt Security Notice: LSN-<xsl:value-of select="lsn:id"/></title>
	<link rel="stylesheet" type="text/css" href="../main.css" />
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
      </head>
      <body>
	<h1>Libvirt Security Notice: LSN-<xsl:value-of select="lsn:id"/></h1>

	<h2>
	  <xsl:value-of select="lsn:summary"/>
	</h2>

	<xsl:apply-templates select="lsn:lifecycle"/>
	<xsl:apply-templates select="lsn:credits"/>

	<xsl:apply-templates select="lsn:reference"/>
	<xsl:apply-templates select="lsn:description"/>
	<xsl:apply-templates select="lsn:impact"/>
	<xsl:apply-templates select="lsn:workaround"/>
	<xsl:apply-templates select="lsn:product"/>

	<hr/>

	<xsl:call-template name="selflink"/>

      </body>
    </html>
  </xsl:template>

  <xsl:template name="selflink">
    <p class="alt">
      Alternative formats:
      <a>
	<xsl:attribute name="href">
	  <xsl:call-template name="selfhref">
	    <xsl:with-param name="id" select="lsn:id"/>
	    <xsl:with-param name="ext" select="'xml'"/>
	  </xsl:call-template>
	</xsl:attribute>
	<xsl:text>[xml]</xsl:text>
      </a>
      <xsl:text> </xsl:text>
      <a>
	<xsl:attribute name="href">
	  <xsl:call-template name="selfhref">
	    <xsl:with-param name="id" select="lsn:id"/>
	    <xsl:with-param name="ext" select="'txt'"/>
	  </xsl:call-template>
	</xsl:attribute>
	<xsl:text>[text]</xsl:text>
      </a>
    </p>
  </xsl:template>

  <xsl:template match="lsn:lifecycle">
    <h3>Lifecycle</h3>
    <table>
      <tr>
	<th>Reported on:</th>
	<td><xsl:value-of select="lsn:reported"/></td>
      </tr>
      <tr>
	<th>Published on:</th>
	<td><xsl:value-of select="lsn:published"/></td>
      </tr>
      <tr>
	<th>Fixed on:</th>
	<td><xsl:value-of select="lsn:fixed"/></td>
      </tr>
    </table>
  </xsl:template>

  <xsl:template match="lsn:credits">
    <h3>Credits</h3>
    <table>
      <xsl:for-each select="lsn:reporter">
	<tr>
	  <xsl:if test="position() = 1">
	    <th>Reported by:</th>
	  </xsl:if>
	  <xsl:if test="position() > 1">
	    <th></th>
	  </xsl:if>
	  <td>
	    <xsl:if test="count(lsn:email) = 1">
	      <a href="mailto:{lsn:email}"><xsl:value-of select="lsn:name"/></a>
	    </xsl:if>
	    <xsl:if test="count(lsn:email) = 0">
	      <xsl:value-of select="lsn:name"/>
	    </xsl:if>
	  </td>
	</tr>
      </xsl:for-each>
      <xsl:for-each select="lsn:patcher">
	<tr>
	  <xsl:if test="position() = 1">
	    <th>Patched by:</th>
	  </xsl:if>
	  <xsl:if test="position() > 1">
	    <th></th>
	  </xsl:if>
	  <td>
	    <xsl:if test="count(lsn:email) = 1">
	      <a href="mailto:{lsn:email}"><xsl:value-of select="lsn:name"/></a>
	    </xsl:if>
	    <xsl:if test="count(lsn:email) = 0">
	      <xsl:value-of select="lsn:name"/>
	    </xsl:if>
	  </td>
	</tr>
      </xsl:for-each>
    </table>
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
    <h3>See also</h3>
    <ul>
    <xsl:for-each select="lsn:advisory|lsn:bug">
      <li><xsl:apply-templates select="."/></li>
    </xsl:for-each>
    </ul>
  </xsl:template>

  <xsl:template match="lsn:description">
    <h3>Description</h3>
    <p>
      <xsl:value-of select="."/>
    </p>
  </xsl:template>

  <xsl:template match="lsn:impact">
    <h3>Impact</h3>
    <p>
      <xsl:value-of select="."/>
    </p>
  </xsl:template>

  <xsl:template match="lsn:workaround">
    <h3>Workaround</h3>
    <p>
      <xsl:value-of select="."/>
    </p>
  </xsl:template>

  <xsl:template name="gitbranch">
    <xsl:param name="repository"/>
    <xsl:param name="branch"/>
    <a href="https://gitlab.com/libvirt/{$repository}/-/commits/{$branch}"><xsl:value-of select="$branch"/></a>
  </xsl:template>

  <xsl:template name="gittag">
    <xsl:param name="repository"/>
    <xsl:param name="tag"/>

    <a href="https://gitlab.com/libvirt/{$repository}/-/tags/{$tag}"><xsl:value-of select="$tag"/></a>
  </xsl:template>

  <xsl:template name="gitchange">
    <xsl:param name="repository"/>
    <xsl:param name="change"/>

    <a href="https://gitlab.com/libvirt/{$repository}/-/commit/{$change}"><xsl:value-of select="$change"/></a>
  </xsl:template>

  <xsl:template match="lsn:product">
    <h3>Affected product: <xsl:value-of select="@name"/></h3>

    <!-- For linking to gitlab we need the repository name without '.git' -->
    <xsl:variable name="repository">
        <xsl:choose>
            <xsl:when test="contains(lsn:repository, '.git')">
                <xsl:value-of select="substring-before(lsn:repository, '.git')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="lsn:repository"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:for-each select="lsn:branch">
      <table>
	<tr>
	  <th>Branch</th>
	  <td>
	    <xsl:call-template name="gitbranch">
	      <xsl:with-param name="repository" select="$repository"/>
	      <xsl:with-param name="branch" select="lsn:name"/>
	    </xsl:call-template>
	  </td>
	</tr>
	<xsl:for-each select="lsn:tag[@state='vulnerable']">
	  <tr>
	    <th>Broken in:</th>
	    <td>
	      <xsl:call-template name="gittag">
		<xsl:with-param name="repository" select="$repository"/>
		<xsl:with-param name="tag" select="."/>
	      </xsl:call-template>
	    </td>
	  </tr>
	</xsl:for-each>
	<xsl:for-each select="lsn:tag[@state='fixed']">
	  <tr>
	    <th>Fixed in:</th>
	    <td>
	      <xsl:call-template name="gittag">
		<xsl:with-param name="repository" select="$repository"/>
		<xsl:with-param name="tag" select="."/>
	      </xsl:call-template>
	    </td>
	  </tr>
	</xsl:for-each>
	<xsl:for-each select="lsn:change[@state='vulnerable']">
	  <tr>
	    <th>Broken by:</th>
	    <td>
	      <xsl:call-template name="gitchange">
		<xsl:with-param name="repository" select="$repository"/>
		<xsl:with-param name="change" select="."/>
	      </xsl:call-template>
	    </td>
	  </tr>
	</xsl:for-each>
	<xsl:for-each select="lsn:change[@state='fixed']">
	  <tr>
	    <th>Fixed by:</th>
	    <td>
	      <xsl:call-template name="gitchange">
		<xsl:with-param name="repository" select="$repository"/>
		<xsl:with-param name="change" select="."/>
	      </xsl:call-template>
	    </td>
	  </tr>
	</xsl:for-each>
      </table>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
