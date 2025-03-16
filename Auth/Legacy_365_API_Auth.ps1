$api = Read-Host "Enter Secret Key" -AsSecureString
$token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($api))

$TenantId = ''
$ClientId = ''

$aturl = "https://login.microsoftonline.com/$TenantID/oauth2/v2.0/token"

$body = @{
  grant_type = 'client_credentials'
  client_id = "$ClientID"
  Client_Secret = "$token"
  scope = 'https://outlook.office365.com/.default'
}

$response = invoke-RestMethod -URI $aturl -Method POST -body $body -contentType 'application/x-www-form-urlencoded'

$Headers     = @{
  'Authorization' = 'Bearer ' + $response.Access_Token
  'ConsistencyLevel' = 'eventual'
}

$trace = Invoke-RestMethod -Method GET -URI "https://reports.office365.com/ecp/reportingwebservice/reporting.svc/MessageTrace/" -Headers $Headers
