$api = Read-Host "Enter Secret Key" -AsSecureString
$token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($api)) 

$headers=@{
	"accept"		= "application/json"
	"X-ApiKeys"		= $token
}

$headers=@{
"accept" = "application/json"
"X-ApiKeys" = $token
}

$tojson = [ordered] @{
    filters = [ordered] @{
        severity = @(
            "critical",
            "high"
        )
        state = @(
            "open",
            "reopened"
        )
    }
}

$body = $tojson | ConvertTo-Json -Compress

$response = Invoke-RestMethod -Uri 'https://cloud.tenable.com/vulns/export' -Method POST -Headers $headers -ContentType 'application/json' -Body $body

# '{"filters":{"severity":["critical","high"],"state":["Open","reopened"]}}'

$Exportid = $response.export_uuid
$vulns = @()
While ($ExportStatus.status -ne "FINISHED") {
	$uri = "https://cloud.tenable.com/vulns/export/$Exportid/status"
    $ExportStatus = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
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
	$response = Invoke-RestMethod -Uri "https://cloud.tenable.com/vulns/export/$exportid/chunks/$i" -Method GET -Headers $headers
	$vulns += $response
}

$report = @()
foreach($vuln in $vulns){
	$merg = [PSCUSTOMOBJECT]@{
		PluginName 		= $vuln.plugin.name
		Severity		= $vuln.severity
		CVE 			= $vuln.plugin.cve | out-string
		CVSS3 			= $vuln.plugin.cvss3_base_score
		PluginDate		= $vuln.plugin.publication_date 
		FirstSeen		= $vuln.first_found
		LastSeen		= $vuln.last_found
		AssetID 		= $vuln.asset.uuid
		IPv4 			= $vuln.asset.ipv4
		HostName 		= $vuln.asset.hostname
		Plugin 			= $vuln.plugin.id
		Description 	= $vuln.plugin.description
		PluginOutput 	= $vuln.output
		Solution 		= $vuln.plugin.solution
	}
	$report += $merg
}

$today = get-date -format 'yyyy-MM-dd'
$Folder = "$Env:UserProfile\Downloads\" + $today + "_Tenable-Vulnerabilies"
$path = "$Folder\" + "$today" + "_Vuln-Report.csv"
New-Item -Path $Folder -ItemType "directory" -force
$report | sort-Object -Property Plugin | Export-csv -Path $path  -NoTypeInformation

ForEach($plugin in ($report.plugin | Select-Object -Unique )){
	$name = ($report | where-object {$_.Plugin -eq $plugin} | Select-object -ExpandProperty PluginName -Unique) -replace '[\\/:*?"<>|]', ''
	$fname = "$plugin" + " - $name"
	$vulnReport = "
	Vulnerability: $($report | where-object {$_.Plugin -eq $plugin} | Select-object -ExpandProperty PluginName -Unique) `n
	PluginID: $($plugin) `n
	CVE: `n$($report | where-object {$_.Plugin -eq $plugin} | Select-object -ExpandProperty CVE -Unique) `n
	CVSS3: `n$($report | where-object {$_.Plugin -eq $plugin} | Select-object -ExpandProperty CVSS3 -Unique) `n
	Severity: `n$($report | where-object {$_.Plugin -eq $plugin} | Select-object -ExpandProperty Severity -Unique) `n
	HostNames: `n$($report | where-object {$_.Plugin -eq $plugin} | Select-object -ExpandProperty Hostname | out-string ) `n
	Description: `n$($report | where-object {$_.Plugin -eq $plugin} | Select-object -ExpandProperty Description -Unique) `n
	Solution: `n$($report | where-object {$_.Plugin -eq $plugin} | Select-object -ExpandProperty Solution -Unique ) `n
	PluginOutput: $($report | where-object {$_.Plugin -eq $plugin} | Select-object -ExpandProperty PluginOutput -Unique )
	"
	$fpath  = "$folder" + "\$fname" + ".txt"
	$vulnReport | Out-File -FilePath $fPath
}
