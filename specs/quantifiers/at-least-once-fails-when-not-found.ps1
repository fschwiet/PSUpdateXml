WHEN:

    param($xmlFile)

    update-xml $xmlFile {
        get-xml -atLeastOnce "//root/document/heading"
    }
    
WHEN:

    param($xmlFile)

    update-xml $xmlFile {
        set-xml -atLeastOnce "//root/document/heading" "world"
    }    
    
WHEN:

    param($xmlFile)

    update-xml $xmlFile {
        remove-xml -atLeastOnce "//root/document/heading"
    }

WHEN:

    param($xmlFile)

    update-xml $xmlFile {
        append-xml -atLeastOnce "//root/document/heading" "world"
    }
    
WHEN:

    param($xmlFile)

    update-xml $xmlFile {
        for-xml -atLeastOnce "//root/document/heading" {
            
        }
    }

GIVEN:
<root>
    <document>
    </document>
</root>

THEN-ERROR-CONTAINS:
Expected to find at least one match
actually found 0 matches
"//root/document/heading"
