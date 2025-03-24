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

# ✅ Get datacenter
$datacenter = Get-Datacenter -Name "Regional"
if (-not $datacenter) {
    Write-Host "❌ ERROR: Datacenter 'Regional' not found!"
    Disconnect-VIServer -Server $vCenterServer -Confirm:$false
    exit 1
}
Write-Host "📍 Using datacenter: $($datacenter.Name)"

# ✅ Get target cluster
$cluster = Get-Cluster -Location $datacenter | Where-Object { $_.Name -eq "ClusterCIT" }
if (-not $cluster) {
    Write-Host "❌ ERROR: Cluster 'ClusterCIT' not found in datacenter '$($datacenter.Name)'!"
    Disconnect-VIServer -Server $vCenterServer -Confirm:$false
    exit 1
}
Write-Host "📦 Using cluster: $($cluster.Name)"

# ✅ Ensure the Resource Pool exists in ClusterCIT
$ResourcePoolObj = Get-ResourcePool -Location $cluster | Where-Object { $_.Name -eq $ResourcePoolName }
if (-not $ResourcePoolObj) {
    Write-Host "❌ ERROR: Resource Pool '$ResourcePoolName' not found in cluster '$($cluster.Name)'!"
    Disconnect-VIServer -Server $vCenterServer -Confirm:$false
    exit 1
}

# ✅ Ensure the Datastore exists in ClusterCIT
$DatastoreTrimmed = $Datastore.Trim()
Write-Host "🔍 Looking for datastore named: '$DatastoreTrimmed' in cluster '$($cluster.Name)'"

$DatastoreObj = Get-Datastore -Location $cluster | Where-Object { $_.Name -ieq $DatastoreTrimmed }

if (-not $DatastoreObj) {
    Write-Host "❌ ERROR: Datastore '$DatastoreTrimmed' not found in cluster '$($cluster.Name)'! Available:"
    Get-Datastore -Location $cluster | Select Name | ForEach-Object { Write-Host "➡️ '$($_.Name)'" }
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
