param(
    [string]$vCenterServer,
    [string]$vCenterUser,
    [string]$vCenterPass,
    [string]$VMSource,
    [string]$NewVMName,
    [string]$Datastore,
    [string]$ResourcePool,
    [string]$VMFolder
)

# Ignore invalid or self-signed SSL certificates
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false -Scope User

# Connect to vCenter Server
Write-Host "Connecting to vCenter Server: $vCenterServer"
Connect-VIServer -Server $vCenterServer -User $vCenterUser -Password $vCenterPass

# Check if the source VM exists
Write-Host "Checking if source VM '$VMSource' exists..."
$sourceVM = Get-VM -Name $VMSource -ErrorAction SilentlyContinue

if ($null -eq $sourceVM) {
    Write-Host "❌ Error: Source VM '$VMSource' not found!"
    Disconnect-VIServer -Server $vCenterServer -Confirm:$false
    exit 1
}

# Define cloning parameters
$cloneParams = @{
    Name       = $NewVMName
    VM         = $sourceVM
    Datastore  = $Datastore
    ResourcePool = Get-ResourcePool -Name $ResourcePool
    Location   = Get-Folder -Name $VMFolder
}

# Clone the VM
Write-Host "🛠️ Cloning VM '$VMSource' to '$NewVMName'..."
try {
    $newVM = New-VM @cloneParams -ErrorAction Stop
    Write-Host "✅ VM '$NewVMName' cloned successfully."
} catch {
    Write-Host "❌ Error: Failed to clone VM '$VMSource' to '$NewVMName'. $_"
    Disconnect-VIServer -Server $vCenterServer -Confirm:$false
    exit 1
}

# Power on the new VM
Write-Host "⚡ Powering on VM '$NewVMName'..."
try {
    Start-VM -VM $NewVMName -Confirm:$false -ErrorAction Stop
    Write-Host "✅ VM '$NewVMName' is now powered on."
} catch {
    Write-Host "❌ Error: Failed to power on VM '$NewVMName'. $_"
    Disconnect-VIServer -Server $vCenterServer -Confirm:$false
    exit 1
}

# Disconnect from vCenter
Write-Host "Disconnecting from the vCenter Server..."
Disconnect-VIServer -Server $vCenterServer -Confirm:$false
