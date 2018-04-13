$ver = $host | select version 
if($Ver.version.major -gt 1) {$Host.Runspace.ThreadOptions = "ReuseThread"} 
if(!(Get-PSSnapin Microsoft.SharePoint.PowerShell -ea 0)) 
{ 
Write-Progress -Activity "Loading Modules" -Status "Loading Microsoft.SharePoint.PowerShell" 
Add-PSSnapin Microsoft.SharePoint.PowerShell 
} 
 
## 
#Set Static Variables 
## 
 
$SourceWebURL = "http://www.contoso.com" 
$SourceLibraryTitle = "Shared Documents" 
$DestinationWebURL = "http://archive.contoso.com/WWWArchive" 
$DestinationLibraryTitle = "Shared Documents" 
 
## 
#Begin Script 
## 
 
$sWeb = Get-SPWeb $SourceWebURL 
$sList = $sWeb.Lists | ? {$_.Title -eq $SourceLibraryTitle} 
$dWeb = Get-SPWeb $DestinationWebURL 
$dList = $dWeb.Lists | ? {$_.title -like $DestinationLibraryTitle} 
 
$AllFolders = $sList.Folders 
$RootFolder = $sList.RootFolder 
$RootItems = $RootFolder.files 
 
foreach($RootItem in $RootItems) 
{ 
    $sBytes = $RootItem.OpenBinary() 
    $dFile = $dList.RootFolder.Files.Add($RootItem.Name, $sBytes, $true) 
 
    $AllFields = $RootItem.Item.Fields | ? {!($_.sealed)} 
 
    foreach($Field in $AllFields) 
    { 
        if($RootItem.Properties[$Field.Title]) 
        { 
            if(!($dFile.Properties[$Field.title])) 
            { 
                $dFile.AddProperty($Field.Title, $RootItem.Properties[$Field.Title]) 
            } 
            else 
            { 
                $dFile.Properties[$Field.Title] = $RootItem.Properties[$Field.Title] 
            } 
        } 
    } 
    $dFile.Update() 
} 
 
foreach($Folder in $AllFolders) 
{ 
    Remove-Variable ParentFolderURL 
    $i = 0 
     
    $FolderURL = $Folder.url.Split("/") 
         
    while($i -lt ($FolderURL.count-1)) 
    { 
    $ParentFolderURL = "$ParentFolderURL/" + $FolderURL[$i] 
    $i++ 
    } 
     
    $CurrentFolder = $dList.Folders | ? {$_.url -eq $ParentFolderURL.substring(1)} 
    if(!($CurrentFolder.Folders | ? {$_.name -eq $Folder.Name})) 
    { 
        $NewFolder = $dlist.Folders.Add(("$DestinationWebURL" + $ParentFolderURL), [Microsoft.SharePoint.SPFileSystemObjectType]::Folder, $Folder.name) 
        $NewFolder.update() 
    } 
    else 
    { 
        $NewFolder = $dList.Folders | ? {$_.name -eq $Folder.Name} 
    } 
    $AllFiles = $sList.Items 
    $sItems = $Folder.folder.Files 
     
    if($Folder.Folder.Files.count -gt 0) 
    { 
        foreach($item in $sItems) 
        { 
             
            $Relative = ($Item.ServerRelativeUrl).substring(1) 
            $TargetItem = $AllFiles | ? {$_.URL -eq $Relative} 
            $sBytes = $TargetItem.File.OpenBinary() 
            $dFile = $Newfolder.Folder.Files.Add($TargetItem.Name, $sBytes, $true) 
            $AllFields = $TargetItem.Fields | ? {!($_.sealed)} 
             
            foreach($Field in $AllFields) 
            { 
                if($TargetItem.Properties[$Field.Title]) 
                { 
                    if(!($dFile.Properties[$Field.title])) 
                    { 
                        $dFile.AddProperty($Field.Title, $TargetItem.Properties[$Field.Title]) 
                    } 
                    else 
                    { 
                        $dFile.Properties[$Field.Title] = $TargetItem.Properties[$Field.Title] 
                    } 
                } 
            } 
            $dFile.Update() 
        } 
    } 
}
