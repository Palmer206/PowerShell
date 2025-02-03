$Inboxes = Get-Mailbox -RecipientTypeDetails UserMailbox -ResultSize unlimited

ForEach ($Inbox in $Inboxes) {
  Get-InboxRule -Mailbox $Inbox | ForEach {Get-InboxRule -Mailbox $Inbox -Identity $_.Name} | Where-Object { $_.ForwardTo -ne $null -or $_.RedirectTo -ne $null } | Select-Object Description, Enabled, Name, RuleIdentity, From, HasAttachment, CopyToFolder, DeleteMessage, ForwardAsAttachmentTo, ForwardTo, RedirectTo, SendTextMessageNotificationTo, SoftDeleteMessage, MailboxOwnerId | Export-csv -Path "$ENV:USERPROFILE\Downloads\Forwarding.csv" -NoTypeInformation -Append -NoClobber
}