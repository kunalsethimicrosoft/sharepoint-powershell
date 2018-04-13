cls
# the path here may need to change if you used e.g. C:\Lib.. 
Add-Type -Path "C:\Install\SharePointOnlinePowerShellScripts\ISAPI\Microsoft.SharePoint.Client.dll" 
Add-Type -Path "C:\Install\SharePointOnlinePowerShellScripts\ISAPI\Microsoft.SharePoint.Client.Runtime.dll" 
Add-Type -Path "C:\Install\SharePointOnlinePowerShellScripts\ISAPI\Microsoft.SharePoint.Client.Taxonomy.dll" 
# note that you might need some other references (depending on what your script does) for example:

#Site collection URL where we need to create the site columns  
$siteurl = Read-Host -Prompt 'Provide the site url'

#User name and Passwords  
$userName = Read-Host -Prompt 'Provide the user name' 
$password = Read-Host -Prompt 'Provide the password' -AsSecureString

#Path of the elements.xml file with field list
#"C:\Install\siteColumns.xml"
$xmlFile = Read-Host -Prompt 'Provide full path of the xml file' 

#client context object and setting the credentials   
[Microsoft.SharePoint.Client.ClientContext]$clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($siteurl)   

# connect/authenticate to SharePoint Online and get ClientContext object..   
$clientContext.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($userName, $password) 

if (!$clientContext.ServerObjectIsNull.Value) 
{ 
    Write-Host "Connected to SharePoint Online site: '$siteurl'" -ForegroundColor Green 
	
	#get the respective web  
	$site = $clientContext.Site  
	$web = $site.RootWeb  
	 
	#Get all fields collection  
	$fields = $web.Fields   
	$clientContext.Load($fields)

	$clientContext.Load($web)  
	$clientContext.ExecuteQuery()
	
    #Create a XML File to Export Fields 
    New-Item $xmlFile -type file -force 
    
    #Wrap Field Schema XML inside <Fields> Element 
    Add-Content $xmlFile "<?xml version=""1.0"" encoding=""utf-8""?>" 
    Add-Content $xmlFile "`n<Elements>"

    #Export All Site Columns of specific Group to XML file 
    $web.Fields | ForEach-Object {
        $clientContext.Load($_)  
	    $clientContext.ExecuteQuery()

        #if ($_.Group -eq "Crescent Travel Request") { 
            Add-Content $xmlFile $_.SchemaXml 
        #}
        Write-Host $_.Title
    } 
    
    #Closing Wrapper 
    Add-Content $xmlFile "</Elements>" 

    Write-Host "Export completed."


}
