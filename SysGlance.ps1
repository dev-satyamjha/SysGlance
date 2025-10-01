if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

function Convert-WmiDate($wmiDate) {
    if ($wmiDate) {
        return ([System.Management.ManagementDateTimeConverter]::ToDateTime($wmiDate)).ToString("yyyy-MM-dd HH:mm")
    } else {
        return "N/A"
    }
}

Write-Host "`n========= SYSTEM INFORMATION =========`n"

$computer = Get-WmiObject Win32_ComputerSystem
$bios = Get-WmiObject Win32_BIOS
$os = Get-WmiObject Win32_OperatingSystem
$baseboard = Get-WmiObject Win32_BaseBoard

Write-Host "Hostname            : $($computer.Name)"
Write-Host "Model               : $($computer.Model)"
Write-Host "Serial Number       : $($bios.SerialNumber)"
Write-Host "Current OS Name     : $($os.Caption)"
Write-Host "OS Version          : $($os.Version)"
Write-Host "OS Install Date     : $(Convert-WmiDate $os.InstallDate)"

$productKey = (Get-WmiObject -query 'select * from SoftwareLicensingService').OA3xOriginalProductKey
Write-Host "Product Key         : $productKey"

Write-Host "`n========= MEMORY INFORMATION =========`n"

$memory = Get-WmiObject Win32_PhysicalMemory

foreach ($stick in $memory) {
    Write-Host "`n--- RAM Stick ---"
    Write-Host "Capacity            : $([math]::Round($stick.Capacity / 1GB, 2)) GB"
    Write-Host "Frequency           : $($stick.Speed) MHz"
    Write-Host "Form Factor         : $($stick.FormFactor) (12 = SODIMM)"
    Write-Host "Manufacturer        : $($stick.Manufacturer)"
    Write-Host "Part Number         : $($stick.PartNumber.Trim())"
    Write-Host "Serial Number       : $($stick.SerialNumber)"
    Write-Host "Slot/Bank Label     : $($stick.BankLabel)"
    Write-Host "Soldered            : $(if ($stick.FormFactor -eq 12 -or $stick.FormFactor -eq 8) { "No" } else { "Possibly Yes" })"
}

Write-Host "`n========= VIDEO INFORMATION =========`n"

$video = Get-WmiObject Win32_VideoController
foreach ($gpu in $video) {
    Write-Host "GPU Name            : $($gpu.Name)"
    Write-Host "VRAM Available      : $([math]::Round($gpu.AdapterRAM / 1MB, 2)) MB"
    Write-Host "Driver Version      : $($gpu.DriverVersion)"
    Write-Host "Video Processor     : $($gpu.VideoProcessor)"
}

Write-Host "`n========= CPU INFORMATION =========`n"

$cpu = Get-WmiObject Win32_Processor
foreach ($c in $cpu) {
    Write-Host "Name                : $($c.Name)"
    Write-Host "Cores               : $($c.NumberOfCores)"
    Write-Host "Logical Processors  : $($c.NumberOfLogicalProcessors)"
    Write-Host "Architecture        : $($c.Architecture)"
    Write-Host "Socket              : $($c.SocketDesignation)"
    Write-Host "Max Clock Speed     : $($c.MaxClockSpeed) MHz"
}

try {
    $tempInfo = Get-WmiObject -Namespace "root\wmi" -Class MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
    foreach ($temp in $tempInfo) {
        $tempC = [math]::Round(($temp.CurrentTemperature / 10) - 273.15, 1)
        Write-Host "CPU Temperature     : $tempC °C"
    }
} catch {
    Write-Host "CPU Temperature     : Not Available"
}

Write-Host "`n========= NETWORK INFORMATION =========`n"

$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
foreach ($adapter in $adapters) {
    $wifi = Get-NetConnectionProfile -InterfaceAlias $adapter.Name -ErrorAction SilentlyContinue
    Write-Host "Interface Name      : $($adapter.Name)"
    Write-Host "Connected Network   : $($wifi.Name)"
    Write-Host "MAC Address         : $($adapter.MacAddress)"
}

Write-Host "`n========= DISK INFORMATION =========`n"

$physicalDisks = Get-PhysicalDisk
Write-Host "Total Disk Slots    : $($physicalDisks.Count)"
foreach ($disk in $physicalDisks) {
    $diskNumber = (Get-Disk | Where-Object { $_.FriendlyName -eq $disk.FriendlyName }).Number
    Write-Host "`n--- Disk #$diskNumber ---"
    Write-Host "Model               : $($disk.FriendlyName)"
    Write-Host "Size                : $([math]::Round($disk.Size / 1GB, 2)) GB"
    Write-Host "Bus Type            : $($disk.BusType)"
    Write-Host "Media Type          : $($disk.MediaType)"
    Write-Host "Health Status       : $($disk.HealthStatus)"
}
