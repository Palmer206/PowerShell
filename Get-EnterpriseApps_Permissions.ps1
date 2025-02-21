$apps = Get-MgServicePrincipal -all | Where-Object {$_.Tags -contains "WindowsAzureActiveDirectoryIntegratedApp"}
$permissions = Get-MgOauth2PermissionGrant -All

$report = @()

ForEach($app in $apps){
	$appPermissions = $permissions | Where-Object {$_.ClientID -eq $app.id}
	$scopes = $appPermissions.scope | group
	$merg = [PSCustomObject]@{
		createdDateTime = $app.AdditionalProperties.createdDateTime
		DisplayName = $app.DisplayName
		ID = $app.Id
		AppId = $app.AppId
		App_Homepage = $app.homepage
		App_URLs = $app.ReplyUrls | out-string
		Permissions = $scopes.name | out-string
	}
	$report += $merg
}
$report | FT -autosize

$report | Export-Csv -Path "$Env:UserProfile\Downloads\Enterprise_Apps_Permissions.csv" -NoTypeInformation
