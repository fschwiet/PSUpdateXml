WHEN:

    param($xmlFile)

    update-xml $xmlFile {
        get-xml -atMostOnce "//root/document/heading"
    }
    
WHEN:

    param($xmlFile)

    update-xml $xmlFile {
        set-xml -atMostOnce "//root/document/heading" "world"
    }
    
WHEN:

    param($xmlFile)

    update-xml $xmlFile {
        remove-xml -atMostOnce "//root/document/heading"
    }

WHEN:

    param($xmlFile)

    update-xml $xmlFile {
        append-xml -atMostOnce "//root/document/heading" "world"
    }
    
WHEN:

    param($xmlFile)

    update-xml $xmlFile {
        for-xml -atMostOnce "//root/document/heading" {
            
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
Expected to find at most one match
actually found 2 matches
"//root/document/heading"
