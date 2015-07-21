<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:estr="http://exslt.org/strings" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:teix="http://www.tei-c.org/ns/Examples" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:html="http://www.w3.org/1999/xhtml" xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0" xmlns:exsl="http://exslt.org/common" xmlns:rng="http://relaxng.org/ns/structure/1.0" xmlns:m="http://www.w3.org/1998/Math/MathML" xmlns:edate="http://exslt.org/dates-and-times" xmlns:fotex="http://www.tug.org/fotex" xmlns:XSL="http://www.w3.org/1999/XSL/Transform" extension-element-prefixes="exsl estr edate" exclude-result-prefixes="exsl edate a fo rng tei teix fotex m html" version="1.0">
    <xsl:output indent="yes" encoding="utf-8"/>
    <xsl:template match="XSL:stylesheet">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="XSL:*"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>