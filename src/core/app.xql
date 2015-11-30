xquery version "3.0";
module namespace app="http://sade/app";

declare namespace ore="http://www.openarchives.org/ore/terms/"; 
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace tgmd="http://textgrid.info/namespaces/metadata/core/2010";
declare namespace digilib="digilib:digilib";
declare namespace xlink="http://www.w3.org/1999/xlink";

import module namespace console="http://exist-db.org/xquery/console";
import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace config-params="http://exist-db.org/xquery/apps/config-params" at "config.xql";

declare function app:stylesheets($node as node(), $model as map(*)) {
    if (request:get-parameter('lest', '') = '1')
    then <link rel="stylesheet" type="text/css" href="css/fontane.css"/>
    else ()
};

declare function app:eraseall($node as node(), $model as map(*)) {
let $check := request:get-parameter('check', '0')
return
if ($check != '1') then 'wrong parameter or parameter value' 
else
let $login := xmldb:login('/sade-projects/textgrid/data/xml/data',  'admin',  ''),

    $egal := xmldb:remove('/db/sade-projects/textgrid/data/xml/data'),
    $egal := xmldb:remove('/db/sade-projects/textgrid/data/xml/meta'),
    $egal := xmldb:remove('/db/sade-projects/textgrid/data/xml/tile'),
    $egal := xmldb:remove('/db/sade-projects/textgrid/data/xml/agg'),
    $egal := xmldb:create-collection('/db/sade-projects/textgrid/data/xml', 'data'),
    $egal := xmldb:create-collection('/db/sade-projects/textgrid/data/xml', 'meta'),
    $egal := xmldb:create-collection('/db/sade-projects/textgrid/data/xml', 'tile'),
    $egal := xmldb:create-collection('/db/sade-projects/textgrid/data/xml', 'agg'),
    $nav2 := <div class="row">
                <div class="span3">
                    <div class="well">
                        <div id="nav-textgrid">
                            <ul class="nav nav-list">
                                <li>
                                    <label class="tree-toggle nav-header">
                                        <a href="index.html">Home</a>
                                    </label>
                                </li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>,
    $egal := xmldb:store('/db/sade-projects/textgrid/', 'navigation-bootstrap3.xml', $nav2 ,  'text/xml'),
    $egal := xmldb:store('/db/sade-projects/textgrid/', 'navigation-tg.xml', <navigation/> ,  'text/xml')

return 'ok'
};

(:
declare 
    %templates:wrap
function app:init($node as node(), $model as map(*), $project as xs:string?) {
        let $project-config-path := concat($config:projects-dir, $project, "/config.xml")
        let $project-resolved := if (doc-available($project-config-path)) then $project else "no such project"
        let $project-config := if (doc-available($project-config-path)) then doc($project-config-path) else ()
        return map { "config" := $project-config 
        }
:)
(:   <p>{$project}</p>:)
 
        (:    <p>exist:root {request:get-attribute("$exist:root")}<br/>
        exist:resource {request:get-attribute("$exist:resource")}<br/>
        exist:path {request:get-attribute("$exist:path")}<br/>
        exist:controller {request:get-attribute("$exist:controller")}<br/>
        exist:prefix {request:get-attribute("$exist:prefix")}<br/>
        get-uri {request:get-uri()}<br/>
        config:app-root {$config:app-root}<br/>
        
</p>
};:)

declare 
    %templates:wrap
function app:title($node as node(), $model as map(*)) {
(:    $model("config")//param[xs:string(@key)='project-title']:)
config:param-value($model, 'project-title')

};
declare 
    %templates:wrap
function app:project-id($node as node(), $model as map(*)) {
<div data-target=".sidebar-collapse" data-toggle="collapse" id="sidebar-toggle">
<span class="glyphicon glyphicon-list"> </span> {' ' || config:param-value($model, 'project-title')}
</div>
};
declare 
    %templates:wrap
function app:logo($node as node(), $model as map(*)) {

    let $logo-image := config:param-value($model, 'logo-image')
    let $logo-link := config:param-value($model, 'logo-link')
    
    return <a href="{$logo-link}" target="_blank">
                    <img src="{$logo-image}" class="logo right"/>
                </a>
           
};

declare 
    %templates:wrap
    %templates:default("filter", "")
function app:list-projects($node as node(), $model as map(*), $filter as xs:string) {

    let $filter-seq:= tokenize($filter,',')
    let  $projects := if ($filter='') then config:list-projects()
                        else $filter-seq
    
    (: get the absolute path to controller, for the image-urls :)
    let $exist-controller := config:param-value($model, 'exist-controller')
    let $request-uri:= config:param-value($model, 'request-uri')
    let $base-uri:= if (contains($request-uri,$exist-controller)) then 
                        concat(substring-before($request-uri,$exist-controller),$exist-controller)
                      else $request-uri
    
    for $pid in $projects
    
                    let $config-map := map { "config" := config:project-config($pid)}
                    (: try to get the base-project (could be different then the current $project-id for the only-config-projects :) 
                    let $config-dir := substring-after(config:param-value($config-map, 'project-dir'),$config-params:projects-dir)
                    let $visibility := config:param-value($config-map, 'visibility')                 
                    let $title := config:param-value($config-map, 'project-title')
                    let $link := if (config:param-value($config-map, 'project-url')!='') then
                                        config:param-value($config-map, 'project-url')
                                        else  concat($base-uri, '/', $pid, '/index.html')
                    let $teaser-image :=  concat($base-uri, '/', $config-dir, config:param-value($config-map, 'teaser-image'))
                    let $teaser-text:= if (config:param-value($config-map, 'teaser-text')!='') then
                                            config:param-value($config-map, 'teaser-text')
                                        else
(:                                        welcome message as fallback for teaser:)
                                            let $teaser := collection(config:param-value($config-map, 'project-static-dir'))//*[xs:string(@id)= 'teaser'][1]/p
                                            let $welcome := collection(config:param-value($config-map, 'project-static-dir'))//*[xs:string(@id)='welcome'][1]/p
                                            return if ($teaser) then $teaser else $welcome
                                                                                    
                                          
                    
(:                                let $teaser := config:param-value($config-map, 'teaser'):)
                    return if ($visibility != 'private') then <div class="teaser" xmlns="http://www.w3.org/1999/xhtml"><img class="teaser" src="{$teaser-image}" /> <h3><a href="{$link}" >{$title}</a></h3>
                                     {$teaser-text}
                            </div> else ()

(:    return $projects:)
};

(: FONTANE STUFF :)
declare 
    %templates:wrap
function app:cite($node as node(), $model as map(*)) {
<span>
      <a href="#" data-toggle="modal" data-target="#sendemail">Zitationsempfehlung</a> 
                <!-- Modal window: -->
                <div class="modal fade" id="sendemail" tabindex="-1" role="dialog" aria-labelledby="citationrecommendation" aria-hidden="true">
                  <div class="modal-dialog">
                    <div class="modal-content">
                      <div class="modal-header">
                        <button type="button" class="close" data-dismiss="modal" aria-hidden="true"><i class="fa fa-times"></i></button>
                        <h4 class="modal-title">Zitationsempfehlung</h4>
                        <div class="clearfix"></div>
                      </div>
                      <div class="modal-body">
                        
                        Theodor Fontane: Notizbücher. Hrsg. von Gabriele Radecke.<br/>
                        {replace(request:get-url(), 'localhost:8080/exist/apps/SADE/textgrid', 'fontane-nb.dariah.eu') ||(if (request:get-query-string()) then '?' || request:get-query-string() else '')}<br/>
                        abgerufen am: {day-from-date(current-date())}. {month-from-date(current-date())}. {year-from-date(current-date())}
                      </div>
                    </div><!-- /.modal-content -->
                  </div><!-- /.modal-dialog -->
                </div><!-- /.modal -->
                <!-- End of modal window -->
</span>
};

declare function app:kaesten($node as node(), $model as map(*)){
    let $q := request:get-parameter('n', '')
return
    
    (<ul class="nav nav-tabs">
        {for $kasten in (('a', 'b', 'c', 'd', 'e'))
        return
            if ($q = $kasten)
            then 
                <li class="active">
                    <a href="#{$kasten}" data-toggle="tab">Kasten {upper-case($kasten)}</a>
                </li>
            else 
                <li>
                    <a href="#{$kasten}" data-toggle="tab">Kasten {upper-case($kasten)}</a>
                </li>
        }
    </ul>,
    <div class="tab-content">
    {
        for $kasten in (('a', 'b', 'c', 'd', 'e'))
            return
                if ($q = $kasten)
            then 
        <div class="tab-pane active" id="{$kasten}">
            <div class="panel-group" id="accordion{upper-case($kasten)}" role="tablist" aria-multiselectable="true">    
                    {app:list(config:param-value($model, 'data-dir') || '/xml/meta', upper-case($kasten))}
            </div>
        </div>
        else 
        <div class="tab-pane" id="{$kasten}">
            <div class="panel-group" id="accordion{upper-case($kasten)}" role="tablist" aria-multiselectable="true">    
                {app:list(config:param-value($model, 'data-dir') || '/xml/meta', upper-case($kasten))}
            </div>
        </div>
    }
    </div>)
};
declare function app:list($datadir, $param) {
    let $tgnav:= doc('/db/sade-projects/textgrid/navigation-fontane.xml')

    for $item at $pos in distinct-values($tgnav//object[@type="text/xml"][starts-with(@title, 'Notizbuch ' || $param)]/@title)
    let $maxRev:=  max($tgnav//object[@title = $item]/number(substring-after(@uri, '.'))),
    $uri:= $tgnav//object[@title = $item][number(substring-after(@uri, '.')) = $maxRev]/substring-after(@uri, 'textgrid:')
    return
        <div class="panel panel-dark">
                    <div class="panel-heading" role="tab" id="heading{$param||$pos}">
                      <h3 class="panel-title">
                      <a role="button" data-toggle="collapse" data-parent="#accordion{$param}" href="#collapse{$param||$pos}" aria-expanded="false" aria-controls="collapse{$param||$pos}">
                      { if (matches($item, '0\d')) then replace($item, '0', '') else $item }
                        </a>  
                      </h3>
                      
                    </div>
                    <div id="collapse{$param||$pos}" class="panel-collapse collapse" role="tabpanel" aria-labelledby="heading{$param||$pos}">
                    <div class="panel-body">
                    <div class="row">
                        <div class="col-md-9">
                              uri: {$uri[last()]}<br/>
                              Revision: {$maxRev}<br/>
                              <a href="content.html?id=/xml/data/{$uri[last()]}.xml">content.html</a><br/>
                              <a href="content2.html?id=/xml/data/{$uri[last()]}.xml">content2.html</a><br/>
                              <a href="content2.html?id=/xml/data/{$uri[last()]}.xml&amp;test=1">TextGridLab</a>
                              <span style="margin-left:20px;"/>
                                <form style="display:inline;" action="content2.html" metod="get">
                                    <input type="hidden" name="id" value="/xml/data/{$uri[last()]}.xml"/>
                                    <input type="hidden" name="test" value="1"/>
                                    <input name="page" type="text" style="width: 40px;border: none;" placeholder="1r"/>
                                </form>
                              <br/>
                                <ul>
                                    <li>Digitalisate</li>
                                    <li>Transkriptionsansicht</li>
                                    <li>Edierter Text/Textkritischer Apparat</li>
                                    <li>TEI/XML-Ansicht</li>
                                    <li>Kommentare und Register
                                        <ul>
                                            <li>Überblickskommentar</li>
                                            <li>Stellenkommentar</li>
                                            <li>Register
                                                <ul>
                                                    <li>Register der Personen und Werke</li>
                                                    <li>Register der Werke</li>
                                                    <li>Register der Werke Theodor Fontanes</li>
                                                    <li>Register der Periodika</li>
                                                    <li>Geographisches Register</li>
                                                    <li>Register der Ereignisse</li>
                                                    <li>Register der Institutionen und Körperschaften</li>
                                                </ul>
                                            </li>
                                            
                                        </ul>
                                    </li>
                                    <li>Inhaltsverzeichnis</li>
                                    
                                </ul>
                        </div>
                        <div class="col-md-3">
                            <div id="thumb">
                                <img src="/digilib/{substring-after($item, ' ')}_001.jpg?dh=350&amp;mo=png"/>
                            </div>
                        </div>
                    </div>
                    </div>
                    </div>
                  </div>
};

(: Synch with TFA-Homepage: :)
declare function app:publications($node as node(), $model as map(*)) {
httpclient:get(xs:anyURI('http://www.uni-goettingen.de/de/publikationen/303721.html'), true(), ())//ul[@class="txtlist"][1]/li[position() < 4]
};

declare function app:presentations($node as node(), $model as map(*)) {
httpclient:get(xs:anyURI('http://www.uni-goettingen.de/de/vortr%C3%A4ge-und-pr%C3%A4sentationen/303717.html'), true(), ())//ul[@class="txtlist"][1]/li[position() < 5]
};

declare function app:countdown($node as node(), $model as map(*)) {
let $target := xs:dateTime('2015-11-15T12:00:00.000+02:00')
let $duration := $target - current-dateTime()
return
    <ul>
      <li class="chart" data-percent="{ days-from-duration($duration) div 200 * 100 }"><span>{ days-from-duration($duration) }</span>Tage</li>
      <li class="chart" data-percent="{ hours-from-duration($duration) div 24 * 100 }"><span>{ hours-from-duration($duration) }</span>Stunden</li>
      <li class="chart" data-percent="{ minutes-from-duration($duration) div 60 * 100 }"><span>{ minutes-from-duration($duration) }</span>Minuten</li>
    </ul>
};
declare function app:tble($node as node(), $model as map(*)) {
let $coll := '/db/sade-projects/textgrid/data/xml/tile'
let $owners := for $object in xmldb:get-child-resources($coll)
                return
                    for $owner in xmldb:get-owner($coll, $object)
                    return
                        ($owner)
let $user := request:get-parameter('u', 'x')
let $polygon := request:get-parameter('polygon', 'x')

(:let $user := if($user = '' or $user = ()) then 'x' else $user:)
(:let $polygon := if($polygon = '' or $polygon = ()) then 'x' else $polygon:)

return
    if ($polygon = 'x') then
        if (string-length($user) lt 2) then
        <div>
            Bitte Nutzer auswählen:
            <ul>
                {for $i in distinct-values($owners)
                order by $i
                return (<li><a href="?u={$i}">{$i}</a></li>, console:log($i))
                }
            </ul>
        </div>
        else 
            <div>
            {for $res in xmldb:get-child-resources($coll)
            where xmldb:get-owner($coll, $res) = $user
            order by $res
            return
                <p><a href="?polygon={$res}">{$res}</a></p>
            }
        </div>
    else
        let $tile := doc($coll || '/' || $polygon)
        let $seq := tokenize($tile//svg:polygon/@points, ' ')
        let $ulx := min(for $point in $seq return number(substring-before($point, '%,')) div 100)
        let $uly := min(for $point in $seq return number(substring-before(substring-after($point, '%,'), '%')) div 100)
        let $lrx := max(for $point in $seq return number(substring-before($point, '%,')) div 100) - $ulx
        let $lry := max(for $point in $seq return number(substring-before(substring-after($point, '%,'), '%')) div 100) - $uly
        let $image := $tile//svg:image/@xlink:href
        let $imageW := $tile//svg:image/@width
        let $imageH := $tile//svg:image/@height
        let $dh := round($imageH * $lry)
        
        let $target := substring-before(substring-after($tile//tei:link[1]/@targets, 'textgrid:'), '#')
        let $tei:= doc( substring-before($coll, 'tile') || 'data/' || $target )
        let $rectX := number(replace($tile//svg:rect/@x, '%', '')) div 100 * $imageW
        let $rectY := number(replace($tile//svg:rect/@y, '%', '')) div 100 * $imageH
        
        let $points := for $item in $seq
                        let $item := replace($item, '%', '')
                        let $x := ((number(tokenize($item, ',')[1]) div 100) * $imageW - $rectX) div 236
                        let $y := ((number(tokenize($item, ',')[2]) div 100) * $imageH - $rectY) div 236
                        return
                            $x||','||$y||' '
        let $pattern := '##.0'
        let $dpcm := 236
        let $pointsRound := for $item in $seq
                let $item := replace($item, '%', '')
                let $x := ((number(tokenize($item, ',')[1]) div 100) * $imageW - $rectX) div $dpcm
                let $y := ((number(tokenize($item, ',')[2]) div 100) * $imageH - $rectY) div $dpcm
                return
                    format-number(round($x * 10) div 10, $pattern)||','||format-number(round($y * 10) div 10, $pattern)
        let $join := string-join(for $i in $pointsRound return replace(replace($i, '\.,', '.0,'), '\.$', '.0'), ' ')
        let $join := if(matches($join, ',\d+$')) then $join || '.0' else $join
        return
            (<img id="tbleImage" src="/digilib/{$image}?dh={$dh}&amp;wx={$ulx}&amp;wy={$uly}&amp;ww={$lrx}&amp;wh={$lry}&amp;mo=png"/>,
            <p id="coordinates"/>,
            <p id="margin"/>,
            <br/>,
            <h3>Berechnet</h3>,
            <p>points="{$points}"</p>,
            <h3>Gerundet</h3>,
            <p>points="{$join}"</p>)
};
declare function app:pageNav($node as node(), $model as map(*), $id){
if(request:get-parameter-names() = 'page') 
    then
        let $page := if(request:get-parameter('page', '') = '') then 'outer_front_cover' else request:get-parameter('page', '')
        let $doc:= doc('/db/sade-projects/textgrid/data'||$id)/tei:TEI
        let $page := if ($page = '') then 'outer_front_cover' else $page
        return
        (
            (
            if ( $doc//tei:surface[@n=$page]/preceding-sibling::tei:surface )
            then
            <a id="navPrev" href="/content2.html?test=1&amp;id={$id}&amp;page={$doc//tei:surface[@n=$page]/preceding-sibling::tei:surface[1]/string(@n)}">
                <i class="fa fa-chevron-left"></i>
            </a> else ()
            )
            ,
            (
            if ( 
                $doc//tei:surface[@n=$page]/following-sibling::tei:surface )
            then
            <a id="navNext" href="/content2.html?test=1&amp;id={$id}&amp;page={$doc//tei:surface[@n=$page]/following-sibling::tei:surface[1]/string(@n)}">
                <i class="fa fa-chevron-right"></i>
            </a>
            else ()
            ),
            element script {
                '$(document).keyup(function(e){
                    var next = jQuery.isEmptyObject( $("#navNext").attr("href") );
                    var prev = jQuery.isEmptyObject( $("#navPrev").attr("href") );
                    if ( (e.keyCode == 37) &amp;&amp; prev == false ) 
                        {location.href = $( "#navPrev" ).attr("href"); }
                    else if (e.keyCode == 39 &amp;&amp; next == false )
                     {location.href = $( "#navNext" ).attr("href"); }
                });'
            }
        )
else ()
};
declare function app:register($node as node(), $model as map(*)){
let $metacol := collection('/db/sade-projects/textgrid/data/xml/meta/')

for $item in doc('/db/sade-projects/textgrid/data/xml/agg/253st.0.xml')//ore:aggregates/string(@rdf:resource)
    let $uri := $item || '.' || local:getLatestRev($item)
    let $doc := doc('/db/sade-projects/textgrid/data/xml/data/'||substring-after($uri, 'textgrid:')||'.xml')
return
<ul>{
    for $p in $doc//(tei:person | tei:persGrp)
    return
    <li>{if($p//tei:persName) then ($p//tei:persName)[1] else ('xml:id '||string($p/@xml:id))}
        <ul>
            {for $idno in $p//tei:idno 
            return
                <li>{string($idno/@type)}: {$idno/string()}{if ($idno/@xml:base) then <a target="_blank" href="{$idno/@xml:base || $idno/string()}"><i class="fa fa-external-link"></i></a> else ()}</li>}
        </ul>
        <ul>
        {if ($p//tei:linkGrp/@targFunc="active passive") 
        then 
            for $link in $p//tei:linkGrp[@targFunc="active passive"]/tei:link/string(@target)
            return
                <li>
                {
                let $baseuri := substring-before(substring-after($link, 'http://textgridrep.org/'), '#xpath') 
                let $surface := substring-before(substring-after($link, "surface[@n='"), "']//")
                let $rev := local:getLatestRev($baseuri)
                let $meta := doc('/db/sade-projects/textgrid/data/xml/meta/' || substring-after($baseuri, 'textgrid:') ||'.'|| $rev|| '.xml')
                return 
                    <a href="content2.html?test=1&amp;id=/xml/data/{substring-after($baseuri, 'textgrid:') ||'.'|| $rev|| '.xml'}&amp;page={$surface}">{
                    $meta//tgmd:title/string(.) || ' (' || $surface || ')'
                    }</a>
                } 
                </li>
        else ()}
        </ul>
    </li>
}</ul>
    
};

declare function local:getLatestRev($uri as xs:string){
let $uri := if(contains($uri, '.')) then substring-before($uri, '.') else $uri
let $uri := if(starts-with($uri, 'textgrid:')) then $uri else 'textgrid:'||$uri
let $metacol := collection('/db/sade-projects/textgrid/data/xml/meta/')//tgmd:object[descendant::tgmd:textgridUri/starts-with(., $uri)]
return
    max($metacol//tgmd:revision)
};