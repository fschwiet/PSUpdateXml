Editing XML from powershell has always seemed harder than it should be.  Maybe I am missing some article..  Reading XML is fairly easy, I like I can cast a string to XML.  I think changing an XML file should be as easy.  I think this module makes that true (if you don't mind XPATH).  It is simple code to rewrite on a project basis, but I figure it's worth writing once with tests.

See the "specs" folder to see specifics on how to use PSUpdateXML.psm1.

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