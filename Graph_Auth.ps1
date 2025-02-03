$api = Read-Host "Enter Secret Key" -AsSecureString
$token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($api))
$authparams = @{
    ClientId    = ''
    TenantId    = ''
    ClientSecret = $token
}

$auth = Get-MsalToken @authParams

$graphGetParams = @{
    Headers     = @{
        'Authorization' = 'Bearer $($auth.AccessToken)'
    'ConsistencyLevel' = 'eventual'
    }
    Method      = "GET"
  Uri = 'https://graph.microsoft.com/v1.0/me'
  OutputType = 'PsObject'
}

$Result = Invoke-RestMethod @graphGetParams

$Result