using System;
using System.IO;
using System.Xml;
using System.Text;
using System.Reflection;
using Microsoft.XmlDiffPatch;

namespace Microsoft.XmlDiffPatch
{

class TestXmlDiff
{

	static void Main( string[] args )
	{
        bool bFragment = false;
        bool bNodes = false;
        XmlDiffAlgorithm algorithm = XmlDiffAlgorithm.Auto;

        try
        {
            if ( args.Length < 3 )
            {
                WriteUsage();
                return;
            }

            XmlDiffOptions options = XmlDiffOptions.None;

            // process options
            int curArgsIndex = 0;
            string optionsString = string.Empty;
            while ( args[curArgsIndex][0] == '/' )
            {
                if ( args[curArgsIndex].Length != 2 )
                {
                    System.Console.Write( "Invalid option: " + args[curArgsIndex] + "\n" );
                    return;
                }
                
                switch ( args[curArgsIndex][1] )
                {
                    case 'o':
                        options |= XmlDiffOptions.IgnoreChildOrder;
                        break;
                    case 'c':
                        options |= XmlDiffOptions.IgnoreComments;
                        break;
                    case 'p':
                        options |= XmlDiffOptions.IgnorePI;
                        break;
                    case 'w':
                        options |= XmlDiffOptions.IgnoreWhitespace;
                        break;
                    case 'n':
                        options |= XmlDiffOptions.IgnoreNamespaces;
                        break;
                    case 'r':
                        options |= XmlDiffOptions.IgnorePrefixes;
                        break;
                    case 'x':
                        options |= XmlDiffOptions.IgnoreXmlDecl;
                        break;
                    case 'd':
                        options |= XmlDiffOptions.IgnoreDtd;
                        break;
                    case 'e':
                        bNodes = true;
                        break;
                    case 'f':
                        bFragment = true;
                        break;
                    case 't':
                        algorithm = XmlDiffAlgorithm.Fast;
                        break;
                    case 'z':
                        algorithm = XmlDiffAlgorithm.Precise;
                        break;
                    default:
                        System.Console.Write( "Invalid option: " + args[curArgsIndex] + "\n" );
                        return;
                }
                optionsString += args[curArgsIndex][1];
                curArgsIndex++;

                if ( args.Length - curArgsIndex < 3 )
                {
                    WriteUsage();
                    return;
                }
            }

            // extract names from command line
            string sourceXml = args[ curArgsIndex ];
            string targetXml = args[ curArgsIndex + 1 ];
            string diffgram  = args[ curArgsIndex + 2 ];
            bool bVerify = ( args.Length - curArgsIndex == 4 ) && ( args[ curArgsIndex + 3 ] == "verify" );

            // write legend
            string legend = sourceXml.Substring( sourceXml.LastIndexOf("\\") + 1 ) + " & " +
                            targetXml.Substring( targetXml.LastIndexOf("\\") + 1 ) + " -> " +
                            diffgram.Substring( diffgram.LastIndexOf("\\") + 1 );
            if ( optionsString != string.Empty )
                legend += " (" + optionsString + ")";

            if ( legend.Length < 60 )
                legend += new String( ' ', 60 - legend.Length );
            else 
                legend += "\n" + new String( ' ', 60 );

            System.Console.Write( legend );

            // create diffgram writer
            XmlWriter DiffgramWriter = new XmlTextWriter( diffgram, new System.Text.UnicodeEncoding() );

            // create XmlDiff object & set the options
            XmlDiff xmlDiff = new XmlDiff( options );
            xmlDiff.Algorithm = algorithm;

            // compare xml files
            bool bIdentical;
            if ( bNodes ) {
                if ( bFragment ) {
                    Console.Write( "Cannot have option 'd' and 'f' together." );
                    return;
                }

                XmlDocument sourceDoc = new XmlDocument();
                sourceDoc.Load( sourceXml );
                XmlDocument targetDoc = new XmlDocument();
                targetDoc.Load( targetXml );

                bIdentical = xmlDiff.Compare( sourceDoc, targetDoc, DiffgramWriter );
            }
            else {
                bIdentical = xmlDiff.Compare( sourceXml, targetXml, bFragment, DiffgramWriter );
            }
            
/*
 *             if ( bMeasurePerf ) {
                Type type = xmlDiff.GetType();
                MemberInfo[] mi = type.GetMember( "_xmlDiffPerf" );
                if ( mi != null && mi.Length > 0 ) {
                    XmlDiffPerf xmldiffPerf = (XmlDiffPerf)type.InvokeMember( "_xmlDiffPerf", BindingFlags.GetField, null, xmlDiff, new object[0]);
                }
            }
            */

            // write result
            if ( bIdentical )
                System.Console.Write( "identical" );
            else
                System.Console.Write( "different" ); 

            DiffgramWriter.Close();

            // verify
            if ( !bIdentical && bVerify )
            {
                XmlNode sourceNode;
                if ( bFragment )
                {
                    NameTable nt = new NameTable();
                    XmlTextReader tr = new XmlTextReader( new FileStream( sourceXml, FileMode.Open, FileAccess.Read ),
                                                          XmlNodeType.Element,
                                                          new XmlParserContext( nt, new XmlNamespaceManager( nt ),
                                                                                string.Empty, XmlSpace.Default ) );
                    XmlDocument doc = new XmlDocument();
                    XmlDocumentFragment frag = doc.CreateDocumentFragment();

                    XmlNode node;
                    while ( ( node = doc.ReadNode( tr ) ) != null ) {
                        if ( node.NodeType != XmlNodeType.Whitespace )
                            frag.AppendChild( node );
                    }

                    sourceNode = frag;
                }
                else
                {
                    // load source document
                    XmlDocument sourceDoc = new XmlDocument();
                    sourceDoc.XmlResolver = null;
                    sourceDoc.Load( sourceXml );
                    sourceNode = sourceDoc;
                }

                // patch it & save
                new XmlPatch().Patch( ref sourceNode, new XmlTextReader( diffgram ) );
                if ( sourceNode.NodeType == XmlNodeType.Document )
                    ((XmlDocument)sourceNode).Save( "_patched.xml" );
                else {
                    XmlTextWriter tw = new XmlTextWriter( "_patched.xml", Encoding.Unicode );
                    sourceNode.WriteTo( tw );
                    tw.Close();
                }

				XmlWriter diffgramWriter2 = new XmlTextWriter( "_2ndDiff.xml", new System.Text.UnicodeEncoding() );

                // compare patched source document and target document
                if ( xmlDiff.Compare( "_patched.xml", targetXml, bFragment, diffgramWriter2 ) )
                    System.Console.Write( " - ok" );
                else
                    System.Console.Write( " - FAILED" );

				diffgramWriter2.Close();
            }
            System.Console.Write( "\n" );
        }
        catch ( Exception e )
        {
            Console.Write("\n*** Error: " + e.Message + " (source: " + e.Source + ")\n");
        }

        if ( System.Diagnostics.Debugger.IsAttached ) 
        {
            Console.Write( "\nPress enter...\n" );
            Console.Read();
        }
	}

    static private void WriteUsage()
    {
        System.Console.Write( "TestXmlDiff - test application for XmlDiff\n" );
        System.Console.Write( "USAGE: testapp [options] <source xml> <target xml> <diffgram> [verify]\n\n" +
                                "Options:\n" +
                                "/o    ignore child order\n" +
                                "/c    ignore comments\n" + 
                                "/p    ignore processing instructions\n" + 
                                "/w    ignore whitespaces, normalize text value\n" + 
                                "/n    ignore namespaces\n" +
                                "/r    ignore prefixes\n" + 
                                "/x    ignore XML declaration\n" );
    }
}
}
