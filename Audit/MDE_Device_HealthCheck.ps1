###### Auth - Build Token #####
$tenantId = ""
$appId = ""
$appSecret = Read-Host "Enter App Secret" -asSecureString | ConvertFrom-SecureString -AsPlainText

$resourceAppIdUri = 'https://api.securitycenter.microsoft.com'
$oAuthUri = "https://login.microsoftonline.com/$TenantId/oauth2/token"
$body = [Ordered] @{
    resource = "$resourceAppIdUri"
    client_id = "$appId"
    client_secret = "$appSecret"
    grant_type = 'client_credentials'
}
$response = Invoke-RestMethod -Method Post -Uri $oAuthUri -Body $body -ErrorAction Stop
$Token = $response.access_token

$headers = @{ 
    'Content-Type' = 'application/json'
    Accept = 'application/json'
    Authorization = "Bearer $token" 
}

##### Query Security Center #####
$uri = "https://api-us3.securitycenter.microsoft.com/api/machines/"
$AllResponses = @()
do {
	$response = Invoke-RestMethod -Method GET -Uri $uri -Headers $headers
	$AllResponses += $response.value
	$uri = $response.'@odata.nextlink'
} while ($uri)

##### Filter Responses #####

$oldDate = (Get-Date).AddDays(-14).ToString('yyyy-MM-dd')

$HealthReport = $AllResponses | Where-Object {
    ($_.onboardingStatus -ne "InsufficientInfo" -and $_.onboardingstatus -ne "Unsupported" ) -and 
    (($_.lastseen -lt "$olddate" ) -or ($_.healthStatus -ne "Active"))
} | Sort-Object healthStatus, onboardingStatus, osplatform | ForEach-Object {
    [PSCustomObject]@{
        ID              = $_.id
        ComputerDNSName = $_.computerdnsname
        HealthStatus    = $_.healthStatus
        OnboardingStatus = $_.onboardingstatus
        OSPlatform      = $_.osplatform
        LastSeen        = $_.lastseen
        LastIPAddress   = $_.lastipaddress
        MacAddress      = $_.ipAddresses.MacAddress
    }
}
$healthReport | Export-CSV -Path "$Env:UserProfile\Downloads\MDE_Device_Health.csv"  -NoTypeInformation
<#
$UnknownDevices = $AllResponses | Where-Object {
    $_.onboardingStatus -eq "InsufficientInfo"
} | Sort-Object healthStatus, onboardingStatus, osplatform | ForEach-Object {
    [PSCustomObject]@{
        ID              = $_.id
        ComputerDNSName = $_.computerdnsname
        HealthStatus    = $_.healthStatus
        OnboardingStatus = $_.onboardingstatus
        OSPlatform      = $_.osplatform
        LastSeen        = $_.lastseen
        LastIPAddress   = $_.lastipaddress
        MacAddress      = $_.ipAddresses.MacAddress
    }
}
$UnknownDevices | Export-CSV -Path "$Env:UserProfile\Downloads\MDE_UnknownDevices.csv"  -NoTypeInformation
$UnknownDevices
#>
$healthReport | ft


