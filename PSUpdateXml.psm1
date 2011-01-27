
$currentNamespaceManager = $null;
$currentNode = $null;


function update-xml([System.IO.FileInfo]$xmlFile, 
    [ScriptBlock]$action) {

    $doc = New-Object System.Xml.XmlDocument
    $currentNamespaceManager = New-Object System.Xml.XmlNamespaceManager $doc.NameTable
    $currentNode = $doc

    $xmlFile = (resolve-path $xmlFile).path;

    $doc.Load($xmlFile)

    & $action
     
    $doc.Save($xmlFile)
}

function add-xmlnamespace([string] $name, [string] $value) {
    $currentNamespaceManager.AddNamespace( $name, $value);
}

function check-quantifier-against-nodes($nodes, $exactlyonce,  $atleastonce,  $atmostonce) {
    
    if ($exactlyonce) {
        Assert ($nodes.length -eq 1) "Expected to find one match, actually found $($nodes.length) matches for xpath expression `"$xpath`"."
    }
}


function get-xml([string] $xpath, 
    [switch]$exactlyonce = $false, 
    [switch]$atleastonce = $false, 
    [switch]$atmostonce = $false) {
    
    $nodes = @($currentNode.SelectNodes($xpath, $currentNamespaceManager))
     
    check-quantifier-against-nodes $nodes $exactlyonce $atleastonce $atmostonce

    foreach ($node in $nodes) {
        if ($node.NodeType -eq "Element") {
            $node.InnerXml
        }
        else {
            $node.Value
        }
    }
}

function set-xml(
    [string] $xpath, 
    [string] $value, 
    [switch]$exactlyonce = $false, 
    [switch]$atleastonce = $false, 
    [switch]$atmostonce = $false) {

    $nodes = @($currentNode.SelectNodes($xpath, $currentNamespaceManager))
    
    check-quantifier-against-nodes $nodes $exactlyonce $atleastonce $atmostonce
     
    foreach ($node in $nodes) {
        if ($node.NodeType -eq "Element") {
            $node.InnerXml = $value
        }
        else {
            $node.Value = $value
        }
    }
}


function remove-xml([string] $xpath, 
    [switch]$exactlyonce = $false, 
    [switch]$atleastonce = $false, 
    [switch]$atmostonce = $false) {

    $nodes = @($currentNode.SelectNodes($xpath))
     
    check-quantifier-against-nodes $nodes $exactlyonce $atleastonce $atmostonce

    foreach($node in $nodes) {
        $nav = $node.CreateNavigator();
        $nav.DeleteSelf();
    }
}


function for-xml([string] $xpath, 
    [ScriptBlock] $action, 
    [switch]$exactlyonce = $false, 
    [switch]$atleastonce = $false, 
    [switch]$atmostonce = $false) {

    $originalNode = $currentNode
    
    try {
        $nodes = @($currentNode.SelectNodes($xpath))

        check-quantifier-against-nodes $nodes $exactlyonce $atleastonce $atmostonce

        foreach($node in $nodes) {
            $currentNode = $node;
            & $action;
        }

    } finally {
        $currentNode = $originalNode
    }
}


export-modulemember -function update-xml,add-xmlnamespace,get-xml,set-xml,remove-xml,for-xml


