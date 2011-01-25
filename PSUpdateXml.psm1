
$currentNamespaceManager = $null;
$currentNode = $null;

function with-current-node($node, $action) {
    $originalNode = $currentNode
    $currentNode = node
    try {
        $action
    } finally {
        $currentNode = $originalNode
    }
}

function update-xml([System.IO.FileInfo]$xmlFile, [ScriptBlock]$action) {

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


function get-xml([string] $xpath) {
    
    $nodes = $currentNode.SelectNodes($xpath, $currentNamespaceManager)
     
    foreach ($node in $nodes) {
        if ($node.NodeType -eq "Element") {
            $node.InnerXml
        }
        else {
            $node.Value
        }
    }
}


function set-xml([string] $xpath, [string] $value) {

    $nodes = $currentNode.SelectNodes($xpath, $currentNamespaceManager)
     
    foreach ($node in $nodes) {
        if ($node.NodeType -eq "Element") {
            $node.InnerXml = $value
        }
        else {
            $node.Value = $value
        }
    }
}


function remove-xml([string] $xpath) {

    $nodes = $currentNode.SelectNodes($xpath)
     
    foreach($node in $nodes) {
        $nav = $node.CreateNavigator();
        $nav.DeleteSelf();
    }
}


function for-xml([string] $xpath, [ScriptBlock] $action) {

    $originalNode = $currentNode
    
    try {
        $nodes = $currentNode.SelectNodes($xpath)

        foreach($node in $nodes) {
            $currentNode = $node;
            & $action;
        }

    } finally {
        $currentNode = $originalNode
    }
}


export-modulemember -function update-xml,add-xmlnamespace,get-xml,set-xml,remove-xml,for-xml


