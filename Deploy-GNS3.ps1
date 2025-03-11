param(
    [string]$vCenterServer,
    [string]$vCenterUser,
    [string]$vCenterPass
)

# Ignore SSL warnings
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false -Scope User

# Connect to vCenter Server
Write-Host "🔗 Connecting to vCenter Server: $vCenterServer"
Connect-VIServer -Server $vCenterServer -User $vCenterUser -Password $vCenterPass

# Define variables
$VMSource = "gns3-main"
$NewVMName = "gns3-clone-$((Get-Date).Ticks)"
$Datastore = "CITServer-Internal-2"
$ResourcePoolName = "Regional/ClusterCIT"  # Corrected Resource Pool Path
$VMFolderPath = "Regional/CIT Prod Server VMs/Senior Project Machines"  # Corrected Folder Path

# 🔍 Debug: List available Resource Pools
Write-Host "🔍 Checking available Resource Pools..."
Get-ResourcePool | Select Name, Id

# 🔍 Debug: List available Folders
Write-Host "🔍 Checking available Folders..."
Get-Folder | Select Name, Id

# Ensure the resource pool exists
$ResourcePoolObj = Get-ResourcePool -Location "Regional" | Where-Object { $_.Name -eq "ClusterCIT" }
if (-not $ResourcePoolObj) {
    Write-Host "❌ ERROR: Resource Pool '$ResourcePoolName' not found!"
    Disconnect-VIServer -Server $vCenterServer -Confirm:$false
    exit 1
}

# Ensure the folder exists
$VMFolderObj = Get-Folder | Where-Object { $_.Name -eq "Senior Project Machines" -or $_.Id -match "Senior Project Machines" }
if (-not $VMFolderObj) {
    Write-Host "❌ ERROR: VM Folder '$VMFolderPath' not found!"
    Disconnect-VIServer -Server $vCenterServer -Confirm:$false
    exit 1
}

# 🛠️ Clone the VM
Write-Host "🛠️ Cloning VM '$VMSource' to '$NewVMName'..."
try {
    New-VM -Name $NewVMName -VM $VMSource -Datastore $Datastore -ResourcePool $ResourcePoolObj -Location $VMFolderObj -ErrorAction Stop
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
