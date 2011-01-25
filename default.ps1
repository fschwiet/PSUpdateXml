
properties {
    $buildDirectory = ".\build"
}

import-module .\PSUpdateXml.psm1

task default -depends CheckSpecs

function assert-xml-equals([System.IO.FileInfo]$file1, [System.IO.FileInfo]$file2) {

    $f1 = (resolve-path $file1)
    $f2 = (resolve-path $file2)

    $comparisonResult = & .\tools\XmlDiffPatch\Bin\XmlDiff.exe $f1 $f2
    
    Assert ($comparisonResult -like "*Files are identical*") "Expected XML files to equal, there were different.  Filesnames: '$f1', '$f2'";
}

task Clean {
    if (test-path $buildDirectory) {
        rmdir $buildDirectory -recurse -force
    }
}


task CheckSpecs -depends Clean {

    gci .\specs\ * | % {
    
        $specName = $_.name;
        $specFile = $_.fullname;
        
        "Running spec $specName at $specFile"
        
        $script:blocks = @();
        $currentBlock = $null;
        
        function nextBlock($type) {
            $result = @{
                type = $type
                lines = @()
            }
            $script:blocks += , $result
            $result
        }
        
        switch -file $specFile -regex {
            "\s*GIVEN:\s*" { 
                $currentBlock = nextBlock "given"
            }
            "\s*WHEN:\s*" { 
                $currentBlock = nextBlock "when"
            }
            "\s*THEN:\s*" { 
                $currentBlock = nextBlock "then"
            }
            default {
                $currentBlock.lines += $_
            }
        }
        
        $givens = @($blocks | ? { $_.type -eq "given" })
        $whens = @($blocks | ? { $_.type -eq "when" })
        $thens = @($blocks | ? { $_.type -eq "then" })
        
        foreach($givenIndex in 1..$givens.length) {
            $given = $givens[$givenIndex-1];
            
            foreach($whenIndex in 1..$whens.length) {
                $when = $whens[$whenIndex-1];
                
                foreach($thenIndex in 1..$thens.length) {
                    $then = $thens[$thenIndex-1];
                    
                    $specPath = (join-path $buildDirectory "$specName.$givenIndex.$whenIndex.$thenIndex")
                    "  ($givenIndex,$whenIndex,$thenIndex @ $specPath)"
                    
                    $null = mkdir $specPath

                    $xmlPath = (join-path $specPath "test.xml")
                    $expectedPath = (join-path $specPath "expected.xml")
                    $sutPath = (join-path $specPath "test.ps1")
                    
                    $given.lines | set-content $xmlPath
                    $then.lines | set-content $expectedPath
                    
                    $whenExpression = [string]::join("`n", $when.lines)
                    $when.lines | set-content $sutPath
                    
                    & $sutPath $xmlPath
                    
                    assert-xml-equals $xmlPath $expectedPath
                }
            }
        }
    }
}





