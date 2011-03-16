
properties {
    $buildDirectory = ".\build"
}

import-module .\PSUpdateXml.psm1

task default -depends CheckSpecs

function assert-xml-equals([System.IO.FileInfo]$file1, [System.IO.FileInfo]$file2) {

    $f1 = (resolve-path $file1)
    $f2 = (resolve-path $file2)

    $comparisonResult = & .\tools\XmlDiffPatch\Bin\XmlDiff.exe $f1 $f2
    
    if (-not ($comparisonResult -like "*Files are identical*")) {
        diffmerge $f1 $f2
    }
    
    Assert ($comparisonResult -like "*Files are identical*") "Expected XML files to equal, there were different.  Filesnames: '$f1', '$f2'";
}

task Clean {
    if (test-path $buildDirectory) {
        rmdir $buildDirectory -recurse -force
    }
}


task CheckSpecs -depends Clean {

    $specsBase = gi .\specs\

    gci $specsBase * -rec | ? { -not $_.PSIsContainer } | % {
    
        $specName = $_.fullname.Substring($specsBase.fullname.length);
        $specFile = $_.fullname;
        
        "Running spec $specName at $specFile"
        
        $script:blocks = @();
        $currentBlock = $null;
        
        function nextBlock($blockType) {
            $result = @{
                blockType = $blockType;
                lines = @();
            }
            $script:blocks += , $result
            $result
        }
        
        $regexLineWithComment = "";#"\s*#.*`$"
        
        switch -file $specFile -regex {
            ("^\s*GIVEN:" + $regexLineWithComment) { 
                $currentBlock = nextBlock "given"
            }
            ("^\s*WHEN:" + $regexLineWithComment) { 
                $currentBlock = nextBlock "when"
            }
            ("^\s*THEN:" + $regexLineWithComment) { 
                $currentBlock = nextBlock "then"
            }
            ("^\s*THEN-ERROR-CONTAINS:" + $regexLineWithComment) { 
                $currentBlock = nextBlock "then-error-contains"
            }
            default {
                if ($currentBlock) {
                    $currentBlock.lines += $_
                }
            }
        }
        
        $givens = @($blocks | ? { $_.blockType -eq "given" })
        $whens = @($blocks | ? { $_.blockType -eq "when" })
        $thens = @($blocks | ? { $_.blockType -eq "then" })
        $expectedErrors = @($blocks | ? { $_.blockType -eq "then-error-contains" })
        
        for($givenIndex = 0; $givenIndex -lt $givens.length; $givenIndex++) {
            $given = $givens[$givenIndex];
            
            for($whenIndex = 0; $whenIndex -lt $whens.length; $whenIndex++) {
                $when = $whens[$whenIndex];
                
                for($thenIndex = 0; $thenIndex -lt $thens.length; $thenIndex++) {
                    $then = $thens[$thenIndex];
                    
                    $specPath = (join-path $buildDirectory "$specName.$givenIndex.$whenIndex.$thenIndex")
                    "  ($givenIndex,$whenIndex,$thenIndex @ $specPath)"
                    
                    $null = mkdir $specPath

                    $xmlPath = (join-path $specPath "test.xml")
                    $expectedPath = (join-path $specPath "expected.xml")
                    $sutPath = (join-path $specPath "test.ps1")
                    
                    $given.lines | set-content $xmlPath
                    $then.lines | set-content $expectedPath
                    
                    $whenExpression = [string]::Join("`n", @($when.lines))
                    $when.lines | set-content $sutPath
                    
                    & $sutPath $xmlPath
                    
                    assert-xml-equals $xmlPath $expectedPath
                }
                
                for($expectedErrorsIndex = 0; $expectedErrorsIndex -lt $expectedErrors.length; $expectedErrorsIndex++) {
                
                    $stringsToCheck = $expectedErrors[$expectedErrorsIndex].lines;
                
                    $specPath = (join-path $buildDirectory "$specName.$givenIndex.$whenIndex.error$expectedErrorsIndex")
                    "  ($givenIndex,$whenIndex,error $expectedErrorsIndex @ $specPath)"
                
                    $null = mkdir $specPath

                    $xmlPath = (join-path $specPath "test.xml")
                    $sutPath = (join-path $specPath "test.ps1")
                    
                    $given.lines | set-content $xmlPath
                    
                    $whenExpression = [string]::Join("`n", @($when.lines))
                    $when.lines | set-content $sutPath
                    
                    $sawError = $false;
                    try {
                    
                        & $sutPath $xmlPath
                        
                    } catch {
                    
                        $sawError = $true;

                        $errorString = $_.Exception.Message;
                        
                        foreach($expectedString in $stringsToCheck) {
                            Assert $errorString.Contains($expectedString) "Did not find string '$expectedString'.  Actual error was: $errorString"
                        }
                    }

                    Assert $sawError "Expected an error to be thrown, none was."
                }
            }
        }
    }
}





