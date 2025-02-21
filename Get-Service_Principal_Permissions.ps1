$servicePrincipals = Get-MgServicePrincipal -All
$permissions = Get-MgOauth2PermissionGrant -All

$report = @()

Foreach($grant in $permissions) {
    $sp = $servicePrincipals | Where-Object { $_.Id -eq $grant.ClientId }
    $merg = [PSCustomObject]@{
        createdDateTime = $sp.AdditionalProperties.createdDateTime
        GrantID         = $grant.ClientId
        ID              = $sp.Id
        DisplayName     = $sp.DisplayName
        ConsentType     = $grant.ConsentType
        PrincipalID     = $grant.PrincipalId
        Scope           = $grant.Scope
        Tags            = $sp.Tags
    }
    $report += $merg
}

$report | FT -autosize
$report | Export-Csv -Path $Env:UserProfile\Downloads\ServicePrincipal_Permissions.csv -NoTypeInformation
