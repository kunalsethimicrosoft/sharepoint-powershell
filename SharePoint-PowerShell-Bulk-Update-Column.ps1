function SPO-MultiColumnSystemChange {
<#
    .Synopsis
    Connect to SharePoint Online
    
    Requires:
    1. PowerShell module - Microsoft.Online.SharePoint.PowerShell, ver. 6906 or higher
    2. SharePoint Client Components, ver. 6906 or higher
        2a. Microsoft.SharePoint.Client.dll
        2b. Microsoft.SharePoint.Client.Runtime.dll

    .DESCRIPTION
    Enables mass changing values in single column. Object search i recursive. By default it searchest for files and folders.
    Enables to add Prefix, Sufix or Replace value in column. You can use CLAMQuery to change only selected values or use default setting to mass change on all files, directories or both.
    After operation generate Log file put on desktop of user.

    .PARAMETER Url
    Provide the site collection url.
    Warrning! - If site collection have spacial chars it can crush whit error if so close address in ""
    
    .PARAMETER credential
    Provide the credential for connecting to web.
    If not provided in variable you will be ask for it.
    
    .PARAMETER ConfigFile
    Provide configuration file for what and where to change. Configuration file is CSV file with columns ListOrLibrary, Column, Replace, Prefix, Sufix, OnlyAllFiles, OnlyAllFolders, CLAMQuery

    ListOrLibrary - Name of list or library
    Column - Name of column on what you want to preform operation
    Replace - Replace content with given value
    Prefix - Add prefix to existing value. If used with "Replace" it will first replace value in column and then add Prefix.
    Sufix - Add sufix to existing value. If used with "Replace" it will first replace value in column and then add Sufix.
    OnlyAllFiles - If you put True will get only all files. If set tu TRUE: set OnlyAllFolders to FALSE and leave CLAMQuery empty
    OnlyAllFolders - If you put True will get only all folders. If set tu TRUE: set OnlyAllFiles to FALSE and leave CLAMQuery empty
    
 
    .EXAMPLE

    $credential = Get-Credential
    SPO-MultiColumnSystemChange -Url https://tenant.sharepoint.com/sites/YourSite -LibraryOrList Documents -Credential $credential -ConfigFile C:\Temp\Modify_items_metadata.config

    Here you will get only files with file name contaning Word001 in it, whitin library Documents. Then it will change in column choice text to Two.

    Sample configuration file:

    ListOrLibrary;Column;Replace;Prefix;Sufix;OnlyAllFiles;OnlyAllFolders;CLAMQuery
    Documents;Title;Jeden;AddingPref;AddingSuf;true;false; - In Document library replace in "Title" column value and add prefix and sufix to it on all files
    Documents;Numbers;101;;;false;true; - In Document library replace in "Numbers" column to 101 on all folders
    Documents;choice;New;;;false;false; - In Document library change "choice" column to New on all files and folders/objects
    Administrative;Title;OnlyMe;;_File;false;false;<Where><Eq><FieldRef Name='FSObjType' /><Value Type='Integer'>0</Value></Eq></Where> - In Administrative library Replace Title on files to OnlyMe and add prefix
    List;Todo;2018-6-15 08:00:00;;;false;false;<Where><Geq><FieldRef Name='Todo' /><Value Type='DateTime'>2018-01-09T12:00:00Z</Value></Geq></Where> - In list List replace in column Todo date to new value only where date is greater or equal set specific value

    

#>
param (
    [Parameter(Mandatory=$true, HelpMessage="Site URL")]
		[string]$Url,
    [Parameter(Mandatory=$false, HelpMessage="Site collection administrator credentials")]
		[PSCredential]$Credential,
    [Parameter(Mandatory=$true, HelpMessage="File with configuration")]
		[string]$ConfigFile=$null
)

#Define and cleary vars    
$Library = ""
$table=@()

#Check if credential was provided if not get them
if($Credential -eq $null){
$Credential=Get-Credential
}


#Connect to site
    Write-Host "Connecting to site:" $Url -ForegroundColor Cyan
    $SecurePassword = $Credential.Password
    $UserName = $Credential.UserName
    $clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($Url)
    $creds = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, $SecurePassword)
    $clientContext.Credentials = $creds

#Read configuration file and preform actions

    if ($ConfigFile -and (Test-Path $ConfigFile)) {
    
    #Import configuration file. Sort for better preformence
    Write-Host "Config file provided. Reding config..." -ForegroundColor Green
    $configuration = Import-Csv -Path $ConfigFile -Delimiter ";"
    $configuration = $configuration | sort -Property ListOrLibrary, Column

    Foreach ($operation in $configuration){
        if($Library -ne $operation.ListOrLibrary){
        Write-Host "Old library parm:" $Library -ForegroundColor Yellow
        $Library = $operation.ListOrLibrary
        Write-Host "New library parm:" $Library -ForegroundColor Magenta
        }
        
        if (!$operation.CLAMQuery){
            Write-Host "No CLAMQuery using default settings" -ForegroundColor Yellow
            if($operation.OnlyAllFiles -eq "true"){$CLAMQuery="<Where><Eq><FieldRef Name='FSObjType' /><Value Type='Integer'>0</Value></Eq></Where>"}
            elseif($operation.OnlyAllFolders -eq "true"){$CLAMQuery="<Where><Eq><FieldRef Name='FSObjType' /><Value Type='Integer'>1</Value></Eq></Where>"}
            else{$CLAMQuery="<Where></Where>"}
            Write-Host $CLAMQuery -ForegroundColor Gray
            }
            else {
            Write-Host "Query present" -ForegroundColor Green
            $CLAMQuery=$operation.CLAMQuery
            Write-Host $CLAMQuery -ForegroundColor Gray
            }
        $Column = $operation.Column
        
        # Prepare the query
        $query = New-Object Microsoft.SharePoint.Client.CamlQuery
        $query.ViewXml = "<View Scope='RecursiveAll'>" + 
        "<Query>"+
        $CLAMQuery+
        "</Query>"+
        "</view>"
 
        #Get list and list items
        #List connecting
        Write-Host "Retriving items from list/library:" $Library -ForegroundColor Cyan
        $list = $clientContext.Web.Lists.GetByTitle($Library)
        $clientContext.Load($list)

        #Get Items
        $listItems = $list.getItems($query)
        $clientContext.Load($listItems)
        Execute-SPOQuery $clientContext

        #Preform operation on items


        foreach ($item in $listItems){
            $old_value=""
            $new_value=""
            $old_value=$item[$Column]
            if($operation.Replace) {$item[$Column] = $operation.Replace}
            if($operation.Prefix) {$item[$Column] = $operation.Prefix + $item[$Column]}
            if($operation.Sufix) {$item[$Column] = $item[$Column] + $operation.Sufix}
            $item.SystemUpdate()
            $new_value=$item[$Column]
            Write-Host "Item ID:" $item["ID"] "and path" $item["FileRef"] ", Filed/Column:" $Column ", From:" $old_value ", To:" $new_value -ForegroundColor DarkYellow
            $wrapper = New-Object PSObject -Property ([ordered]@{"Library" =$Library; "Item ID"=$item["ID"];"Path to object"=$item["FileRef"];"Fild/Column"=$Column;"Old Value"=$old_value;"New_Value"=$new_value})
            $table += $wrapper
            }  
        
    }
    $table | ft
    Write-Host "Do you want to execute (Y/N)?" -ForegroundColor Yellow
    $execute_change = Read-Host -Prompt "Anwser"
        If($execute_change -eq "Y"){
        Execute-SPOQuery $clientContext
        Write-Host "Dumping log change table" -ForegroundColor Yellow
        $logfilenamedate = Get-Date -UFormat "%Y-%m-%d_%H#%M#%S"
        $logfilename = "ChangeLogTable-"+ $LibraryOrList + "-" + $logfilenamedate + ".csv"
        $table | Export-Csv -Path "$env:HOMEPATH\Desktop\$logfilename" -Delimiter ";" -NoClobber -NoTypeInformation
        Write-Host "Dump file path: $env:HOMEPATH\Desktop\$logfilename" -ForegroundColor DarkGray
        }
        else {
        write-host "Exiting..." -ForegroundColor Gray
        }
    }
    else    {
    Write-Host "No configuration file provided." -ForegroundColor Red
    Write-Host "Ending script" -ForegroundColor Red
    }
}
