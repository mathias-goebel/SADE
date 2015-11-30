xquery version "3.0";
module namespace mviewer = "http://sade/multiviewer" ;
declare namespace templates="http://exist-db.org/xquery/templates";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace tgmd="http://textgrid.info/namespaces/metadata/core/2010";

import module namespace config="http://exist-db.org/xquery/apps/config" at "../../core/config.xqm";
import module namespace md="http://exist-db.org/xquery/markdown" at "/apps/markdown/content/markdown.xql";
import module namespace dsk-view="http://semtonotes.github.io/SemToNotes/dsk-view"
  at './SemToNotes.xqm';
import module namespace fontaneTransfo="http://fontane-nb.dariah.eu/Transfo"
  at './fontane.xqm';
import module namespace fontaneSfEx="http://fontane-nb.dariah.eu/SfEx"
  at './fontane-surfaceExtract.xqm';
  
import module namespace console="http://exist-db.org/xquery/console";

declare function mviewer:show($node as node(), $model as map(*), $id as xs:string) as item()* {

    let $data-dir := config:param-value($model, 'data-dir')
    let $docpath := if(tokenize($id, '.')[3]) 
                    then $data-dir || '/' || $id 
                    else $data-dir || '/' || $id
(: collection('/db/sade-projects/textgrid/data/xml/meta/')//tgmd:textgridUri[following::tgmd:revision[1]/number(string()) = max( collection('/db/sade-projects/textgrid/data/xml/meta/')//tgmd:revision[preceding::tgmd:textgridUri/starts-with(substring-after(., 'textgrid:'), tokenize($id, '.')[1])]/number(string(.)) )]/substring-after(., 'textgrid:') || '.xml' :)
    let $authstr := config:param-value($model, 'secret')
    let $auth:= if (request:get-cookie-value('fontaneAuth') != $authstr and request:get-parameter('authstr', '') = $authstr) then  response:set-cookie('fontaneAuth', $authstr) else ''

    return
        switch(tokenize($id, "\.")[last()])
            case "xml"
            return
                if (request:get-cookie-value('fontaneAuth') = $authstr or  request:get-parameter('authstr', '') = $authstr) then
                    if (contains($id, '/tile/')) then mviewer:renderTILE($node, $model, $docpath)
                    else
                    mviewer:renderXml($node, $model, $docpath)
                else
                    <div class="container FontaneAuth">
                    <div class="row">
                        <form class="form" method="get">
                            <div class="col-xs-10">
                                <input name="authstr" type="password" id="authstr" class="form-control" placeholder="Passwort"/>
                            </div>
                            <input type="hidden" name="id" value="{request:get-parameter('id', '')}" />
                            <button type="submit" class="btn btn-dark" onclick="createCookie('fontaneAuth', document.getElementById('authstr').value ,140)">Send</button>
                        </form>
                        </div>
                    </div>
            case "md"
                return if ($id='startseite.md') then mviewer:renderMarkdown($node, $model, $docpath) else <div class="container">{mviewer:renderMarkdown($node, $model, $docpath)}</div>
            case "html"
                return doc($docpath)
            default
                return mviewer:renderXml($node, $model, $docpath)
};

declare function mviewer:renderMarkdown($node as node(), $model as map(*), $docpath as xs:string) as item()* {
    
    let $inputDoc := util:binary-doc( $docpath )
    let $input := util:binary-to-string($inputDoc)
    return
        <div class="markdown">
        {md:parse($input)}
            <script type="text/javascript" src="$shared/resources/scripts/jquery/jquery-1.7.1.min.js"/>
        <script type="text/javascript" src="$shared/resources/scripts/ace/ace.js"/>
        <script type="text/javascript" src="$shared/resources/scripts/ace/mode-javascript.js"/>
        <script type="text/javascript" src="$shared/resources/scripts/ace/mode-text.js"/>
        <script type="text/javascript" src="$shared/resources/scripts/ace/mode-xquery.js"/>
        <script type="text/javascript" src="$shared/resources/scripts/ace/mode-java.js"/>
        <script type="text/javascript" src="$shared/resources/scripts/ace/mode-css.js"/>
        <script type="text/javascript" src="$shared/resources/scripts/ace/mode-xml.js"/>
        <script type="text/javascript" src="$shared/resources/scripts/ace/theme-clouds.js"/>
        <script type="text/javascript" src="$shared/resources/scripts/highlight.js"/>
        <script type="text/javascript">
            $(document).ready(function() {{
                $(".code").highlight({{theme: "clouds"}});
            }});
        </script>
        </div>
};

declare function mviewer:renderXml($node as node(), $model as map(*), $docpath as xs:string) as item()* {
let $doc := doc($docpath)
(:todo: if tei :)
(:    let $page := xs:integer(request:get-parameter("page", -1)):)
(:    let $doc := mviewer:tei-paging($doc, $page):)

let $tgurl := 'http://textgridlab.org/1.0/tgcrud/rest/textgrid:'
let $sid := 'gM8eogFsgESvZmqEYiJMFNRWipcV7K6DMlU62fBt5BEG5kVtWxDCx1Gy1434546037956017'
let $baseuri := substring-before(substring-before(substring-after(request:get-parameter('id', ''), '/xml/data/'), '.'), '.')
let $uri := substring-before(substring-after(request:get-parameter('id', ''), '/xml/data/'), '.')

let $page := if(request:get-parameter-names() = 'page') then if(request:get-parameter('page', '') = '') then 'outer_front_cover' else request:get-parameter('page', '') else ''
let $html :=  
    if ( (request:get-parameter('test', '') = '1') and ($page = '') )
    then (: test if we can use a cached html :)

        let $datacol := substring-before($docpath, '/xml/data/') || '/xml'
        let $dbDocName := substring-after($docpath, 'xml/data/')
        let $dbDocNameXhtml := replace($dbDocName, 'xml', 'xhtml')
        let $metadata := xs:dateTime(doc($tgurl|| $uri ||'/metadata?sessionId='|| $sid)//tgmd:lastModified)
        let $lastChangeXhtml := 
                    if  ( doc-available($datacol||'/xhtml/' || $dbDocNameXhtml) ) 
                    then( xmldb:last-modified('/db/sade-projects/textgrid/data/xml/xhtml', $dbDocNameXhtml) )
                    else( xs:dateTime('2005-09-28T21:38:18.089+02:00') )
        let $lastChangeProcessing := xmldb:last-modified('/db/apps/SADE/modules/multiviewer','fontane.xqm')
        return
            if($metadata gt $lastChangeXhtml or $lastChangeProcessing gt $lastChangeXhtml) 
            then (let $transfo := fontaneTransfo:magic(doc($tgurl|| substring-before(substring-after(request:get-parameter('id', ''), '/xml/data/'), '.') ||'/data?sessionId='||$sid)/tei:TEI)
                let $store := (
                    xmldb:login(substring-before($docpath, '/xml/data/') || '/xml/xhtml', config:param-value($model, 'sade.user'), config:param-value($model, 'sade.password')),
                    xmldb:store( substring-before($docpath, '/xml/data/') || '/xml/xhtml' , $dbDocNameXhtml, <xhtml:body>{$transfo}</xhtml:body>),
                    session:invalidate()
                    )
                return $transfo
)
            else doc('/db/sade-projects/textgrid/data/xml/xhtml/'||$dbDocNameXhtml)//xhtml:body/*
    else
        if ( (request:get-parameter('test', '') = '1') and ($page != '') )
        then
            let $id := request:get-parameter('id', '')
            let $id := if (contains($id, '/')) then $id else replace($id, '%2F', '/')
            let $uri := tokenize( tokenize($id, '/')[last()], '\.')[1]
            let $tei := doc($tgurl|| $uri ||'/data?sessionId='|| $sid)/tei:TEI
            let $extract := fontaneSfEx:extract( $tei, $page )
            
            return fontaneTransfo:magic($extract)

    else  mviewer:choose-xsl-and-transform($doc, $model)

return
    if(local-name($html[1]) = "html") then
        <div class="teiXsltView">{$html//xhtml:div[@id='sourceDoc']}</div>
    else
        <div class="teiXsltView">{$html}</div>
};
declare function mviewer:renderTILE($node as node(), $model as map(*), $docpath as xs:string) as item()* {
let $doc := doc($docpath)
let $i := $doc//tei:link[starts-with(@targets, '#shape')][1]
let $shape := substring-before(substring-after($i/@targets, '#'), ' ')
let $teiuri :=  if(contains(substring-before(substring-after($i/@targets, $shape || ' textgrid:'), '#a'), '.'))
                                then substring-before(substring-after($i/@targets, $shape || ' textgrid:'), '#a')
                                else 
                                    (: todo: find lates revision in collection :)
                                    substring-before(substring-after($i/@targets, $shape || ' textgrid:'), '#a') || '.0'
let $imageuri := $doc//svg:image[following::svg:rect/@id eq $shape]/string(@xlink:href),
    $imgwidth := $doc//svg:image/@width/number()

let $teidoc := doc(substring-before($docpath, 'tile') || 'data/' || $teiuri || '.xml')/*
let $html := dsk-view:render($teidoc, $imageuri, $imgwidth, $docpath)//xhtml:body/*

return <div id="stn">
   {$html}
    </div>
};

declare function mviewer:renderTILEold($node as node(), $model as map(*), $docpath as xs:string) as item()* {
    let $sid := doc(config:param-value($model, 'textgrid.webauth') || '?authZinstance='|| config:param-value($model, 'textgrid.authZinstance') || '&amp;loginname=' || config:param-value($model, 'textgrid.user') || '&amp;password=' || config:param-value($model, 'textgrid.password'))//xhtml:meta[@name='rbac_sessionid']/string(@content),
        $doc := doc($docpath)
    return
        <div>
        <!-- Achtung: Bootstrap! Hier wird nicht sauber zwischen Layout und Daten getrennt! -->
        <!-- TODO: Get Session ID from tgclient instead of $sid in this function -->
            {for $i in $doc//tei:link[starts-with(@targets, '#shape')]
                let $shape := substring-before(substring-after($i/@targets, '#'), ' '),
                    $teiuri :=  if(contains(substring-before(substring-after($i/@targets, $shape || ' textgrid:'), '#a'), '.'))
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
declare function mviewer:tei-paging($doc, $page as xs:integer) {
    
    let $doc := if ($page > 0 and ($doc//tei:pb)[$page]) then
            util:parse(util:get-fragment-between(($doc//tei:pb)[$page], ($doc//tei:pb)[$page+1], true(), true()))
            (: Kann das funktionieren, wenn page als integer übergeben wird? müsste man nicht tei:pb/@n auswerten? :)
        else
            $doc
            
    return $doc
    
};

declare function mviewer:choose-xsl-and-transform($doc, $model as map(*)) {
    
    let $namespace := namespace-uri($doc/*[1])
    let $xslconf := $model("config")//module[@key="multiviewer"]//stylesheet[@namespace=$namespace][1]

    let $xslloc := if ($xslconf/@local = "true") then
            config:param-value($model, "project-dir")|| "/" ||  $xslconf/@location
        else
            $xslconf/@location
    
    let $xsl := doc('/db/sade-projects/textgrid/data/xml/data/1vzvf.8.xml')
    let $html := transform:transform($doc, $xsl, $xslconf/parameters)
    
    return $html
};
