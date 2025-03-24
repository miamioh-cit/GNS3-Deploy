param(
    [string]$vCenterServer = $env:VCENTER_SERVER,
    [string]$vCenterUser = $env:VCENTER_USER,
    [string]$vCenterPass = $env:VCENTER_PASS,
    [string]$VMSource = $env:VM_SOURCE,
    [string]$NewVMName = $env:NEW_VM_NAME,
    [string]$Datastore = $env:DATASTORE,
    [string]$ResourcePoolName = $env:RESOURCE_POOL,
    [string]$VMFolderPath = $env:VM_FOLDER
)

# Ignore SSL warnings
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false -Scope User

# 🔗 Connect to vCenter Server
Write-Host "🔗 Connecting to vCenter Server: $vCenterServer"
Connect-VIServer -Server $vCenterServer -User $vCenterUser -Password $vCenterPass

# ✅ Get and use datacenter context
$datacenter = Get-Datacenter
if (-not $datacenter) {
    Write-Host "❌ ERROR: No datacenter found!"
    Disconnect-VIServer -Server $vCenterServer -Confirm:$false
    exit 1
}
Write-Host "📍 Using datacenter: $($datacenter.Name)"

# 🔍 List all available datastores in this context
Write-Host "📦 Available datastores in '$($datacenter.Name)':"
Get-Datastore -Location $datacenter | ForEach-Object { Write-Host "➡️ '$($_.Name)'" }

# 🔍 Debug: List available Resource Pools
Write-Host "🔍 Checking available Resource Pools..."
Get-ResourcePool | Select Name, Id

# 🔍 Debug: List available Folders
Write-Host "🔍 Checking available Folders..."
Get-Folder | Select Name, Id

# ✅ Ensure the Resource Pool exists
$ResourcePoolObj = Get-ResourcePool | Where-Object { $_.Name -eq $ResourcePoolName }
if (-not $ResourcePoolObj) {
    Write-Host "❌ ERROR: Resource Pool '$ResourcePoolName' not found!"
    Disconnect-VIServer -Server $vCenterServer -Confirm:$false
    exit 1
}

# ✅ Ensure the Datastore exists (case-insensitive, trimmed)
$DatastoreTrimmed = $Datastore.Trim()
$DatastoreObj = Get-Datastore -Location $datacenter | Where-Object { $_.Name -ieq $DatastoreTrimmed }
if (-not $DatastoreObj) {
    Write-Host "❌ ERROR: Datastore '$DatastoreTrimmed' not found! Available Datastores:"
    Get-Datastore -Location $datacenter | Select Name
    Disconnect-VIServer -Server $vCenterServer -Confirm:$false
    exit 1
}

# ✅ Ensure the Folder exists
$VMFolderObj = Get-Folder | Where-Object { $_.Name -eq $VMFolderPath }
if (-not $VMFolderObj) {
    Write-Host "❌ ERROR: VM Folder '$VMFolderPath' not found! Available Folders:"
    Get-Folder | Select Name
    Disconnect-VIServer -Server $vCenterServer -Confirm:$false
    exit 1
}

# 🛠️ Clone the VM
Write-Host "🛠️ Cloning VM '$VMSource' to '$NewVMName'..."
try {
    New-VM -Name $NewVMName -VM $VMSource -Datastore $DatastoreObj -ResourcePool $ResourcePoolObj -Location $VMFolderObj -ErrorAction Stop
    Write-Host "✅ VM '$NewVMName' cloned successfully."
} catch {
    Write-Host "❌ ERROR: Failed to clone VM '$VMSource' to '$NewVMName'. $_"
    Disconnect-VIServer -Server $vCenterServer -Confirm:$false
    exit 1
}

# ⚡ Power on the new VM
Write-Host "⚡ Powering on VM '$NewVMName'..."
try {
    Start-VM -VM $NewVMName -Confirm:$false -ErrorAction Stop
    Write-Host "✅ VM '$NewVMName' is now powered on."
} catch {
    Write-Host "❌ ERROR: Failed to power on VM '$NewVMName'. $_"
    Disconnect-VIServer -Server $vCenterServer -Confirm:$false
    exit 1
}

# 🔌 Disconnect from vCenter
Write-Host "🔌 Disconnecting from vCenter Server..."
Disconnect-VIServer -Server $vCenterServer -Confirm:$false
