# Ensure Timer Services are Running
NET START SPAdminV4
NET START SPTimerV4

# Create Isolated App Domain
Set-SPAppDomain "app.dev.local"

$appPoolSubSvc = Get-SPServiceApplicationPool "Service Applications"

Get-SPServiceInstance | where{$_.GetType().Name -eq "AppManagementServiceInstance" -or $_.GetType().Name -eq "SPSubscriptionSettingsServiceInstance"} | Start-SPServiceInstance

# Provision Subscription Service Application
$appSubSvc = New-SPSubscriptionSettingsServiceApplication -ApplicationPool $appPoolSubSvc -Name "SettingsServiceApp" -DatabaseName "SP-Dev-SettingsServiceDB"
$proxySubSvc = New-SPSubscriptionSettingsServiceApplicationProxy -ServiceApplication $appSubSvc

# Provision Application Management Service Application
$appAppSvc = New-SPAppManagementServiceApplication -ApplicationPool $appPoolSubSvc -Name "AppServiceApp" -DatabaseName "SP-Dev-AppManagementDB"
$proxyAppSvc = New-SPAppManagementServiceApplicationProxy -ServiceApplication $appAppSvc -Name "AppServiceApp Proxy"

# Set Application Management Tenancy
Set-SPAppSiteSubscriptionName -Name "app" -Confirm:$false