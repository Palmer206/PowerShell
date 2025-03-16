<#
--------------------------------------------------|Scan Health|--------------------------------------------------
#>
$api = Read-Host "Enter Secret Key" -AsSecureString
$token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($api))

$headers=@{
	"accept"		= "application/json"
	"X-ApiKeys"		= $token
}

$today = get-date -format 'MM-dd-yyyy'
$Yesterday = ([DateTimeOffset](Get-Date).AddDays(-1)).ToUnixTimeSeconds()
$results = @()

$response = Invoke-RestMethod -Uri "https://cloud.tenable.com/scans" -Method GET -Headers $headers

ForEach ($scan in $response.scans) {
	
	$id = $scan.id
	$ScanResponse = Invoke-RestMethod -Uri "https://cloud.tenable.com/scans/$id" -Method GET -Headers $headers
	
	if ($ScanResponse.info.scan_start -gt $Yesterday){
	
		$merg = [PSCustomObject]@{
			Name	= $ScanResponse.info.name
			StartTime = (Get-Date '1970-01-01Z').AddSeconds(($ScanResponse.info.scan_start))
			EndTime	= (Get-Date '1970-01-01Z').AddSeconds($ScanResponse.info.scan_end)
			Duration	= "{0:hh\:mm\:ss}" -f [TimeSpan]::FromSeconds($ScanResponse.info.scan_end - $ScanResponse.info.scan_start)
			Status_publishing = "{0:hh\:mm\:ss}" -f [TimeSpan]::FromMilliseconds($scan.status_times.publishing)
			Status_running = "{0:hh\:mm\:ss}" -f [TimeSpan]::FromMilliseconds($scan.status_times.running)
			Warnings	= $ScanResponse.notes.message | Out-String			
		}
		$results += $merg
	}
}
$path = "$Env:UserProfile\Downloads\" + $today + "_ScanHealth.csv"
$results | Export-csv -Path $path -NoTypeInformation
$results | ft -autosize


