
properties {
    $t1 = ".\test1.xml"
    $t2 = ".\test2.xml"
    $t3 = ".\test3.xml"
}

task default -depends CheckSpecs


function assert-xml-equals([System.IO.FileInfo]$file1, [System.IO.FileInfo]$file2) {

    $f1 = (resolve-path $file1)
    $f2 = (resolve-path $file2)

    $comparisonResult = & .\tools\XmlDiffPatch\Bin\XmlDiff.exe $f1 $f2
    
    Assert ($comparisonResult -like "*Files are identical*") "Expected XML files to equal, there were different.  Filesnames: '$f1', '$f2'";
    
    "hi"
}


task CheckSpecs {

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
        
        "  givens: $($givens.length), whens: $($whens.length), thens: $($whens.length)"
        
        foreach($givenIndex in 1..$givens.length) {
            $given = $givens[$givenIndex];
            
            foreach($whenIndex in 1..$whens.length) {
                $when = $whens[$whenIndex];
                
                foreach($thenIndex in 1..$thens.length) {
                    $then = $thens[$thenIndex];
                    
                    "  ($givenIndex,$whenIndex,$thenIndex)"
                }
            }
        }
    
    }
}


