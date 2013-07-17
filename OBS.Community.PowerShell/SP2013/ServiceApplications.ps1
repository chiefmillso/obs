$serverName = "MILLERD2013"

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

# Configure Search
$searchPoolSvc = Get-SPServiceApplicationPool "Search Service Application"

# Ensure Services
Start-SPEnterpriseSearchServiceInstance $serverName
Start-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance $serverName

# Provision Search Service Application
$appSearchSvc = New-SPEnterpriseSearchServiceApplication -Partitioned -Name "SearchServiceApp" -ApplicationPool $searchPoolSvc -DatabaseName "SP-Dev-Search"
$proxySearchSvc = New-SPEnterpriseSearchServiceApplicationProxy -Partitioned -Name "SearchServiceApp Proxy" -SearchApplication $appSearchSvc

# "Configuring Search Component Topology..."
$clone = $appSearchSvc.ActiveTopology.Clone()
$searchServiceInstance = Get-SPEnterpriseSearchServiceInstance
New-SPEnterpriseSearchAdminComponent –SearchTopology $clone -SearchServiceInstance $searchServiceInstance
New-SPEnterpriseSearchContentProcessingComponent –SearchTopology $clone -SearchServiceInstance $searchServiceInstance
New-SPEnterpriseSearchAnalyticsProcessingComponent –SearchTopology $clone -SearchServiceInstance $searchServiceInstance
New-SPEnterpriseSearchCrawlComponent –SearchTopology $clone -SearchServiceInstance $searchServiceInstance
New-SPEnterpriseSearchIndexComponent –SearchTopology $clone -SearchServiceInstance $searchServiceInstance
New-SPEnterpriseSearchQueryProcessingComponent –SearchTopology $clone -SearchServiceInstance $searchServiceInstance
$clone.Activate()
