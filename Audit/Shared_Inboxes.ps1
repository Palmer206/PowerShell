Connect-ExchangeOnline
$Shared = Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited
# $Shared = $Shared| Where-object {$_.RequireSenderAuthenticationEnabled -eq $false}
$Results = @()
ForEach($Share in $Shared){
	$Access = Get-MailboxPermission -identity $Share.UserPrincipalName | Where-object {$_.User -notlike "NT AUTHORITY\*" }
	$boxes = [PSCUSTOMOBJECT]@{
		SharedInbox 	= $share.UserPrincipalName
		Users			= $Access.user -join ','
	}
	$Results += $boxes
}

$Results | Export-Csv -Path "$Env:UserProfile\Downloads\SharedInboxs.csv" -NoTypeInformation
$Results 
