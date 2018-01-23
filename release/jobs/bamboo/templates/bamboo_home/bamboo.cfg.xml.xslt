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

  <xsl:template match="properties">
    <properties>
      <!-- copy everything not specified below -->
      <xsl:copy-of select="./property[
            not(@name='hibernate.connection.datasource') and
            not(@name='hibernate.c3p0.acquire_increment') and
            not(@name='hibernate.c3p0.idle_test_period') and
            not(@name='hibernate.c3p0.min_size') and
            not(@name='hibernate.c3p0.max_size') and
            not(@name='hibernate.c3p0.max_statements') and
            not(@name='hibernate.c3p0.timeout') and
            not(@name='hibernate.connection.driver_class') and
            not(@name='hibernate.connection.url') and
            not(@name='hibernate.connection.username') and
            not(@name='hibernate.connection.password') and
            not(@name='hibernate.connection.dialect') and
            not(@name='bamboo.jms.broker.client.uri') and
            not(@name='license.string')  ]"/>

      <property name="hibernate.c3p0.acquire_increment">3</property>
      <property name="hibernate.c3p0.idle_test_period">30</property>
      <property name="hibernate.c3p0.min_size">20</property>
      <property name="hibernate.c3p0.max_size">500</property>
      <property name="hibernate.c3p0.max_statements">0</property>
      <property name="hibernate.c3p0.timeout">120</property>
      <property name="hibernate.connection.driver_class">org.postgresql.Driver</property>
      <property name="hibernate.connection.username">bamboo</property>
      <property name="hibernate.connection.password">password</property>
      <property name="hibernate.connection.url">jdbc:postgresql://<%= link('data-db').instances[0].address %>:<%= link('data-db').p('databases.port') %>/bamboo</property>
      <property name="hibernate.dialect">org.hibernate.dialect.PostgreSQLDialect</property>
      <property name="bamboo.jms.broker.client.uri">failover:(tcp://<%= spec.ip %>:54663?wireFormat.maxInactivityDuration=300000)?initialReconnectDelay=15000&amp;maxReconnectAttempts=10</property>
      <property name="license.string"><%= p("bamboo.license") %></property>
    </properties>
  </xsl:template>
</xsl:stylesheet>
