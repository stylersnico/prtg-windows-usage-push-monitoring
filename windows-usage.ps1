# PRTG HTTP Push Sensor Script
# Collects CPU, Memory, Uptime, and Disk Usage and sends it to PRTG "HTTP Push Data Advanced" sensor

param(
    [string]$PrtgServer = "PRTG_IP",  # Replace with your PRTG server IP
    [int]$PrtgPort = 5050,
    [string]$Token = "TOKEN"     # Replace with your PRTG sensor token
)
Add-Type -AssemblyName System.Web

# Function to send data to PRTG
function Send-PrtgData {
    param(
        [string]$Data
    )
    
    $url = "http://${PrtgServer}:${PrtgPort}/${Token}?content=$([System.Web.HttpUtility]::UrlEncode($Data))"
    
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $url -Method Get
        Write-Host "Data sent successfully. Status: $($response.StatusCode)"
    }
    catch {
        Write-Error "Failed to send data: $($_.Exception.Message)"
    }
}

# Collect system information
$cpuUsage = (Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
$memory = Get-WmiObject -Class Win32_OperatingSystem
$memoryUsage = [math]::Round((($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / $memory.TotalVisibleMemorySize) * 100, 2)
$uptime = ((Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime).Days

# Get disk usage for all drives
$disks = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3"
$diskData = ""
foreach ($disk in $disks) {
    $drive = $disk.DeviceID
    $size = [math]::Round($disk.Size / 1GB, 0)
    $free = [math]::Round($disk.FreeSpace / 1GB, 0)
    $used = $size - $free
    $usage = [math]::Round(($used / $size) * 100, 0)
    
    $diskData += "<result><channel>Disk usage: $drive</channel><value>$usage</value><warning>80</warning><error>90</error><unit>Percent</unit></result>"
}

# Create XML payload with warnings and errors
$xmlPayload = @"
<prtg>
    <result>
        <channel>CPU Usage</channel>
        <value>$cpuUsage</value>
		<LimitMode>1</LimitMode>
		<LimitMaxWarning>80</LimitMaxWarning>
		<LimitMaxError>90</LimitMaxError>
		<unit>Percent</unit>
    </result>
    <result>
        <channel>Memory Usage</channel>
        <value>$memoryUsage</value>
		<LimitMode>1</LimitMode>
		<LimitMaxWarning>80</LimitMaxWarning>
		<LimitMaxError>90</LimitMaxError>
		<unit>Percent</unit>
    </result>
    <result>
        <channel>Uptime Days</channel>
        <value>$uptime</value>
		<LimitMode>1</LimitMode>
		<LimitMaxWarning>45</LimitMaxWarning>
		<LimitMaxError>60</LimitMaxError>
        <unit>Custom</unit>
        <customunit>days</customunit>
    </result>
    $diskData
</prtg>
"@

# Send data to PRTG
Send-PrtgData -Data $xmlPayload
