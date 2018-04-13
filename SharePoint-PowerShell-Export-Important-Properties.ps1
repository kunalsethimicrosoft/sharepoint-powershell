## script is used to export some OneDrive for Business information for all users having a provisioned MySite

Import-Module Microsoft.Online.SharePoint.Powershell
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.UserProfiles.dll"

$creds = Get-Credential -Message "Please specify the global admin credentials"
# please specify the desired exportpath
$exportFile = "C:\tmp\export.csv"
# please specify your tenantname
$tenantName = "yourTenantName"
$mySiteUrl = "https://$($tenantName)-my.sharepoint.com";
$tenantUrl = "https://$($tenantName)-admin.sharepoint.com";


Write-Host "Starting operation" -ForegroundColor Yellow
Connect-SPOService $tenantUrl -Credential $creds

$ctx = New-Object Microsoft.SharePoint.Client.ClientContext($mySiteUrl)
$ctx.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($creds.UserName, $creds.Password)

$siteUsers = $ctx.Web.SiteUsers;
$ctx.Load($siteUsers);
$ctx.ExecuteQuery();

# the headings of the csv file
("Url","Owner;StorageQuota;StorageUsageCurrent;SharingCapability") -join ";" | Out-File -FilePath $exportFile
$pManager = New-Object Microsoft.SharePoint.Client.UserProfiles.PeopleManager($ctx)
$siteCount = 0;

foreach ($user in $siteUsers)
{
    if ($user.PrincipalType -ne [Microsoft.SharePoint.Client.Utilities.PrincipalType]::User) {
        continue;
    }

    # you can also load all user profile properties through the method 'GetUserProfilePropertiesFor'. 
    # This retunrs a collection that needs to be parsed.
    # please note that that operation might be slower since it retrieves more properties from the service.
    $personalSpace = $pManager.GetUserProfilePropertyFor($user.LoginName, "PersonalSpace");
    $ctx.ExecuteQuery();
    if ([String]::IsNullOrEmpty($personalSpace.Value) -ne $true)
    {   
        $mySiteFullURL = $mySiteUrl + $personalSpace.Value.TrimEnd('/');
        $siteCount++;
        Write-Progress -Activity “Processing sites” -status “Processing $mySiteFullURL” -percentComplete ($siteCount / $siteUsers.Count * 100)
        $spoSite = Get-SPOSite $mySiteFullURL
        # extend it here with the properties you want. remember to update the headings before
        ($spoSite.Url,$spoSite.Owner,$spoSite.StorageQuota,$spoSite.StorageUsageCurrent,$spoSite.SharingCapability) -join ";"| Out-File -FilePath $exportFile -Append
    }
}
Write-Host "Operation completed" -ForegroundColor Yellow
Disconnect-SPOService





