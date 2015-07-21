<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:iso="http://www.iso.org/ns/1.0" xmlns:fn="http://www.w3.org/2005/02/xpath-functions" xmlns:tbx="http://www.lisa.org/TBX-Specification.33.0.html" xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture" xmlns:cals="http://www.oasis-open.org/specs/tm9901" xmlns:mml="http://www.w3.org/1998/Math/MathML" xmlns:contypes="http://schemas.openxmlformats.org/package/2006/content-types" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:teix="http://www.tei-c.org/ns/Examples" xmlns:w10="urn:schemas-microsoft-com:office:word" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:html="http://www.w3.org/1999/xhtml" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math" xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:ve="http://schemas.openxmlformats.org/markup-compatibility/2006" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:teidocx="http://www.tei-c.org/ns/teidocx/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:dc="http://purl.org/dc/elements/1.1/" version="2.0" exclude-result-prefixes="cp ve o r m v wp w10 w wne mml tbx iso      tei a xs pic fn xsi dc dcterms dcmitype     contypes teidocx teix html cals">
    <xsl:template match="tei:seg[@rend='specChildModule']">
        <w:r>
            <w:rPr>
                <w:rStyle w:val="tei{local-name()}"/>
                <w:b/>
            </w:rPr>
            <w:t>
                <xsl:attribute name="xml:space">preserve</xsl:attribute>
                <xsl:text/>
            </w:t>
            <w:t>
                <xsl:attribute name="xml:space">preserve</xsl:attribute>
                <xsl:value-of select="."/>
            </w:t>
        </w:r>
    </xsl:template>
</xsl:stylesheet>