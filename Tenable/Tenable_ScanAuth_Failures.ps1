<#
--------------------------------------------------|Auth Failure|--------------------------------------------------
#>
# $api = Read-Host "Enter Secret Key" -AsSecureString
# $token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($api))

$token = Read-Host "Enter Token" -asSecureString | ConvertFrom-SecureString -AsPlainText

$headers=@{
	"accept"		= "application/json"
	"X-ApiKeys"		= $token
}

$LastWeek = ([DateTimeOffset](Get-Date).AddDays(-7)).ToUnixTimeSeconds()

$tojson = [ordered] @{
	"num_assets" = "1000"
	"filters"	= [Ordered] @{
		"last_found" = $LastWeek
		"plugin_id" = @(
			104410	# Target Credential Status by Authentication Protocol - Failure for Provided Credentials	https://www.tenable.com/plugins/nessus/104410
			21745	# OS Security Patch Assessment Failed	https://www.tenable.com/plugins/nessus/21745
			110723	# Target Credential Status by Authentication Protocol - No Credentials Provided	https://www.tenable.com/plugins/nessus/110723
			110385	# Target Credential Issues by Authentication Protocol - Insufficient Privilege	https://www.tenable.com/plugins/nessus/110385
			104410  # Target Credential Status by Authentication Protocol - Failure for Provided Credential
			24786	# Nessus Windows Scan Not Performed with Admin Privileges	https://www.tenable.com/plugins/nessus/24786
			10428	# Microsoft Windows SMB Registry Not Fully Accessible Detection	https://www.tenable.com/plugins/nessus/10428
			26917	# Microsoft Windows SMB Registry : Nessus Cannot Access the Windows Registry	https://www.tenable.com/plugins/nessus/26917
			117885	# Target Credential Issues by Authentication Protocol - Intermittent Authentication Failure	https://www.tenable.com/plugins/nessus/117885
			91822	# Database Authentication Failure(s) for Provided Credentials	https://www.tenable.com/plugins/nessus/91822
			122503	# Integration Credential Status by Authentication Protocol - Failure for Provided Credentials	https://www.tenable.com/plugins/nessus/122503
		)
	}
} 

$body = $tojson | ConvertTo-Json -Compress

$response = Invoke-RestMethod -Uri 'https://cloud.tenable.com/vulns/export' -Method POST -Headers $headers -ContentType 'application/json' -Body $body
$Exportid = $response.export_uuid

$vulns = @()

<#
While ($ExportStatus.status -ne "FINISHED"){
	$ExportStatus = Invoke-RestMethod -Uri "https://cloud.tenable.com/vulns/export/$ExportID/status" -Method GET -Headers $headers
	$ExportStatus
	Start-Sleep -Seconds 15
}
#>

While ($ExportStatus.status -ne "FINISHED") {
    $ExportStatus = Invoke-RestMethod -Uri "https://cloud.tenable.com/vulns/export/$ExportID/status" -Method GET -Headers $headers
    Switch ($ExportStatus.status) {
        "QUEUED" {
            Write-Host "$(get-date -f 'hh:mm:ss') - Export Status: $($ExportStatus.status)"
            Start-Sleep -Seconds 15
        }
		"Processing" {
            Write-Host "$(get-date -f 'hh:mm:ss') - Export Status: $($ExportStatus.status)"
            Start-Sleep -Seconds 15
        }
        "ERROR" {
            Write-Warning "Tenable Vulnerability Management encountered an error while processing the export request. Tenable recommends that you retry the request. If the status persists on retry, contact Support."
            return
        }
        "CANCELLED" {
            Write-Warning "An administrator has cancelled the export request."
            return
        }
        "FINISHED" {
            Write-Host "FINISHED — Tenable Vulnerability Management has completed processing the export request. The list of chunks is complete."
            return
        }
    }
}

For ($i= 1; $i -le $ExportStatus.chunks_available.count; $i++) {
	$response = Invoke-RestMethod -Uri "https://cloud.tenable.com/vulns/export/$ExportID/chunks/$i" -Method GET -Headers $headers
	$vulns += $response
}

$report = @()
ForEach ($vuln in $vulns) {
	$suuid = $vuln.scan.schedule_uuid 
	$scan_name = invoke-RestMethod -Uri "https://cloud.tenable.com/scans/$suuid" -Method GET -Headers $headers
	
	$merg = [PSCUSTOMOBJECT]@{
		ScanName			= $scan_name.info.name
		HostName			= $vuln.asset.Hostname
		IPv4				= $vuln.asset.ipv4
		Mac					= $vuln.asset.mac_address
		LastAuth			= ($vuln.asset.last_authenticated_results -split "T")[0]
		Output				= $vuln.output | out-string
		PluginID			= $vuln.plugin.id
		PluginName			= $vuln.plugin.name
		PluginDescription	= $vuln.plugin.description
		PluginSynopsis		= $vuln.plugin.synopsis
	}
	$report += $merg
}
$report | ft 
$report | Export-csv -Path "$Env:UserProfile\Downloads\AuthFailureReport.csv" -NoTypeInformation