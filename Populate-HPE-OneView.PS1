$ip_addr  = "192.168.0.19" # "<DHCP IP Address assigned to DCS appliance>"
$password = "P@ssw0rd"  # "<New Administrator Password>"
$hostname = "ov89-vb.lj.lab"  # "<Hostname associated with DHCP IP Address of the DCS appliance>"

if (!(Get-Module -Name HPEOneView.*)) {
    if (!(Get-Module -ListAvailable -Name HPEOneView.*)) {
        Write-Output "No suitable HPEOneView module found. Please run Install-Module"
    } else {
        $module = Get-Module -ListAvailable -Name HPEOneView.* | Select-Object Name | Sort-Object -Property Name | select-object -last 1
        Write-Output "About to import"$module.Name". If you want an older version, please import it before running this script"
        Import-Module $module.Name
    }
} else {
    $module = Get-Module -Name HPEOneView.*
    Write-Output "Found module"$module.Name
}

#
# Function Declarations
#
function ConfigureAppliance {
    Param ( [Parameter(Mandatory=$True)] [string]$vm_ipaddr,
            [Parameter(Mandatory=$True)] [string]$vm_password,
            [Parameter(Mandatory=$True)] [string]$vm_hostname
    )

    # Accept the EULA
    if (Get-OVEulaStatus -appliance $vm_ipaddr) {
        Write-Output $vm_ipaddr "Accepting EULA..."
        $ret = Set-OVEulaStatus -supportAccess "yes" -appliance $vm_ipaddr
    }

    # For initial setup, connect first using "default" Administrator credentials
    try {
        [securestring]$secStringPassword = ConvertTo-SecureString "admin" -AsPlainText -Force
        $orig_credential = New-Object System.Management.Automation.PSCredential('Administrator',$secStringPassword)
        $ret = Connect-OVMgmt -appliance $vm_ipaddr -Credential $orig_credential
    } catch [ HPEOneView.Appliance.PasswordChangeRequired ] {
        $ret = Set-OVInitialPassword -oldPassword "admin" -newPassword "$vm_password" -Appliance $vm_ipaddr
    }
    [securestring]$secStringPassword = ConvertTo-SecureString $vm_password -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential('Administrator',$secStringPassword)
    $ret = Connect-OVMgmt -appliance $vm_ipaddr -Credential $credential

    #
    # Update the networking configuration.
    # Key assumption here is that DHCP address we received initially will not change.
    $task = Set-OVApplianceNetworkConfig -hostname $vm_hostname -ipv4type "DHCP" -ipv6type "UNCONFIGURE"
    Disconnect-OVMgmt
}

function ImportSANManager {
    Add-OVSanManager -Hostname 172.18.20.1 -SnmpUserName dcs-SHA-AES128 -SnmpAuthLevel AuthAndPriv -SnmpAuthPassword dcsdcsdcs -SnmpAuthProtocol sha -SnmpPrivPassword dcsdcsdcs -SnmpPrivProtocol aes-128 -Type Cisco -Port 161 | Wait-OVTaskComplete
}

function CreateNetworks {
    # Create Ethernet networks
    # Current version of the library does not allow the creation of Ethernet networks on a VM appliance, so we have to resort to Send-OVRequest
    $body = @{
        name = "";
        vlanId = "";
        purpose = "General";
        smartLink = $true;
        privateNetwork = $false;
        connectionTemplateUri = $null;
        ethernetNetworkType = "Tagged";
        type = "ethernet-networkV4"
    }
    $body.name = "corpnet A"
    $body.vlanId = 10
    Send-OVRequest "/rest/ethernet-networks" -method POST -body $body

    $body.name = "corpnet B"
    $body.vlanId = 10
    Send-OVRequest "/rest/ethernet-networks" -method POST -body $body

    $body.name = "ESXi mgmt A"
    $body.vlanId = 1131
    Send-OVRequest "/rest/ethernet-networks" -method POST -body $body

    $body.name = "ESXi mgmt B"
    $body.vlanId = 1131
    Send-OVRequest "/rest/ethernet-networks" -method POST -body $body

    $body.name = "ESXi vmotion A"
    $body.vlanId = 1132
    Send-OVRequest "/rest/ethernet-networks" -method POST -body $body

    $body.name = "ESXi vmotion B"
    $body.vlanId = 1132
    Send-OVRequest "/rest/ethernet-networks" -method POST -body $body

    $body.name = "prod vm1 A"
    $body.vlanId = 1101
    Send-OVRequest "/rest/ethernet-networks" -method POST -body $body
    $body.name = "prod vm1 B"
    $body.vlanId = 1101
    Send-OVRequest "/rest/ethernet-networks" -method POST -body $body

    $body.name = "prod vm2 A"
    $body.vlanId = 1102
    Send-OVRequest "/rest/ethernet-networks" -method POST -body $body
    $body.name = "prod vm2 B"
    $body.vlanId = 1102
    Send-OVRequest "/rest/ethernet-networks" -method POST -body $body

    $body.name = "prod vm3 A"
    $body.vlanId = 1103
    Send-OVRequest "/rest/ethernet-networks" -method POST -body $body
    $body.name = "prod vm3 B"
    $body.vlanId = 1103
    Send-OVRequest "/rest/ethernet-networks" -method POST -body $body
    
    $body.name = "prod vm4 A"
    $body.vlanId = 1104
    Send-OVRequest "/rest/ethernet-networks" -method POST -body $body
    $body.name = "prod vm4 B"
    $body.vlanId = 1104
    Send-OVRequest "/rest/ethernet-networks" -method POST -body $body
    
    $body.name = "test vm1 A"
    $body.vlanId = 1111
    Send-OVRequest "/rest/ethernet-networks" -method POST -body $body
    $body.name = "test vm1 B"
    $body.vlanId = 1111
    Send-OVRequest "/rest/ethernet-networks" -method POST -body $body
    
    $body.name = "test vm2 A"
    $body.vlanId = 1112
    Send-OVRequest "/rest/ethernet-networks" -method POST -body $body
    $body.name = "test vm2 B"
    $body.vlanId = 1112
    Send-OVRequest "/rest/ethernet-networks" -method POST -body $body
    
    $body.name = "test vm3 A"
    $body.vlanId = 1113
    Send-OVRequest "/rest/ethernet-networks" -method POST -body $body
    $body.name = "test vm3 B"
    $body.vlanId = 1113
    Send-OVRequest "/rest/ethernet-networks" -method POST -body $body
    
    $body.name = "test vm4 A"
    $body.vlanId = 1114
    Send-OVRequest "/rest/ethernet-networks" -method POST -body $body
    $body.name = "test vm4 B"
    $body.vlanId = 1114
    Send-OVRequest "/rest/ethernet-networks" -method POST -body $body
    
    $body.name = "dev vm1 A"
    $body.vlanId = 1121
    Send-OVRequest "/rest/ethernet-networks" -method POST -body $body
    $body.name = "dev vm1 B"
    $body.vlanId = 1121
    Send-OVRequest "/rest/ethernet-networks" -method POST -body $body
    
    $body.name = "dev vm2 A"
    $body.vlanId = 1122
    Send-OVRequest "/rest/ethernet-networks" -method POST -body $body
    $body.name = "dev vm2 B"
    $body.vlanId = 1122
    Send-OVRequest "/rest/ethernet-networks" -method POST -body $body
    
    $body.name = "dev vm3 A"
    $body.vlanId = 1123
    Send-OVRequest "/rest/ethernet-networks" -method POST -body $body
    $body.name = "dev vm3 B"
    $body.vlanId = 1123
    Send-OVRequest "/rest/ethernet-networks" -method POST -body $body
    
    $body.name = "dev vm4 A"
    $body.vlanId = 1124
    Send-OVRequest "/rest/ethernet-networks" -method POST -body $body
    $body.name = "dev vm4 B"
    $body.vlanId = 1124
    Send-OVRequest "/rest/ethernet-networks" -method POST -body $body
    
    # Create the FC networks
    New-OVNetwork -name "3PAR SAN A fabric" -type "FibreChannel" -typicalBandwidth 4000 -autoLoginRedistribution $true -managedSan "VSAN11"
    New-OVNetwork -name "3PAR SAN B fabric" -type "FibreChannel" -typicalBandwidth 4000 -autoLoginRedistribution $true -managedSan "VSAN20"
    New-OVNetwork -name "3PAR SAN A direct" -type "FibreChannel" -typicalBandwidth 4000 -autoLoginRedistribution $true -fabricType DirectAttach
    New-OVNetwork -name "3PAR SAN B direct" -type "FibreChannel" -typicalBandwidth 4000 -autoLoginRedistribution $true -fabricType DirectAttach
}

function CreateNetworkSets {
    $res = New-OVNetworkSet -name "Production Networks A" -networks (Get-OVNetwork -name "prod*A")
    $res = New-OVNetworkSet -name "Production Networks B" -networks (Get-OVNetwork -name "prod*B")
    $res = New-OVNetworkSet -name "Test Networks A"       -networks (Get-OVNetwork -name "test*A")
    $res = New-OVNetworkSet -name "Test Networks B"       -networks (Get-OVNetwork -name "test*B")
    $res = New-OVNetworkSet -name "Dev Networks A"        -networks (Get-OVNetwork -name "dev*A")
    $res = New-OVNetworkSet -name "Dev Networks B"        -networks (Get-OVNetwork -name "dev*B")
}

function ImportStorageArray {
    [securestring]$secStringPassword = ConvertTo-SecureString "dcs" -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential('dcs',$secStringPassword)
    $myArrayDCSName = "ThreePAR-1"
    $myArrayDomain = "TestDomain"
    $myArrayPools = [System.Array]("FST_CPG1", "FST_CPG2")
    $myArray = "172.18.11.11"
    Write-Host "Importing storage array: StoreServ $myArray"
    $task = Add-OVStorageSystem -hostname $myArray -Credential $credential -Family StoreServ -Domain $myArrayDomain
    $task | Wait-OVTaskComplete -timeout (New-TimeSpan -Minutes 15)
    $task = Get-OVStoragePool -Name "FST_CPG*" -ErrorAction Stop | Set-OVStoragePool -Managed $true

    $myArray = "172.18.29.1"
    Write-Host "Importing storage array: Nimble $myArray"
    $task = Add-OVStorageSystem -hostname $myArray -Credential $credential -Family Nimble
    $task | Wait-OVTaskComplete -timeout (New-TimeSpan -Minutes 15)
    $task = Get-OVStoragePool -Name "default-1" -ErrorAction Stop | Set-OVStoragePool -Managed $true
}

function CreateVolumes {
    New-OVStorageVolumeTemplate -templateName PrivateVol -StoragePool (Get-OVSToragePool -Name FST_CPG1) -Capacity 300
    New-OVStorageVolume -Name SharedVol -StoragePool (Get-OVSToragePool -Name FST_CPG2) -Capacity 2000 -Shared
}
function ImportServer {
    Param ( [Parameter(Mandatory=$True)] [string]$ipaddr
    )

    [securestring]$secStringPassword = ConvertTo-SecureString "dcs" -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential('dcs',$secStringPassword)
    Write-Host "Adding server $ipaddr"
    $task = Add-OVServer -Hostname $ipaddr -Credential $credential -Async
}

function CreateSPTs {
    # SPT for DL360 Gen10
    $con1 = Get-OVNetwork -Name "3PAR SAN A fabric" | New-OVServerProfileConnection -ConnectionID 1 -PortId "PCI 1:1"
    $con2 = Get-OVNetwork -Name "3PAR SAN B fabric" | New-OVServerProfileConnection -ConnectionID 2 -PortId "PCI 1:2"
    $connections = $con1, $con2
    $bios = @(@{id='WorkloadProfile';value='Virtualization-MaxPerformance'})
    $volume1 = Get-OVStorageVolume -Name SharedVol | New-OVServerProfileAttachVolume
    $ld1 = New-OVServerProfileLogicalDisk -Name LD1 -RAID RAID1 -NumberofDrives 2 # -Bootable:$true
    $localStorage = New-OVServerProfileLogicalDiskController -ControllerID Embedded -Mode RAID -LogicalDisk $ld1
    New-OVServerProfileTemplate -Name "DL360 Gen10" -ServerHardwareType (Get-OVServerHardwareType -Name "DL360 Gen10") -Connections $connections -ManageBoot:$true -BootMode "UEFI" -BootOrder "HardDisk" -BootModeConsistencyChecking "Exact" -Bios -BiosSettings $bios -SANStorage -StorageVolume $volume1 -HostOStype VMware -LocalStorage -StorageController $localStorage

# OneView library doesn't accept Ethernet connections for DL servers. Need to use Send-OVRequest to add them
    $spt = Get-OVServerProfileTemplate -Name "DL360 Gen10"
    $con3 = Get-OVNetworkSet -Name "Production Networks A" | New-OVServerProfileConnection -ConnectionID 3 
    $con3 | Add-Member -NotePropertyName 'ports' -NotePropertyValue @(@{portId="Flr 1:1"})
    $con4 = Get-OVNetworkSet -Name "Production Networks B" | New-OVServerProfileConnection -ConnectionID 4 
    $con4 | Add-Member -NotePropertyName 'ports' -NotePropertyValue @(@{portId="Flr 1:2"})
    $spt.connectionSettings.connections = $con1, $con2, $con3, $con4

    # Cleanup connection objects to remove properties added by the library that the backend will not accept
    $spt.connectionSettings.connections | % {$_.PSObject.Properties.Remove('mac')}
    $spt.connectionSettings.connections | % {$_.PSObject.Properties.Remove('macType')}
    $spt.connectionSettings.connections | % {$_.PSObject.Properties.Remove('wwpnType')}
    $spt.connectionSettings.connections | % {$_.PSObject.Properties.Remove('wwpn')}
    $spt.connectionSettings.connections | % {$_.PSObject.Properties.Remove('wwnn')}
    $spt.connectionSettings.connections | % {$_.PSObject.Properties.Remove('ApplianceConnection')}
    $spt.connectionSettings.connections | % {$_.requestedMbps = $null}
    $spt.connectionSettings.connections[2].requestedVFs = $null
    $spt.connectionSettings.connections[3].requestedVFs = $null
    $spt.PSObject.Properties.Remove('ApplianceConnection')
    $task = Send-OVRequest $spt.Uri -method PUT -body ($spt | ConvertTo-Json -Depth 6)

    # SPT for DL385 Gen10 Plus
    $bios = @(@{id='WorkloadProfile';value='Virtualization-MaxPerformance'})
    $volume1 = Get-OVStorageVolume -Name SharedVol | New-OVServerProfileAttachVolume
    $ld1 = New-OVServerProfileLogicalDisk -Name LD1 -RAID RAID1 -NumberofDrives 2 # -Bootable:$true
    $localStorage = New-OVServerProfileLogicalDiskController -ControllerID Slot3 -Mode RAID -LogicalDisk $ld1
    New-OVServerProfileTemplate -Name "DL385 Gen10 Plus" -ServerHardwareType (Get-OVServerHardwareType -Name "DL385 Gen10 Plus") -ManageBoot:$true -BootMode "UEFI" -BootOrder "HardDisk" -BootModeConsistencyChecking "Exact" -Bios -BiosSettings $bios -LocalStorage -StorageController $localStorage

# OneView library doesn't accept Ethernet connections for DL servers. Need to use Send-OVRequest to add them
    $spt = Get-OVServerProfileTemplate -Name "DL385 Gen10 Plus"
    $con1 = Get-OVNetworkSet -Name "Production Networks A" | New-OVServerProfileConnection -ConnectionID 1 
    $con1 | Add-Member -NotePropertyName 'ports' -NotePropertyValue @(@{portId="Ocp 10:1"})
    $con2 = Get-OVNetworkSet -Name "Production Networks B" | New-OVServerProfileConnection -ConnectionID 2 
    $con2 | Add-Member -NotePropertyName 'ports' -NotePropertyValue @(@{portId="Ocp 10:2"})
    $spt.connectionSettings.manageConnections = $true
    $spt.connectionSettings.connections = $con1, $con2

    # Cleanup connection objects to remove properties added by the library that the backend will not accept
    $spt.connectionSettings.connections | % {$_.PSObject.Properties.Remove('mac')}
    $spt.connectionSettings.connections | % {$_.PSObject.Properties.Remove('macType')}
    $spt.connectionSettings.connections | % {$_.PSObject.Properties.Remove('wwpnType')}
    $spt.connectionSettings.connections | % {$_.PSObject.Properties.Remove('wwpn')}
    $spt.connectionSettings.connections | % {$_.PSObject.Properties.Remove('wwnn')}
    $spt.connectionSettings.connections | % {$_.PSObject.Properties.Remove('ApplianceConnection')}
    $spt.connectionSettings.connections | % {$_.requestedMbps = $null}
    $spt.connectionSettings.connections[0].requestedVFs = $null
    $spt.connectionSettings.connections[1].requestedVFs = $null
    $spt.PSObject.Properties.Remove('ApplianceConnection')
    $task = Send-OVRequest $spt.Uri -method PUT -body ($spt | ConvertTo-Json -Depth 6)

 }

#
# Main Program
#

#
# Accept the EULA and configure the Administrator credentials
#
ConfigureAppliance $ip_addr "$password" "$hostname"
[securestring]$secStringPassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential('Administrator',$secStringPassword)
Connect-OVMgmt -Hostname $ip_addr -Credential $credential -ErrorAction Stop

#
# Configure virtual resources
#
ImportSanManager
CreateNetworks
CreateNetworkSets
ImportStorageArray
CreateVolumes
(1..14) | foreach-object { ImportServer "172.18.31.$_" }
(1..4) | foreach-object { ImportServer "172.18.6.$_" }
CreateSPTs

#
# Clear any remaining alerts and disconnect from OneView
#
Get-OVAlert -AlertState Active | Set-OVAlert -Cleared
Disconnect-OVMgmt