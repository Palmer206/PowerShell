$SubscriptionId    	= ""
$ResourceGroupName 	= ""
$WorkspaceName     	= ""
$WatchlistAlias    	= ""
$ApiVersion        	= "2024-09-01"
$ClientID 			= ""
$DN 				= ""

Connect-MgGraph -Identity -ClientID $ClientID -NoWelcome
Connect-AzAccount -Identity -AccountId $ClientID

# Get users from Entra
$entraUsers = Get-MgUser -All -Property DisplayName, UserPrincipalName, ID, OnPremisesDistinguishedName | Where-Object {
    $_.onPremisesDistinguishedName -and ($_.onPremisesDistinguishedName -match "$DN")
}

# Get content of watchlist
$watchlistItemsUrl = "https://management.azure.com/subscriptions/$subscriptionId" +
    "/resourceGroups/$resourceGroupName" +
    "/providers/Microsoft.OperationalInsights/workspaces/$workspaceName" +
    "/providers/Microsoft.SecurityInsights/watchlists/$watchlistAlias" +
    "/watchlistItems?api-version=$ApiVersion"

$response = Invoke-AzRestMethod -Method GET -Uri $watchlistItemsUrl
$resContent = $response.content | ConvertFrom-JSON
$watchlistUsers = $resContent.value.properties.itemskeyvalue

#Compare objects by ID, create new objects for users to add and remove
$NewUsers = $EntraUsers | Where-Object {$_.ID -notin $watchlistUsers.ID}
$RemUsers = $watchlistUsers | Where-Object {$_.ID -notin $EntraUsers.ID}

Write-Output 'New Users Count' $NewUsers.count
Write-Output 'Remove Users Count' $RemUsers.count  

function Add-WatchlistItem {
    param(
        [Parameter(Mandatory)]
        $User,
        [Parameter(Mandatory)]
        $SubscriptionId,
        [Parameter(Mandatory)]
        $ResourceGroupName,
        [Parameter(Mandatory)]
        $WorkspaceName,
        [Parameter(Mandatory)]
        $WatchlistAlias,
        [Parameter(Mandatory)]
        $ApiVersion
    )
	# Use the users ObjectId as the watchlist item identifier
	$watchlistItemId = $User.Id

	# Build the JSON payload
	$body = @{
		properties = @{
			itemsKeyValue = @{
				UserPrincipalName = $User.UserPrincipalName
				DisplayName       = $User.DisplayName
				ID = $User.ID
				OnPremisesDistinguishedName = $user.OnPremisesDistinguishedName
			}
		}		
	}  | ConvertTo-Json
	
	#Build URL
	$putURL = "https://management.azure.com/subscriptions/$subscriptionId" +
		"/resourceGroups/$resourceGroupName" +
		"/providers/Microsoft.OperationalInsights/workspaces/$workspaceName" +
		"/providers/Microsoft.SecurityInsights/watchlists/$watchlistAlias" +
		"/watchlistItems/$watchlistItemId" +
		"?api-version=$ApiVersion"	
		
	#API Call to update watchlist
	Invoke-AzRestMethod -Method PUT -Uri $putURL -Payload $body
}

function Remove-WatchlistItem {
    param(
        [Parameter(Mandatory)]
        $User,
        [Parameter(Mandatory)]
        $SubscriptionId,
        [Parameter(Mandatory)]
        $ResourceGroupName,
        [Parameter(Mandatory)]
        $WorkspaceName,
        [Parameter(Mandatory)]
        $WatchlistAlias,
        [Parameter(Mandatory)]
        $ApiVersion
    )
	# Use the users ObjectId as the watchlist item identifier
	$watchlistItemId = $user.id

	#Build URL
	$DeleteURL = "https://management.azure.com/subscriptions/$subscriptionId" +
		"/resourceGroups/$resourceGroupName" +
		"/providers/Microsoft.OperationalInsights/workspaces/$workspaceName" +
		"/providers/Microsoft.SecurityInsights/watchlists/$watchlistAlias" +
		"/watchlistItems/$watchlistItemId" +
		"?api-version=$ApiVersion"
 
	#API Call to update watchlist
	Invoke-AzRestMethod -Method DELETE -Uri $DeleteURL
}

#Call Functions
foreach ($User in $newUsers) {
	Add-WatchlistItem -User $User -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -WorkspaceName $WorkspaceName -WatchlistAlias $WatchlistAlias -ApiVersion $ApiVersion
}

foreach ($User in $remUsers) {
	Remove-WatchlistItem -User $User -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -WorkspaceName $WorkspaceName -WatchlistAlias $WatchlistAlias -ApiVersion $ApiVersion
}