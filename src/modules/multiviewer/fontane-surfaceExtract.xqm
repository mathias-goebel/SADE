xquery version "3.0";
module namespace fontaneSfEx="http://fontane-nb.dariah.eu/SfEx";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function fontaneSfEx:extract ($tei as node(), $page as xs:string){
<TEI xmlns="http://www.tei-c.org/ns/1.0" xml:lang="de">  
    {
        $tei/tei:teiHeader
    }
    <sourceDoc>
        {for $attr in $tei/tei:sourceDoc/@* return $attr}
        {
            element tei:handShift {
                attribute 
                    script { 
                        if (contains($tei/tei:sourceDoc/tei:surface[@n=$page]/preceding::handShift[@script][1]/@script, ' '))
                        then 
                            $tei/tei:sourceDoc/tei:surface[@n=$page]/preceding::handShift[@script][1]/@script
                        else
                            if($tei/tei:sourceDoc/tei:surface[@n=$page]/preceding::handShift[@script][1]/@script = ('standard', 'clean', 'hasty'))
                            then $tei/tei:sourceDoc/tei:surface[@n=$page]/preceding::handShift[@script = ('Latn', 'Latf')][1]/@script || ' ' || $tei/tei:sourceDoc/tei:surface[@n=$page]/preceding::handShift[@script][1]/@script
                            (: ^^^ no test for an additional whitespace together with Latn or Latf, characteristics will be overwritten by the current @script :)
                        else
                            if ($tei/tei:sourceDoc/tei:surface[@n=$page]/preceding::handShift[@script][1]/@script = ('Latn', 'Latf'))
                            then $tei/tei:sourceDoc/tei:surface[@n=$page]/preceding::handShift[@script = ('standard', 'clean', 'hasty')][1]/@script || ' ' || $tei/tei:sourceDoc/tei:surface[@n=$page]/preceding::handShift[@script][1]/@script
                        else ''
                },
                attribute new {$tei/tei:sourceDoc/tei:surface[@n=$page]/preceding::tei:handShift[@new][1]/@new},
                attribute medium {$tei/tei:sourceDoc/tei:surface[@n=$page]/preceding::tei:handShift[@medium][1]/@medium},
                attribute rendition {$tei/tei:sourceDoc/tei:surface[@n=$page]/preceding::tei:handShift[@rendition][1]/@rendition}
            }
        }
        {$tei/tei:sourceDoc/tei:surface[@n=$page]}
    </sourceDoc>
</TEI>
};