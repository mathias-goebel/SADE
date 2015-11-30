xquery version "3.0";

module namespace fontaneTransfo="http://fontane-nb.dariah.eu/Transfo";
declare boundary-space preserve;
declare default element namespace "http://www.tei-c.org/ns/1.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace digilib="digilib:digilib";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace xlink="http://www.w3.org/1999/xlink";

import module namespace console="http://exist-db.org/xquery/console";

declare function fontaneTransfo:magic($nodes as node()*) {
    (:
    C07 contains 27 different elements in tei:surface
        ref
    :)
    
for $node in $nodes return
typeswitch($node)
    case element(tei:TEI) 
            return 
                (element xhtml:div {
                    attribute id {'toc'},
                    attribute style {'display:none;'},
                    fontaneTransfo:toc($node)
                },
                element xhtml:div {
                    attribute class {'TEI', 'clearfix' (: damn bootstrap in this code? damn it! :) },
                    fontaneTransfo:magic($node/node())
                },
                element xhtml:script {
                    "$.getScript('//cdnjs.cloudflare.com/ajax/libs/jquery.lazyload/1.9.1/jquery.lazyload.min.js',function(){$('.imgLazy').lazyload({});});"
                })
    case element(tei:teiHeader) return ()
    case element(tei:sourceDoc)
        return
            element xhtml:div {
                attribute id {substring-after($node/@n, 'er_')},
                attribute class {'sourceDoc'},
                fontaneTransfo:magic($node/node())
            }
    case element(tei:surface)
        return (
            if($node/parent::tei:sourceDoc) then
                    element xhtml:div { 
                    attribute class {'rowWrapper', 'clearfix', 'butthead'},
                    attribute id { $node/string(@n) },
                    fontaneTransfo:facs($node),
                    element xhtml:div {
                        fontaneTransfo:surface($node),
                        fontaneTransfo:magic($node/node())
                    },
                    element xhtml:div {
                        attribute class {'teixml'},
                        element pre {
                            element code {
                                attribute class {'html'},
                                serialize($node)
                            }
                        }
                        }    
                    }
            else
            (fontaneTransfo:facs($node),
            element xhtml:div {
                fontaneTransfo:surface($node),
                fontaneTransfo:magic($node/node())
            })
            )
    case element(tei:zone)
        return
            element xhtml:div {
                fontaneTransfo:zone($node),
                fontaneTransfo:magic($node/node())
            }
    case element(tei:line)
        return
            element xhtml:div  {
                attribute class {'line'},
                attribute style {$node/@style, (if($node//text()[not(parent::tei:fw)]) then () else ('height:0.6cm;') )},
                fontaneTransfo:magic($node/node())
            }
    case element(tei:seg)
        return
            if ($node/tei:g[@ref="#hb"]) then fontaneTransfo:fraction($node)
            else
            element xhtml:span {
                attribute class {'seg', if ($node/@style) then fontaneTransfo:segStyle($node) else ()},
                fontaneTransfo:magic($node/node())
            }
    case element(tei:fw)
        return
            if ($node/preceding::tei:handShift[@new != '#Fontane'])
            then
                (element xhtml:div { attribute class {'fwWrapper'},
                element xhtml:span {
                    attribute class {'fw', (if ($node = ($node/ancestor::tei:surface//tei:fw[preceding::tei:handShift/@new != '#Fontane'])[position() gt 1] ) then (
                        (:'fw2':) ()
                        ) else () )
                    }, fontaneTransfo:magic($node/node())}
                })
            else ()
    case element(tei:mod)
        return
            element xhtml:span {
                attribute class {'mod', $node/@type},
                element xhtml:div {
                    attribute class {'modHover italic', if($node/ancestor::tei:*/@rotate or $node/ancestor::tei:zone/preceding-sibling::tei:addSpan) then () else 'hoverTop'},
                    '<',
                    element xhtml:span {
                        $node/tei:del/text(),
                        (if ($node/tei:del/tei:gap) then fontaneTransfo:magic(( element tei:gap {$node/tei:del/tei:gap/@*})) else ())
                    },
                    ' überschrieben ',
                    element xhtml:span {
                        $node/tei:add/text()
                    },
                    '>'
                },
                fontaneTransfo:magic($node/node())
            }
    case element(tei:del) 
        return 
            element xhtml:span {
                attribute class {'del', $node/@rend, if($node/@instant)then'instant'else()},
                (if($node/parent::tei:mod[@type="subst"] and string-length($node) lt string-length($node/following-sibling::tei:add)) then 
                        attribute style {'text-align: center;display: inline-block;position: absolute;width: 100%;'}
                    else ()),
                fontaneTransfo:magic($node/node())
            }
    case element(tei:hi) 
        return 
            element xhtml:span {
                attribute class {'hi'},
                fontaneTransfo:magic($node/node())
            }
    case element(tei:add) 
        return
            if ($node/@place = 'above') then
                element xhtml:span {
                    attribute class {'addWrapper'},
                    element xhtml:span {
                    attribute class {'add', $node/@place},
                        (if($node/@style) then 
                        attribute style {replace($node/@style, 'margin-left', 'left')}
                        else ()),
                        (if($node/@rend)then(fontaneTransfo:caret($node))else()),
                    fontaneTransfo:magic($node/node())
                    }   
                }
            else
                element xhtml:span {
                    attribute class {'add', $node/@place},
                    (if($node/parent::tei:mod and string-length($node/preceding-sibling::tei:del) lt string-length($node)) then attribute style { 'position: relative;' } else ()),
                    fontaneTransfo:magic($node/node())
                }
    case element(tei:retrace)
        return
            (
            fontaneTransfo:retrace($node),
            fontaneTransfo:magic($node/node())
            )
    case element(tei:choice)
        return
            element xhtml:span {
                attribute class {'choice'},
                if ($node/tei:expan) then 
                    element xhtml:div {
                        attribute class {'expan italic'},
                        $node//tei:expan/text()
                    }
                else (),
                fontaneTransfo:magic($node/node())
            }
    case element(tei:abbr)
        return
            element xhtml:span {
                attribute class {'abbr'},
                fontaneTransfo:magic($node/node())
            }
    case element(tei:rs) 
        return 
            element xhtml:span {
                attribute class {'rs', if($node/@type) then $node/@type else () },
                fontaneTransfo:magic($node/node())
            }
    case element(tei:date) 
        return 
            element xhtml:span {
                attribute class {'date'},
                fontaneTransfo:magic($node/node())
            }
    case element(tei:stamp)
        return
            element xhtml:div {
                attribute class {'stamp'},
                fontaneTransfo:stamp($node)
            }
    case element(tei:metamark)
        return
            element xhtml:span {
                attribute class {'metamark'},
                fontaneTransfo:magic($node/node())
            }
    case element(tei:g)
        return
            if ($node/@ref='#mgem') then
                element xhtml:span {
                    attribute class {'g mgem'},
                    fontaneTransfo:magic($node/node())
                }
            else if ($node/@ref='#ngem') then
                element xhtml:span {
                    attribute class {'g ngem'},
                    fontaneTransfo:magic($node/node())
                }
            else ()
    case element(tei:unclear)
    return
        element xhtml:span {
            attribute class {'unclear'},
            fontaneTransfo:magic($node/node())
        }
    case element(tei:gap)
        return
            element xhtml:span {
                attribute class {'gap', $node/@reason, ($node/@unit || $node/@quantity (: classes must begin with a letter :)),
                (let $preMedium := $node/preceding::tei:handShift[@medium][1]/@medium
                return 
                    if(tokenize($preMedium, ' ') = ('blue_pencil', 'violet_pencil', 'black_ink', 'blue_ink', 'brown_ink')) then $preMedium else ())
                }
            }
    case element(tei:milestone) return 
        element xhtml:span {
            attribute class {'milestone', $node/@type, $node/@unit},
            attribute style {'display:none;'}
        }
    case element(tei:expan) return ()
    case element(tei:addSpan) return ()
    case element(tei:handShift) return ()
    case element(tei:lb) return ()
    case element(tei:anchor) return ()
    case text()
        return 
            fontaneTransfo:text($node)
    default return fontaneTransfo:magic($node/node())
};

declare function fontaneTransfo:surface($n) {
attribute class {'surface', (if($n/@type) then (' tei'||$n/@type) else '')},
(: dont call it a label (bootstrap) :)
(if($n/@n) then attribute id {$n/@n} else()),
attribute style {
distinct-values((
    if ($n/@n = 'outer_front_cover') 
        then
            let $coverImage:= doc('/db/sade-projects/textgrid/data/xml/data/217qs.1.xml')
            let $coverTble := doc('/db/sade-projects/textgrid/data/xml/tile/218r2.0.xml')
            let $shape := $coverTble//tei:link[ends-with( @targets, $coverImage//digilib:image[@name = $n/@facs]/concat('#',@xml:id) )]/substring-after(substring-before(@targets, ' '), '#')
            let $x:= $coverTble//svg:rect[@id = $shape]/number(substring-before(@x, '%')) div 100,
            $y := $coverTble//svg:rect[@id = $shape]/number(substring-before(@y, '%')) div 100,
            $w := $coverTble//svg:rect[@id = $shape]/number(substring-before(@width, '%')) div 100,
            $h := $coverTble//svg:rect[@id = $shape]/number(substring-before(@height, '%')) div 100
            return
            "background-image: url('/digilib/"||$n/@facs||"?dh=500&amp;wx="||$x||"&amp;wy="||$y||"&amp;ww="||$w||"&amp;wh="||$h||"&amp;mo=png');background-size:cover;"
    else (),
    
    if (    ($n/parent::tei:sourceDoc and 
            $n/@n != 'spine' and
            sum($n//text()[preceding::tei:handShift[@new][1]/@new='#Fontane'][matches(., '.[a-zA-Z0-9]')]/string-length() ) lt 1 )
            and not( max($n//tei:*/@uly) gt 2.1 )
            (: if you like to edit here, please edit the facs height the same way and dont forget the TOC! :)
        ) then 'max-height: 3cm;' else(),
    
    if ($n/(@ulx or @uly)) then ('position:absolute;', 'top:'|| $n/@uly ||'cm;', 'left:'|| $n/@ulx ||'cm;') else (),
    if ($n/(@ulx and @lrx)) then ('position:absolute;' ,'left:'|| $n/@ulx ||'cm;' , 'width:'||$n/@lrx - $n/@ulx||'cm;') else (),
    if ($n/(@uly and @lry)) then ('position:absolute;', 'top:'|| $n/@uly ||'cm;' , 'height:'||$n/@lry - $n/@uly||'cm;') else (),
    if(count($n//tei:zone) = 1 and $n//tei:zone/@rotate) then ('transform:rotate('|| $n//tei:zone/@rotate ||'deg);' ,
            'transform-origin: left top;') else()
            
    )) (: distinct values :)
}
};

declare function fontaneTransfo:zone($n) {
attribute class {
            'zone', 
            if ($n/preceding::*[1]/local-name() = 'addSpan') then 'addSpan' else(),
            if ($n/tei:figure) then 'figure' else(),
            fontaneTransfo:segStyle($n)
    },

attribute style {
(: place it! :)
    if ($n/@ulx or $n/@uly or $n/@lrx or $n/@lry)
        then
            if ($n/ancestor::tei:zone[last()]//tei:figure) 
                then
                'position:absolute;'||
                'top:'|| $n/@uly - sum($n/ancestor::tei:zone/@uly)||'cm;'||
                'left:'||$n/@ulx -sum($n/ancestor::tei:zone/@ulx)||'cm;'||
                'width:'|| (if($n/@lry) then $n/@lrx - (if($n/@ulx) then $n/@ulx else 0) - sum($n/ancestor::tei:zone/@lrx) ||'cm;'  else '' )||
                'height:'|| $n/@lry - (if($n/@uly) then $n/@uly else 0)  - sum($n/ancestor::tei:zone/@lry)||'cm;'
                else
            if (not($n/@ulx|$n/@uly|$n/@lrx) and $n//tei:fw) 
                then 'width:100%;'
            else
                'position:absolute;'||
                'top:'|| $n/@uly ||'cm;'||
                'left:'||$n/@ulx ||'cm;'||
                'width:'||$n/@lrx - (if($n/@ulx) then $n/@ulx else 0) ||'cm;'||
                'height:'|| $n/@lry - (if($n/@uly) then $n/@uly else 0)  ||'cm;'
        else(),
(: rotate it! :)   
    if ($n/@rotate and not( $n/parent::tei:surface/count(tei:zone) = 1)) 
        then
            'transform:rotate('|| $n/@rotate ||'deg);'||
            'transform-origin: left top;'
    else (),
(: line-height it! :)
    (: dont start calcualting in case of a figure :)
    if ($n/ancestor::tei:zone[last()]//tei:figure) then 'line-height:100%'
    else 
    
    (: ok, we are not in a sktech :)
    
    let $cntline := 
            count($n//tei:line) - 
(:            count($n//tei:line[child::tei:fw][descendant::tei:*[not(2)]]) -:)
            count($n//tei:zone[@uly or @lry]//tei:line) 
(:            -            count($n/tei:line[tei:metamark][not(text()[not(parent::tei:metamark)])]):)
    let $surfaceHeight := $n/preceding::tei:teiHeader//tei:extent[1]/tei:dimensions[@type = 'leaf']/tei:height[1]/@quantity div 10
    return
    if ($n/@lry and not($n/@rotate)) then
        
        let $height := $n/@lry - (if($n/@uly) then $n/@uly else 0)
        return
            if (not($n/ancestor-or-self::*/@type = 'illustration') and $cntline != 0)
                then
                    'line-height:' ||
                    $height div $cntline
                    ||'cm;'
            else ()
    else
        (: only one zone and no @lry :)
        if (count(/$n/parent::tei:surface[parent::tei:sourceDoc]/tei:zone) = 1 and not($n/@lry) and $cntline gt 6 and not($n/@rotate))
        then 'line-height:' || ($surfaceHeight) div $cntline ||'cm;'
    else
        if ($n/@uly and not($n/@lry) and not($n/@rotate)) 
        then 'line-height:' || ($surfaceHeight - $n/@uly) div $cntline ||'cm;'
    else 
        if ($n/@rotate = '90')
        then
            'line-height:' ||
            $n/@ulx div $cntline
            ||'cm;'
    else
        if ($n/@rotate = '270')
        then
            'line-height:' ||
            (number($n/preceding::tei:teiHeader//tei:extent[1]/tei:dimensions[@type = 'leaf']/tei:width[1]/@quantity) div 10 - $n/@uly) div $cntline
            ||'cm;'
    else (),
(: look 4 TILE objects :)
    if ($n/tei:figure[@xml:id]) then
        let $uri := $n/ancestor::tei:TEI//tei:publicationStmt//tei:idno[@type="TextGrid"]/string(.)
        let $tei := (collection('/db/sade-projects/textgrid/data/xml/tile/')//tei:TEI//tei:link[contains(@targets, $uri)][contains(@targets, 'shape')][ends-with(@targets, $n/tei:figure/@xml:id)])[last()]/ancestor::tei:TEI
        let $link := (collection('/db/sade-projects/textgrid/data/xml/tile/')//tei:TEI//tei:link[contains(@targets, $uri)][contains(@targets, 'shape')][ends-with(@targets, $n/tei:figure/@xml:id)])[last()]
        let $shape := $link//substring-before(substring-after(@targets, '#'), ' ')
        let $image := $tei//svg:g[@id = $link/parent::tei:linkGrp/substring-after(@facs, '#')]/svg:image/@xlink:href
        
        let $svgg := $tei//svg:g[@id = $link/parent::tei:linkGrp/substring-after(@facs, '#')]

        let $x := number($svgg//svg:rect[@id = $shape]/substring-before(@x, '%')) div 100
        let $y := number($svgg//svg:rect[@id = $shape]/substring-before(@y, '%')) div 100
        let $w := number($svgg//svg:rect[@id = $shape]/substring-before(@width, '%')) div 100
        let $h := number($svgg//svg:rect[@id = $shape]/substring-before(@height, '%')) div 100

        return ("background-image: url('/digilib/"|| $image || '?dh=500&amp;dw=500&amp;wx='||$x||'&amp;wy='||$y||'&amp;ww='||$w||'&amp;wh='||$h||"&amp;mo=png'); background-repeat: no-repeat; background-size: 100% auto;")
    else (),
    
    (: like on C07 15r, a zone can contain a single (nonword) character that belongs to nearby lines. in this cases, we increase the font size by rule.
    this stays against our practise to encode a font-size if semantic matters. we should discuss this.
    :)
    if (sum($n/tei:line//text()/string-length(.)) = 1 and $n/tei:line//text()/matches(., '\W' ) ) then 'font-size:'||$n/@lry - $n/@uly||'cm' else ()
},
if (contains($n/@rend, 'line-through-style:triple_oblique')) 
then for $i in (1 to 3) return element svg {
    namespace svg { "http://www.w3.org/2000/svg" },
    attribute class { "tripleoblique"},
    attribute viewbox { "0 0 100 100"},
    element line {
        attribute x1 {"0"},
        attribute y1 {"0"},
        attribute x2 {"100"},
        attribute y2 {"100"},
        attribute style {"stroke-width:2"}
    }
}
else ()

};

declare function fontaneTransfo:segStyle($node) {
(: returns a sequence of classes according to the given styles
 : not only for tei:seg, also used in tei:zone
 :  :)
let 
$style := $node/@style,
$rend :=  $node/@rend,
$preMedium := $node/preceding::tei:handShift[@medium][1]/@medium

let $rend := replace($rend, '\s', '')
let $seq :=
    for $s in tokenize(replace($style, '\s', ''), ';')
    return
        for $t in tokenize($s, ':')
            return if (contains($t, '-style')) then substring-before($t, '-style') else $t
let $rendSeq := 
    for $r in tokenize(replace($rend, '\s', ''), ';')
    return
        replace(substring-after($r, ':'), '[\(\)]', '')

let $medium := if (tokenize($preMedium, ' ') = ('blue_pencil', 'violet_pencil', 'black_ink', 'blue_ink', 'brown_ink')) then $preMedium else ()
return if($seq = ()) then ('TODO', $medium) else ($seq, $rendSeq, $medium)
};

declare function fontaneTransfo:retrace($node){

element xhtml:span {
    attribute class {'retrace'},
    element xhtml:span {
        attribute class {'retraced'},
        fontaneTransfo:magic($node/text()),
        element xhtml:div {
            attribute class {'retraceHover', if($node/ancestor::tei:*/@rotate and $node/ancestor::tei:zone/preceding-sibling::tei:addSpan) then () else 'hoverTop'},
            (if ($node/ancestor::tei:zone/@rotate) then attribute style {'transform: rotate('|| 360 - sum($node/ancestor::tei:zone/@rotate) ||'deg); transform-origin: left top;'} else ()),
            (if (ends-with($node/preceding::text()[ancestor::tei:line][1], ' '))
                then ()
                else 
                    let $preText:= string-join($node/preceding::text()[ancestor::tei:line][position() lt 6])
                    let $lastWord:= tokenize($preText, ' |\.|,')[last()]
                    return $lastWord),
            element xhtml:span {
                attribute class {'italic'},
                '<'},
            $node//text(),
            element xhtml:span {
                attribute class {'italic'},
                ' nachgezogen '},
                $node//text(),
                element xhtml:span {
                attribute class {'italic'},
                '>'},
            (if (starts-with($node/following::text()[ancestor::tei:line][1], ' ')) then () else tokenize($node/following::text()[ancestor::tei:line][1], ' ')[1] )
        }
    }
}
};

declare function fontaneTransfo:stamp($node) {
switch ($node/string(.))
case 'FONTANE.' return 
                    <svg xmlns="http://www.w3.org/2000/svg" width="23mm" height="4mm">
                        <g alignment-baseline="baseline">
                            <text x="0mm" y="3.5mm" style="fill: purple;stroke: none;font-size:4mm; font-family:Ubuntu-Light, Verdana, sans-serif;">FONTANE.</text>
                        </g>
                    </svg>


case 'STAATSBIBLIOTHEK •BERLIN•' return
                    <svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="24.2mm" height="15.2mm">
                        <defs>
                            <filter id="unschaerfe" color-interpolation-filters="sRGB">
                                <feGaussianBlur stdDeviation="0.0"/>
                            </filter>
                        </defs>
                        <g alignment-baseline="baseline">
                            <g filter="url(#unschaerfe)">
                                <rect x="0.5mm" y="0.5mm" width="23mm" height="14mm" rx="1mm" fill="none" stroke="black" stroke-width="1mm"/>
                                <text
                                    style="stroke:none; font-family:FreeSerif, serif; font-size: 3.4mm; font-weight: bold;">
                                    <tspan id="zeile1" x="5mm" y="4mm">STAATS-</tspan>
                                    <tspan id="zeile2" x="1mm" y="8.5mm">BIBLIOTHEK</tspan>
                                    <tspan id="zeile3" x="3mm" y="13mm">∙ BERLIN ∙</tspan>
                                </text>
                            </g>
                        </g>
                    </svg>

case 'DSB Font.-Arch. Potsdam' return
                    <svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="15.2mm" height="15.2mm">
                        <defs>
                            <filter id="unschaerfe" color-interpolation-filters="sRGB">
                                <feGaussianBlur stdDeviation="0.3"/>
                            </filter>
                        </defs>
                        <g alignment-baseline="baseline">
                            <circle cx="7.5mm" cy="7.5mm" r="7.25mm" fill="none" stroke="darkblue" stroke-width="0.5mm"/>
                            <text style="font-size:65%; font-family:FreeSans;" fill="darkblue">
                                <tspan id="zeile1" x="4.5mm" y="4mm">DSB</tspan>
                                <tspan id="zeile2" x="0.9mm" y="7.5mm">Font.-Arch.</tspan>
                                <tspan id="zeile3" x="2mm" y="11mm">Potsdam</tspan>
                            </text>
                        </g>
                    </svg>
default return
                    <svg xmlns="http://www.w3.org/2000/svg" width="23mm" height="3.5mm">
                        <g alignment-baseline="baseline">
                            <text x="0mm" y="3.5mm" style="font-size:4mm; font-family:Ubuntu-Light, Verdana, sans-serif;" fill="purple">Stempel nicht unterstützt oder Fehler im Code.</text>
                        </g>
                    </svg>
};
declare function fontaneTransfo:text($n) {
(: steht Text nur innerhalb von tei:line? :)
if ($n/ancestor::tei:line) then
element xhtml:span {
    attribute class { 
        $n/preceding::handShift[@medium][1]/@medium,
        $n/preceding::handShift[@new][1]/substring-after(@new, '#'),
        $n/preceding::handShift[@rendition][1]/@rendition,
        (if (contains($n/preceding::handShift[@script][1]/@script, ' '))
        then $n/preceding::handShift[@script][1]/@script
        else
            if($n/preceding::handShift[@script][1]/@script = ('standard', 'clean', 'hasty'))
            then $n/preceding::handShift[@script = ('Latn', 'Latf')][1]/@script || ' ' || $n/preceding::handShift[@script][1]/@script
            (: ^^^ no test for an additional whitespace together with Latn or Latf, characteristics will be overwritten by the current @script :)
        else
            if ($n/preceding::handShift[@script][1]/@script = ('Latn', 'Latf'))
            then $n/preceding::handShift[@script = ('standard', 'clean', 'hasty')][1]/@script || ' ' || $n/preceding::handShift[@script][1]/@script
        else ''
        )
    },
    if ($n/matches(., '.[\w\[\d]') and 
        $n/preceding::tei:handShift[@new][1]/@new != ($n/preceding::tei:handShift[@new][1]/preceding::tei:handShift[@new]/@new) )
    then  
        (attribute id { 'new'||$n/preceding::handShift[@new][1]/substring-after(@new, '#') }, 
        attribute data-handtoggle { $n/preceding::handShift[@new][1]/substring-after(@new, '#') })
    else (),
    
    (: manipulate the string in case of Gemination :)
    if($n/parent::tei:g) then (
        switch ($n/parent::tei:g/@ref)
            case '#mgem' return '&#xe095;'
            case '#ngem' return '&#xe096;'
            default return ()
        )
    else $n/string()
    }
else ()
};

declare function fontaneTransfo:facs($node) {
(if ($node/parent::tei:sourceDoc) then 
    element xhtml:div {
        attribute class {'facs'},
        attribute style { 
            if (    ($node/parent::tei:sourceDoc and 
                    $node/@n != 'spine' and
                    sum($node//text()[preceding::tei:handShift[@new][1]/@new='#Fontane'][matches(., '.[a-zA-Z0-9]')]/string-length() ) lt 1 )
                    and not( max($node//tei:*/@uly) gt 2.1 )
                    (: if you like to edit here, please edit the surface height the same way! :)
            ) then 'max-height: 3cm;' else()
        },
        element xhtml:a {
            attribute href { '/digilib/'||$node/@facs||'?m2' },
            attribute target {'_blank'},
            element xhtml:img {
                attribute class {'imgLazy facs'},
                attribute data-original {fontaneTransfo:digilib($node)},
                attribute src {'/public/img/loader.svg'}
            }
        }
    } else ())
};

declare function fontaneTransfo:digilib($node){
let
$currentNotebook := $node/substring-before(@facs, '_'),
$n := $node/@n,
$type := local-name($node[1]),
$facs := if (not(contains($node/@facs, ' '))) then $node/@facs else substring-before($node/@facs, ' '),
$surfaceWidth := $node/ancestor::tei:TEI//extent[1]/dimensions[@type = 'leaf']/width[1]/@quantity,
$surfaceHeight := $node/ancestor::tei:TEI//extent[1]/dimensions[@type = 'leaf']/height[1]/@quantity,
$bindingWidth := $node/ancestor::tei:TEI//extent[1]/dimensions[@type = 'binding']/width[1]/@quantity,
$bindingHeight := $node/ancestor::tei:TEI//extent[1]/dimensions[@type = 'binding']/height[1]/@quantity,
$dpcm := 236.2205, (:  600 dpi = 236.2205 dpcm  :)
$exif := doc('/db/sade-projects/textgrid/data/xml/data/217qs.1.xml'),
$covertble := doc('/db/sade-projects/textgrid/data/xml/tile/218r2.0.xml'),
$image-width := number($exif//digilib:image[@name = $facs]/@width),
$image-height := number($exif//digilib:image[@name = $facs]/@height),
$plusX := $exif//digilib:offset[@notebook = $currentNotebook][@x]/@x,
$plusX := if ($plusX = '') then 1 else $plusX,
$plusY := $exif//digilib:offset[@notebook = $currentNotebook][@y]/@y,
$plusY := if ($plusY = '') then 1 else $plusY,
$shape := if($type = 'cover' and $exif//digilib:image[@name = $facs]/@xml:id) then (substring-after(substring-before($covertble//tei:link[ends-with(@targets, $exif//digilib:image[@name = $facs]/@xml:id)][1]/@targets, ' '), '#')) else 0,
$scaler := if (number(substring($facs, 7, 1)) mod 2 = 1) then '/digilib/1/Scaler?fn=' else '/digilib/2/Scaler?fn=',
$scaler := '/digilib/',

$ulx := $node/@ulx,
$uly := $node/@uly,
$lrx := $node/@lrx,
$lry := $node/@lry,

(: lets start building our url :)
$image := $facs,
$resolution := switch ($type)
                    case 'thumb' return '?dh=150'
                    case 'thumb-link' return '?dw=1500&amp;dh=1500'
                    case 'surface-empty' return '?dw=300&amp;dh=300'
                    case 'figure' return '?dw=500&amp;dh=500'
                    default return '?dw=500&amp;dh=500',
$offset := switch($type)
                    case 'figure' return
                                    if (matches($n, '\d[a-z]*r')) then 
                                        '&amp;wx='||($plusX + $ulx + $surfaceWidth div 10) * $dpcm div $image-width||
                                        '&amp;wy='||($plusY + $uly) * $dpcm div $image-height
                                    else if(matches($n, '\d[a-z]*v')) then  
                                        '&amp;wx='||($plusX + $ulx) * $dpcm div $image-width||
                                        '&amp;wy='||($plusY + $uly) * $dpcm div $image-height
                                    else ()
                    case 'cover' return
                                    '&amp;wx='||number(substring-before($covertble//svg:rect[@id = $shape][1]/@x, '%')) div 100 ||
                                    '&amp;wy='||number(substring-before($covertble//svg:rect[@id = $shape][1]/@y, '%')) div 100
                    default return 
                                if(contains($n, 'outer')) then
                                    '&amp;wx='||$dpcm div $image-width||
                                    '&amp;wy='||$dpcm div $image-height
                                else if($n = 'inner_back_cover') then 
                                    '&amp;wx='||$plusX * $dpcm div $image-width + ($surfaceWidth div 10) * ($dpcm div $image-width)||
                                    '&amp;wy='||$plusY * $dpcm div $image-height
                                else if($n = 'inner_front_cover') then 
                                    '&amp;wx='||$dpcm div $image-width||
                                    '&amp;wy='||$dpcm div $image-height
                                else if (matches($n, '\d[a-z]*r')) then
                                    '&amp;wx='||$plusX * $dpcm div $image-width + ($surfaceWidth div 10) * ($dpcm div $image-width)||
                                    '&amp;wy='||$plusY * $dpcm div $image-height||console:log($plusX)
                                else if(matches($n, '\d[a-z]*v')) then 
                                    '&amp;wx='||$plusX * $dpcm div $image-width||
                                    '&amp;wy='||$plusY * $dpcm div $image-height
                                else (),
$range := if ($n = 'none') then '&amp;ww=1&amp;wh=1'
        else if ($type = 'figure') then '&amp;ww='||($lrx - $ulx) * $dpcm div $image-width||'&amp;wh='||($lry - $uly) * $dpcm div $image-height
        else if ($type = 'cover' and $exif//digilib:coveroffset[@notebook = $currentNotebook]) then '&amp;ww='||number(substring-before($covertble//svg:rect[@id = $shape][1]/@width, '%')) div 100 || 
                        '&amp;wh='||number(substring-before($covertble//svg:rect[@id = $shape][1]/@height, '%')) div 100
        else if (contains($n, 'outer')) then '&amp;ww=' || ($bindingWidth div 10) * $dpcm div $image-width || '&amp;wh=' || ($bindingHeight div 10) * $dpcm div $image-height
        else    '&amp;ww='||(($surfaceWidth div 10) + 0.5) * $dpcm div $image-width||
                '&amp;wh='||(($surfaceHeight div 10) + 0.5) * $dpcm div $image-height

return if($type = 'total') then concat($scaler, $image, $resolution, '&amp;mo=png')
else concat($scaler, $image, $resolution, $offset, $range, '&amp;mo=png')
};

declare function fontaneTransfo:fraction($n) {
element xhtml:span {
    attribute class {'fraction'},
    attribute style {$n/@style},
    element xhtml:span { attribute class {'top'},
        $n/tei:seg[@style='vertical-align:super']/text()
    },
    element xhtml:span { attribute class {'bottom'},
        $n/tei:seg[@style='vertical-align:sub']/text()
    }
}
    
};

declare function fontaneTransfo:toc($node) {
<ol>
{
for $surface in $node/tei:sourceDoc/tei:surface
return
    <li><a href="#{$surface/@n}">{$surface/string(@n)} {
    if
        (sum($node//text()[preceding::tei:handShift[@new][1]/@new='#Fontane']/string-length() ) lt 1)
    then '(vakat)' 
    else ()}
    </a></li>
}
</ol>
};

declare function fontaneTransfo:caret($node) {
let $bow := <svg:svg width="{substring-before(substring-after($node/@rend, 'caret:bow('), ',pos-')}" height="1cm" viewBox="0 0 100 500" style="{concat(substring-before(substring-after($node/@rend, 'pos-'), ')'), ':-20;')}">
           <svg:path d="M450,250 C500,500 0,250 0,500" stroke="grey" fill="transparent" stroke-width="20"/>
           </svg:svg>

let $curvedV := 
    let $width:= tokenize(substring-before(substring-after($node/@rend, '('), ')'), ','), $w1:=number(substring-before($width[1], 'cm')), $w2:=number(substring-before($width[2], 'cm')), $x:=($w1 * 100) div ($w1 + $w2)  return
        
    <svg:svg style="{(if(not(contains($node/@rend, 'pos'))) then 'left:0;' else() ), 'top: 10px;'}" width="{concat((number(substring-before($width[1], 'cm')) + number(substring-before($width[2], 'cm'))), 'cm')}" height="1cm" viewBox="0 0 100 100">
                    <svg:line style="stroke:grey;stroke-width:5" y2="100" x2="{$x}"
                        y1="0" x1="0"/>
                    <svg:line style="stroke:grey;stroke-width:5" y2="0" x2="100"
                        y1="100" x1="{$x}"/>
</svg:svg>


return
if($node/@rend = 'caret:bow(1.5cm,pos-right)') 
    then $bow
else ()
};