xquery version "3.0";
module namespace mviewer = "http://sade/multiviewer" ;
declare namespace templates="http://exist-db.org/xquery/templates";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace xlink="http://www.w3.org/1999/xlink";

import module namespace config="http://exist-db.org/xquery/apps/config" at "../../core/config.xqm";
import module namespace md="http://exist-db.org/xquery/markdown" at "/apps/markdown/content/markdown.xql";
import module namespace console="http://exist-db.org/xquery/console";

declare function mviewer:show($node as node(), $model as map(*), $id as xs:string) as item()* {

    let $data-dir := config:param-value($model, 'data-dir')
    let $docpath := $data-dir || '/' || $id

    return
        switch(tokenize($id, "\.")[last()])
            case "xml"
            return
                if (contains($id, '/tile/')) then mviewer:renderTILE($node, $model, $docpath)
                else
                mviewer:renderXml($node, $model, $docpath)
            case "md"
                return mviewer:renderMarkdown($node, $model, $docpath)
            case "html"
                return doc($docpath)
            default
                return mviewer:renderXml($node, $model, $docpath)
};

declare function mviewer:renderMarkdown($node as node(), $model as map(*), $docpath as xs:string) as item()* {
    
    let $inputDoc := util:binary-doc( $docpath )
    let $input := util:binary-to-string($inputDoc)
    return
        <div class="container">
            <div class="row">
                <div class="col-md-12">
                    {md:parse($input)}
                </div>
            </div>
        </div>
};

declare function mviewer:renderXml($node as node(), $model as map(*), $docpath as xs:string) as item()* {

    let $doc := doc($docpath)
    
    (:todo: if tei :)
    let $page := request:get-parameter("page", '')
    let $doc := mviewer:tei-paging($doc, $page)

    let $html := mviewer:choose-xsl-and-transform($doc, $model)

    let $toc := 
    <ul id="toc">
    {for $i in doc($docpath)//tei:sourceDoc/tei:surface/@n
        return
            <li>
                <a href="#{$i}">{string($i)}</a>; &#160; <a href="{request:get-uri()||'?id='||request:get-parameter('id', '')||'&amp;page='||$i}"><i class="fa fa-file-text-o"></i></a>
            </li>
    }
    </ul>            
    
    return 
            <div><div class="section-header">
                <div class="container">
                    <div class="row">
                        <div class="col-xs-2">
                        <h1 class="animated slideInLeft">
                        <span class="inactive">
                        <i class="fa fa-picture-o"></i>&#160;<span class="visible-lg">Faksimiles</span>
                        </span>
                        </h1>
                        </div>
                        <div class="col-xs-2">
                        <h1 class="animated slideInLeft"><span class="{if(contains(request:get-uri(), 'content2.html')) then 'inactive' else ''}"><i class="fa fa-pencil-square-o"></i>&#160;<span class="visible-lg">Transkription</span></span>
                            </h1>
                        </div>
                        <div class="col-xs-2">
                        <h1 class="animated slideInLeft"><span class="{if(contains(request:get-uri(), 'content2.html')) then '' else 'inactive'}"><i class="fa fa-align-justify"></i>&#160;<span class="visible-lg">Edierter Text</span></span>
                            </h1>
                        </div>
                        <div class="col-xs-2">
                        <h1 class="animated slideInLeft"><span class="inactive"><i style="display:inline;" class="fa fa-comment-o"></i>&#160;<span class="visible-lg">Kommentar/Apparat</span></span>
                            </h1>
                        </div>
                        <div class="col-xs-2 pull-right">
                        <a href="/exist/rest{$docpath}"><h1 class="animated slideInRight"><span class="inactive"><i class="fa fa-code"></i>&#160;
<span class="visible-lg">XML</span></span>
                            </h1></a>
                        </div>
                    </div>
                </div>
            </div>
                
            <div class="teiXsltView row">
            
                <div class="col-md-9">
                    
                    {if(local-name($html[1]) = "html") then <div id="ediTex">{$html/xhtml:body}</div> else $html}</div>
                
                <div class="col-md-3 pull-right">
                <div class="panel panel-dark">
                    <div class="panel-heading">{doc($docpath)//tei:title[1]/string()}</div>
                    <div class="panel-body">
                <div class="panel-group" id="accordion">
                    <div class="panel panel-default">
                        <div class="panel-heading">
                          <h4 class="panel-title">
                            <a data-toggle="collapse" data-parent="#accordion" href="#collapseOne" class="collapsed">
                              <span class="caret"></span> Seiten (<code>//sourceDoc/surface/@n</code>)
                            </a>
                          </h4>
                        </div>
                        <div id="collapseOne" class="panel-collapse collapse" style="height: 0px;">
                            <div class="panel-body">
                                {$toc}
                            </div>
                        </div>
                    </div>
                    <div class="panel panel-default">
                        <div class="panel-heading">
                          <h4 class="panel-title">
                            <a data-toggle="collapse" data-parent="#accordion" href="#collapseTwo" class="collapsed">
                              <span class="caret"></span> Metadaten
                            </a>
                          </h4>
                        </div>
                        <div id="collapseTwo" class="panel-collapse collapse" style="height: auto;">
                            <div class="panel-body">
                                TODO: Welche Headerdaten?
                            </div>
                        </div>
                    </div>
                    <div class="panel panel-default">
                        <div class="panel-heading">
                          <h4 class="panel-title">
                            <a data-toggle="collapse" data-parent="#accordion" href="#collapseThree" class="collapsed">
                             <span class="caret"></span> Inhaltsverzeichnis
                            </a>
                          </h4>
                        </div>
                        <div id="collapseThree" class="panel-collapse collapse" style="height: 0px;">
                        <div class="panel-body">
                            TODO: aus TEI-Header
                        </div>
                    </div>
                    </div>
                    {if ($page != '') then
                        let $pages := doc($docpath)//tei:sourceDoc/tei:surface/string(@n)
                        return
                   
                    <ul class="pagination center-block">
                    {if (index-of($pages, $page) = 1) then ''
                    else <li><a href="{request:get-uri()||'?id='||request:get-parameter('id', '')||'&amp;page='||$pages[1]}">«</a></li>}
                    {if((index-of($pages, $page)-2) gt 0) then
                        <li class=""><a href="{request:get-uri()||'?id='||request:get-parameter('id', '')||'&amp;page='||$pages[index-of($pages, $page)-2]}">{$pages[(index-of($pages, $page))-2]}</a></li>
                        else ''}
                    {if((index-of($pages, $page)-1) gt 0) then
                        <li><a href="{request:get-uri()||'?id='||request:get-parameter('id', '')||'&amp;page='||$pages[(index-of($pages, $page))-1]}">{$pages[(index-of($pages, $page))-1]}</a></li>
                        else ''}
<!-- CURRENT PAGE --> <li class="active"><a href="#">{$pages[(index-of($pages, $page))]}</a></li>
                    {if((index-of($pages, $page)+1) lt index-of($pages, $pages[last()])) then    
                        <li><a href="{request:get-uri()||'?id='||request:get-parameter('id', '')||'&amp;page='||$pages[(index-of($pages, $page))+1]}">{$pages[(index-of($pages, $page))+1]}</a></li>
                        else ''}
                    {if((index-of($pages, $page)+1) lt index-of($pages, $pages[last()])) then    
                        <li><a href="{request:get-uri()||'?id='||request:get-parameter('id', '')||'&amp;page='||$pages[(index-of($pages, $page))+2]}">{$pages[(index-of($pages, $page))+2]}</a></li>
                        else ''}
                        <li><a href="{request:get-uri()||'?id='||request:get-parameter('id', '')||'&amp;page='||$pages[last()-1]}">»</a></li>
                    </ul>
                    else ''    
                    }
                </div>
                </div>
            </div>
            </div>
            </div>
                </div>
   
           
};

declare function mviewer:renderTILE($node as node(), $model as map(*), $docpath as xs:string) as item()* {
    let $sid := doc(config:param-value($model, 'textgrid.webauth') || '?authZinstance='|| config:param-value($model, 'textgrid.authZinstance') || '&amp;loginname=' || config:param-value($model, 'textgrid.user') || '&amp;password=' || config:param-value($model, 'textgrid.password'))//xhtml:meta[@name='rbac_sessionid']/string(@content),
        $doc := doc($docpath)
    return
        <div>
        <!-- Achtung: Bootstrap! Hier wird nicht sauber zwischen Layout und Daten getrennt! -->
        <!-- TODO: Get Session ID from tgclient instead of $sid in this function -->
            {for $i in $doc//tei:link[starts-with(@targets, '#shape')]
                let $shape := substring-before(substring-after($i/@targets, '#'), ' '),
                    $teiuri := 
                                if(contains(substring-before(substring-after($i/@targets, $shape || ' textgrid:'), '#a'), '.'))
                                then substring-before(substring-after($i/@targets, $shape || ' textgrid:'), '#a')
                                else 
                                    (: todo: find lates revision in collection :)
                                    substring-before(substring-after($i/@targets, $shape || ' textgrid:'), '#a') || '.0',
                    
                    $imageuri := $doc//svg:image[following::svg:rect/@id eq $shape]/string(@xlink:href),
                    $offset := '&amp;wx=' || number(substring-before($doc//svg:rect[@id eq $shape]/string(@x), '%')) div 100 || '&amp;wy=' || number(substring-before($doc//svg:rect[@id eq $shape]/string(@y), '%')) div 100,
                    $range := '&amp;ww=' || number(substring-before($doc//svg:rect[@id eq $shape]/string(@width), '%')) div 100 || '&amp;wh=' || number(substring-before($doc//svg:rect[@id eq $shape]/string(@height), '%')) div 100
                return
                    <div class="row">
                        <div class="col-md-6">
                            <img style="padding-top:10px" alt="detail" src="{config:param-value($model, 'textgrid.digilib') || '/'  || $imageuri};sid={$sid}?{config:param-value($model, 'textgrid.digilib.tile') || $range || $offset}" />
                        </div>
                        <div class="col-md-6">
                            {let    $data-dir := config:param-value($model, 'data-dir'),
                                    $docpath := $data-dir || '/xml/data/' || $teiuri || '.xml'
(:                                    TODO: Soll /xml/data/ aus config hervorgehen? :)
                            return
                                if (doc($docpath) != '')
                                then
                                    if(ends-with($i/@targets, 'end'))
                                    then 
                                        let $start := substring-after(substring-after(substring-before($i/string(@targets), '_start'), '#'), '#') || '_start',
                                            $end := substring-after(substring-after(substring-after(substring-before($i/string(@targets), '_end'), '#'), '#'), '#') || '_end'                                        return mviewer:choose-xsl-and-transform((util:parse(util:get-fragment-between(doc($docpath)//tei:anchor[@xml:id = $start], doc($docpath)//tei:anchor[@xml:id = $end], true(), true()))), $model)
                                    else 
                                        doc($docpath)//*[@xml:id = substring-after(substring-after($i/string(@targets), '#'), '#')]
                                else <span>The requested document is not available. Please resubmit/republish the object <b>{$teiuri}</b>.</span>
                            }
                        </div>
                    </div>
            }
            <br/>
            <div class="row">
                <button type="button" class="btn btn-info" data-toggle="collapse" data-target="#tile">show TILE-Object</button>
                <div id="tile" class="collapse out"><pre>{serialize($doc)}</pre></div>
            </div>
        </div>
};

(: TODO: tei-specific :)
declare function mviewer:tei-paging($doc, $page as xs:string) {
    
let $doc :=
    if ($page = '') then $doc
    else if (number($page) > 0 and ($doc//tei:pb)[$page]) then
        util:parse(util:get-fragment-between(($doc//tei:pb)[$page], ($doc//tei:pb)[$page+1], true(), true()))
        (: Kann das funktionieren, wenn page als integer übergeben wird? müsste man nicht tei:pb/@n auswerten? :)
    else if ($page != '' and $doc//tei:surface/@n = tokenize($page, ',')[1]) then mviewer:fontane-rewrite($doc, $page)
    else
        $doc
        
    return $doc
    
};

declare function mviewer:choose-xsl-and-transform($doc, $model as map(*)) {
    
    let $namespace := namespace-uri($doc/*[1])
    let $xslconf := $model("config")//module[@key="multiviewer"][last()]//stylesheet[@namespace=$namespace][1]

    let $xslloc := if ($xslconf/@local = "true") then
            config:param-value($model, "project-dir")|| "/" ||  $xslconf/@location
        else
            $xslconf/@location
    
    let $xsl := doc($xslloc)
    let $html :=    try { transform:transform($doc, $xsl,
    <parameters>
        <param/>
    </parameters>) }
                    catch * {console:log(concat($err:code, ": ", $err:description))}

return
    if(contains(request:get-uri(), 'content2.html')) then
        (:  edierter Text wird hier erstellt :)
        mviewer:fontane-edi($doc, $model)
    else $html
};
declare function mviewer:fontane-edi($doc, $model){
    
let $xsl:= doc(config:param-value($model, "data-dir")|| "/xml/data/24h59.0.xml")
let $teip5 := transform:transform($doc, $xsl, ())

let $xsl:= doc('/db/sade-projects/textgrid/xslt/tei/stylesheet/xhtml2/tei.xsl')
let $html := transform:transform($teip5, $xsl, ())


return $html

};
declare function mviewer:fontane-rewrite($doc, $page){
(: rewrite the document with requested pages :)

let $page0 := tokenize($page, ',')[1]
let $newdoc := 
    <tei:TEI>
        {$doc//tei:teiHeader}
        <tei:sourceDoc>
            <tei:handShift
                medium="{$doc//tei:surface[@n = $page0]/preceding::tei:handShift[@medium][1]/@medium}"
                rendition="{$doc//tei:surface[@n = $page0]/preceding::tei:handShift[@rendition][1]/@rendition}"
                new="{$doc//tei:surface[@n = $page0]/preceding::tei:handShift[@new][1]/@new}"
                script="{$doc//tei:surface[@n = $page0]/preceding::tei:handShift[@script][1]/@script}"/>
            {for $p in tokenize($page, ',') return $doc//tei:surface[@n = $p]}
        </tei:sourceDoc>
    </tei:TEI>
return $newdoc
};
