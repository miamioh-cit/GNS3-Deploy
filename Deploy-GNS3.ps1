param(
    [string]$vCenterServer = $env:VCENTER_SERVER,
    [string]$vCenterUser = $env:VCENTER_USER,
    [string]$vCenterPass = $env:VCENTER_PASS,
    [string]$VMSource = $env:VM_SOURCE,
    [string]$NewVMName = $env:NEW_VM_NAME,
    [string]$Datastore = "CITServer-Internal-1",  # ✅ Updated default
    [string]$ResourcePoolName = $env:RESOURCE_POOL,
    [string]$VMFolderPath = $env:VM_FOLDER
)

# Ignore invalid certs
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Scope User -Confirm:$false

# Connect to vCenter
Write-Host "🔗 Connecting to vCenter Server: $vCenterServer"
Connect-VIServer -Server $vCenterServer -User $vCenterUser -Password $vCenterPass

# Debug - list inventory
Write-Host "📦 Available Resource Pools:"
Get-ResourcePool | Select Name

Write-Host "💽 Available Datastores:"
Get-Datastore | Select Name

Write-Host "📁 Available VM Folders:"
Get-Folder -Type VM | Select Name

# Validate Resource Pool
$ResourcePoolObj = Get-ResourcePool | Where-Object { $_.Name -eq $ResourcePoolName }
if (-not $ResourcePoolObj) {
    Write-Host "❌ ERROR: Resource Pool '$ResourcePoolName' not found!"
    Disconnect-VIServer -Server $vCenterServer -Confirm:$false
    exit 1
}

# Validate Datastore
$DatastoreObj = Get-Datastore | Where-Object { $_.Name -eq $Datastore }
if (-not $DatastoreObj) {
    Write-Host "❌ ERROR: Datastore '$Datastore' not found! Available:"
    Get-Datastore | Select Name
    Disconnect-VIServer -Server $vCenterServer -Confirm:$false
    exit 1
}

# Validate Folder (ensure only 1 folder is selected and it's a VM folder)
$VMFolderObj = Get-Folder -Name $VMFolderPath -Type VM | Select-Object -First 1
if (-not $VMFolderObj) {
    Write-Host "❌ ERROR: Folder '$VMFolderPath' not found! Available:"
    Get-Folder -Type VM | Select Name
    Disconnect-VIServer -Server $vCenterServer -Confirm:$false
    exit 1
}

# Optional debug
Write-Host "📁 Selected Folder: $($VMFolderObj.Name)"

# Clone VM
Write-Host "🛠️ Cloning VM '$VMSource' as '$NewVMName'..."
try {
    New-VM -Name $NewVMName `
           -VM $VMSource `
           -Datastore $DatastoreObj `
           -ResourcePool $ResourcePoolObj `
           -Location $VMFolderObj `
           -ErrorAction Stop

    Write-Host "✅ VM '$NewVMName' cloned successfully."
}
catch {
    Write-Host "❌ ERROR: Failed to clone VM. $_"
    Disconnect-VIServer -Server $vCenterServer -Confirm:$false
    exit 1
}

# Power on VM
Write-Host "⚡ Powering on '$NewVMName'..."
try {
    Start-VM -VM $NewVMName -Confirm:$false -ErrorAction Stop
    Write-Host "✅ VM '$NewVMName' powered on."
}
catch {
    Write-Host "❌ ERROR: Failed to power on VM. $_"
    Disconnect-VIServer -Server $vCenterServer -Confirm:$false
    exit 1
}

# Done
Write-Host "🔌 Disconnecting..."
Disconnect-VIServer -Server $vCenterServer -Confirm:$false
