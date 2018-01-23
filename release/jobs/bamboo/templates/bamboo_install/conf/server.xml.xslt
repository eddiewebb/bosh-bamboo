<?xml version="1.0" encoding="utf-8"?>
<!-- since much of this file might change release to release we use xslt to inject what should be
relatively consistent, using all other values as provide by install -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" encoding="utf-8" indent="yes"/>
  <xsl:strip-space elements="*"/>

  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="Server/Service/Connector">
    <Connector
        protocol="HTTP/1.1"
        port="<%= p("server.port") %>"

        maxThreads="150"
        minSpareThreads="25"
        connectionTimeout="20000"
        disableUploadTimeout="true"
        acceptCount="100"

        enableLookups="false"
        maxHttpHeaderSize="8192"

        useBodyEncodingForURI="true"
        URIEncoding="UTF-8"

        redirectPort="8443"
        />
  </xsl:template>


  <xsl:template match="Context">

    <Context path="<% if_p('server.context') do |value| %><%= value %><% end %>" docBase="${{catalina.home}}/atlassian-bamboo" reloadable="false" useHttpOnly="true">
      <Manager pathname=""/>
    </Context>
  </xsl:template>
</xsl:stylesheet>
