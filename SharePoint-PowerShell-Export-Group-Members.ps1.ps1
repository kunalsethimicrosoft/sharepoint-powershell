$aClient = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client")
$aClientRuntime = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.Runtime")

Function Get-UserInfo {
    Param ([string]$id) 
    Process {    
        $uList = $web.Lists.GetByTitle('User Information List')
        $userItem = $uList.GetItemById($id);
        $ctx.Load($userItem)
        $ctx.ExecuteQuery()
        $obj = New-Object PSObject 
        $obj | Add-Member -type NoteProperty -Name Title -Value $userItem['Title']
        $obj | Add-Member -type NoteProperty -Name UserName -Value $userItem['UserName']
        $obj | Add-Member -type NoteProperty -Name JobTitle -Value $userItem['JobTitle']
        $obj | Add-Member -type NoteProperty -Name Department -Value $userItem['Department']
        return $obj
    }
}

$siteUrl = "https://crazylabs.sharepoint.com/sites/rajesh"
$grpName = "Rajesh_s Dev Site Owners"
$exportFile = "C:\export-grp.csv"

$ctx = New-Object Microsoft.SharePoint.Client.ClientContext($siteUrl) 
$username = Read-Host -Prompt "Enter Username" 
$password = Read-Host -Prompt "Enter password" -AsSecureString 
$ctx = New-Object Microsoft.SharePoint.Client.ClientContext($siteUrl) 

$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($username, $password)
$ctx.Credentials = $credentials 

$web = $ctx.Web
$ctx.Load($web) 
$group = $web.SiteGroups.GetByName($grpName)                           
$ctx.Load($group)
$ctx.Load($group.Users)
$ctx.ExecuteQuery()  

$group.Users | ForEach-Object { Get-UserInfo($_.Id) } | Export-Csv $exportFile -NoTypeInformation -append 

