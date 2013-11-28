$serverName = "MILLERD2013"
$dbAlias = "SP2013"

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


# Provision Enterprise Search Centre
# http://millerd2013/sites/search


$appSearchSvc = Get-SPEnterpriseSearchServiceApplication "SearchServiceApp"
$appSearchSvc.SearchCenterUrl = "http://millerd2013/sites/search/pages";
$appSearchSvc.Update()

# Provision Managed Metadata Service
$appMetadataSvc = New-SPMetadataServiceApplication -Name "MetadataServiceApp" -ApplicationPool $appPoolSubSvc -DatabaseName "SP-Dev-ManMeta"
$proxyMetadataSvc = New-SPMetadataServiceApplicationProxy -Name "MetadataServiceApp Proxy" -ServiceApplication $appMetadataSvc
$group = Get-SPServiceApplicationProxyGroup
Add-SPServiceApplicationProxyGroupMember $group $proxyMetadataSvc

# Provision BDC
$appPoolSubSvc = Get-SPServiceApplicationPool "Service Applications"
$appBdcSvc = New-SPBusinessDataCatalogServiceApplication -Name "Business Data Catalog" -ApplicationPool $appPoolSubSvc -DatabaseName "SP-Dev-BDC" -DatabaseServer $dbAlias
$ServiceInstance = Get-SPServiceInstance | Where-Object { $_.TypeName -like "*Business*" }
Start-SPServiceInstance $ServiceInstance

# Provision Secure Store
$appSecureStoreSvc = New-SPSecureStoreServiceApplication –ApplicationPool $appPoolSubSvc –AuditingEnabled:$false –DatabaseServer $dbAlias –DatabaseName "SP-Dev-SecureStore" -Name "Secure Store"
$appSecureStoreProxy = New-SPSecureStoreServiceApplicationProxy -Name "Secure Store Proxy" -ServiceApplication $appSecureStoreSvc
$ServiceInstance = Get-SPServiceInstance | Where-Object { $_.TypeName -like "*Secure Store*" }
Start-SPServiceInstance $ServiceInstance
# Ensure Secure Store is active
iisreset

$passphrase = "Password!"
Update-SPSecureStoreMasterKey -ServiceApplicationProxy $appSecureStoreProxy -PassPhrase $passphrase


