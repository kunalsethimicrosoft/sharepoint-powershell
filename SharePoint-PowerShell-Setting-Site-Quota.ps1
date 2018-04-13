function Set-SPOSiteQuota {
<#
    .Synopsis
    Connect to sharepoint online first
    
    .DESCRIPTION
    requires module Microsoft.Online.SharePoint.PowerShell
    
    .PARAMETER Url
    Provide the site collection url.
    Warrning! - If site collection have spacial chars it can crush whit error if so close address in ""
    
    .EXAMPLE
    The following would set qouta on site collection
    Set-SPOSiteQuota -URL "https://tenant.sharepoint.com/teams/IT"
#>

param (
    [Parameter(Mandatory=$true,Position=1)]
		[string]$Url
)
    #Get site and current usage  
    $site = Get-SPOSite -Identity $url 

    #propose quota for each site collection
    #check usage if it is under 90% of propose quota
    if($site.StorageUsageCurrent -le "4608") {$StorageQuota = "5120"; $StorageQuotaWarning="4608"}
    elseif ($site.StorageUsageCurrent -le "9216") {$StorageQuota = "10240"; $StorageQuotaWarning="9216"}
    elseif ($site.StorageUsageCurrent -le "23040") {$StorageQuota = "25600"; $StorageQuotaWarning="23040"}
    elseif ($site.StorageUsageCurrent -le "46080") {$StorageQuota = "51200"; $StorageQuotaWarning="46080"}
    elseif ($site.StorageUsageCurrent -le "92160") {$StorageQuota = "102400"; $StorageQuotaWarning=92160}
    elseif ($site.StorageUsageCurrent -le "184320") {$StorageQuota = "204800"; $StorageQuotaWarning="184320"}
    elseif ($site.StorageUsageCurrent -gt "184320") {$StorageQuota = $site.StorageQuota * 1.1; $StorageQuotaWarning=$site.StorageQuotaWarningLevel * 1.1}

    try
    {
    #change quota
    Write-Host "Trying to change quota for:" $url -ForegroundColor Cyan
    Set-SPOSite -Identity $url -StorageQuota $StorageQuota -StorageQuotaWarningLevel $StorageQuotaWarning
    }
    catch
    {
    Write-Host "Failed setting quota for site:" $url -ForegroundColor Red
    $error[0]
    }
#Get change values
$site = Get-SPOSite -Identity $url
$c_s_quota = $site.StorageQuota
$c_w_quota = $site.StorageQuotaWarningLevel
$c_p_usage="{0:P5}" -f ($site.StorageUsageCurrent / $site.StorageQuota)
Write-Host "Current settings for site: $url, Current Warning Quota: $c_w_quota, Current Storage Quota: $c_s_quota, % of usage $c_p_usage" -ForegroundColor Green
}
