xquery version "3.0";
module namespace app="http://sade/app";
declare namespace tgmd="http://textgrid.info/namespaces/metadata/core/2010";
declare namespace digilib="digilib:digilib";

import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace config-params="http://exist-db.org/xquery/apps/config-params" at "config.xql";

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
                    {app:list(config:param-value($model, 'data-dir') || '/xml/meta', upper-case($kasten))}
        </div>
        else 
            <div class="tab-pane" id="{$kasten}">
                    {app:list(config:param-value($model, 'data-dir') || '/xml/meta', upper-case($kasten))}
        </div>
    }
    </div>)
};
declare function app:list($datadir, $param) {
    let $tgnav:= doc('/db/sade-projects/textgrid/navigation-fontane.xml')

    for $item in distinct-values($tgnav//object[@type="text/xml"][starts-with(@title, 'Notizbuch ' || $param)]/@title)
    let $maxRev:=  max($tgnav//object[@title = $item]/number(substring-after(@uri, '.'))),
    $uri:= $tgnav//object[@title = $item][number(substring-after(@uri, '.')) = $maxRev]/substring-after(@uri, 'textgrid:')
    return
(:declare function app:list($datadir, $param) {:)
(:    let $metacoll := collection($datadir):)
(:    let $pattern := $param || '\d\d$':)
(:return:)
(:    for $nb in distinct-values($metacoll//tgmd:title[starts-with(., 'Notizbuch ' || $param)]):)
(:    order by $nb:)
(:    return :)
(:        let $imgUri := doc('/db/sade-projects/textgrid/data/xml/data/217qs.1.xml')//digilib:image[@name = (substring( $nb , 10, 13) || '_001.jpg')]/@uri:)
(:        let $maxRev := max($metacoll//tgmd:revision[preceding::tgmd:title[1] = $nb]):)
(:        let $uri := substring-after($metacoll//tgmd:textgridUri[preceding::tgmd:title[1] = $nb][following::tgmd:revision[1] = $maxRev], 'textgrid:'):)
(:        return:)
        <div class="panel panel-dark">
                    <div class="panel-heading">
                      <h3 class="panel-title">{ if (matches($item, '0\d')) then replace($item, '0', '') else $item }</h3>
                    </div>
                    <div class="panel-body">
                    <div class="row">
                        <div class="col-md-9">
                              uri: {$uri[last()]}<br/>
                              Revision: {$maxRev}<br/>
                              <a href="content.html?id=/xml/data/{$uri[last()]}.xml">content.html</a><br/>
                              <a href="content2.html?id=/xml/data/{$uri[last()]}.xml">content2.html</a><br/>
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
                                                    <li>Geographisches Register</li>
                                                    <li>Register der Periodika</li>
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
      <li class="chart" data-percent="{ hours-from-duration($duration) div 24 * 100}"><span>{ hours-from-duration($duration) }</span>Stunden</li>
      <li class="chart" data-percent="{ minutes-from-duration($duration) div 60 * 100 }"><span>{ minutes-from-duration($duration) }</span>Minuten</li>
    </ul>
};
