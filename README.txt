Editing XML from powershell has always seemed harder than it should be.  Maybe I am missing some article..  Reading XML is fairly easy, I like I can cast a string to XML.  I think changing an XML file should be as easy.  I think this module makes that true (if you don't mind XPATH).  It is simple code to rewrite on a project basis, but I figure it's worth writing once with tests.

See the "specs" folder to see specifics on how to use PSUpdateXML.psm1.

  update-xml [System.IO.FileInfo]xmlFile [ScriptBlock]action
    - Runs $action against $xmlFile.  $action can in turn call set-xml, for-xml, etc to modify that XML file.
  
  Every other function is called within the script block passed to update-xml.  All calls taking XPATH expression are interpreted relative the current node.  
  
  for-xml [QUANTIFIER] [string]xpath [ScriptBlock]action
    Iterates over every node matching xpath.  Calls action with the current node as that matching node.
  
  set-xml [QUANTIFIER] [string]xpath [string]value
    Sets the xml tag or attribute value at the xpath location.
    
  get-xml [QUANTIFIER] [string]xpath
    Returns the xml tag or attribute value at the xpath location
    
  remove-xml [QUANTIFIER] [string]xpath
    Removes tags or attributes at the xpath location.
    
  append-xml [QUANTIFIER] [string]xpath [string]value
    Appends the text as XML after the last child of the current node.
    
  add-xmlnamespace [string]name [string]value
    - Allow a namespace be specified in your XPATH expressions
    - If you can't get your XPATH to match, it may be the namespace..
    - reference: https://github.com/fschwiet/PSUpdateXml/blob/master/specs/can_handle_namespaces.txt

  QUANTIFIER: optionally use -exactlyOnce, -atLeastOnce, or -atMostOnce
  

Sample usage (update-xml, set-xml, append-xml):

    import-module .\PSUpdateXml.psm1  # this is the only file you need to deploy, everything else in the project path is for testing

    $webConfigFilepath = (join-path (join-path $stagingDirectory "WebAppProjectName") "web.config");

    cp $webConfigFilepath "$webConfigFilepath.backup"

    update-xml $webConfigFilepath {

        #(deployment information is already initialized to $deploy)

        set-xml -exactlyOnce "//configuration/system.web/compilation/@debug" $deploy.debug

        @("SiteName", "BaseUrl", "CdnUrl", "AdminUsername", "AdminPassword", "AddonPath", 
            "NoReplySiteEmail", "AllowUnsafeHooks", "SmtpHost", "SmtpPort", "RavenPath") | % {

            set-xml -exactlyOnce "//configuration/applicationSettings/*/setting[@name='$($_)']/value" $deploy[$_]
        }

        foreach ($connectionString in $deploy.connectionStrings.keys) {

            $connectionStringValue = $deploy.connectionStrings[$connectionString];

            append-xml -exactlyOnce "//configuration/connectionStrings" "<add name=`"$connectionString`" connectionString=`"$connectionStringValue`"/>"
        }

        if ($deploy.elmahConfiguration) {
            set-xml "//configuration/elmah" $deploy.elmahConfiguration
        }
    }
    
    
    
To run the tests, run .\Psake.ps1 from powershell.
