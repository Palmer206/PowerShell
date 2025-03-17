<#
----------| Set Variables |----------
#>

$model = "claude-3-7-sonnet-20250219"
$anthropic_version = "2023-06-01"
$max_tokens = 2048
$key = Read-Host -AsSecureString | ConvertFrom-SecureString -AsPlainText

$headers = @{
	"x-api-key" = $key
    "anthropic-version" = $anthropic_version
    "content-type" = "application/json"
}

function Post-ClaudeMessage {

	$messageContent = Read-Host "Enter Query"
	
	$body = @{
		"model"  = $model
		"max_tokens" = $max_tokens
		"messages" = @(
			@{
				"role" = "user"
				"content" = $messageContent
			}	
		)
	} | ConvertTo-Json
	
	Invoke-RestMethod -Uri "https://api.anthropic.com/v1/messages" -Method Post -Headers $headers -Body $body
	
}

$response = Post-ClaudeMessage