#https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.applications/new-mgserviceprincipalapproleassignment?view=graph-powershell-1.0

# Managed Identity Object Id
$msi = ''

# Microsoft Graph API permissions
$graph = Get-MgServicePrincipal -Filter "AppId eq '00000003-0000-0000-c000-000000000000'"

# Permissions
$permissions = @("User.Read.All", "Group.Read.All", "Directory.Read.All")

foreach($permission in $permissions) {
    $appRole = $graph.AppRoles | Where-Object Value -eq $permission
    $bodyParam = @{
        PrincipalId = $msi
        ResourceId  = $graph.Id
        AppRoleId   = $appRole.Id
    }
    New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $msi -BodyParameter $bodyParam
}
