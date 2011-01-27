WHEN:

    param($xmlFile)

    update-xml $xmlFile {
        get-xml -exactlyOnce "//root/document/heading"
    }
    
WHEN:

    param($xmlFile)

    update-xml $xmlFile {
        set-xml -exactlyOnce "//root/document/heading" "world"
    }
    
WHEN:

    param($xmlFile)

    update-xml $xmlFile {
        remove-xml -exactlyOnce "//root/document/heading"
    }

WHEN:

    param($xmlFile)

    update-xml $xmlFile {
        append-xml -exactlyOnce "//root/document/heading" "world"
    }
    
WHEN:

    param($xmlFile)

    update-xml $xmlFile {
        for-xml -exactlyOnce "//root/document/heading" {
            
        }
    }

GIVEN:
<root>
    <document>
        <heading></heading>
        <heading></heading>
    </document>
</root>

THEN-ERROR-CONTAINS:
Expected to find one match
actually found 2 matches
"//root/document/heading"
