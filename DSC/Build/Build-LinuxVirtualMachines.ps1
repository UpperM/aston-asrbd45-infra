configuration Build-LinuxVM
{

    param(
        [System.string]$VMName,
        [System.String]$HyperHost = $env:COMPUTERNAME,
        [System.String]$SwitchName,
        $VMNetworkAdapter,
        $StartupMemory = 1024MB,
        $MaximumMemory = 2048MB
    )
    Import-DscResource -ModuleName xHyper-V
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    node ("$HyperHost")
    {
        $VHDParentPath = "C:\Hyper-V\VHD\MASTER-UBUNTU.vhdx"
        $VHDPath = "C:\Hyper-V\VHD"

        # Check for Parent VHD file
        File ParentVHDFile
        {
            Ensure = "Present"
            DestinationPath = $VHDParentPath
            Type = "File"
        }

        # Check the destination VHD folder
        File VHDFolder
        {
            Ensure = "Present"
            DestinationPath = $VHDPath
            Type = "Directory"
            DependsOn = "[File]ParentVHDFile"
        }
        
        # Create VHD for VM
        xVHD "VHD$VMName"
        {
            Ensure = "Present"
            Name = "$VMName"
            Generation = "vhdx"
            Path = $VHDPath
            ParentPath = $VHDParentPath
            MaximumSizeBytes = 64Gb
            Type = "Differencing"
            DependsOn = @("[File]VHDFolder")
        }

        # Create VM
        xVMHyperV "VMachine$VMName"
        {
            Ensure = "Present"
            SecureBoot = $false
            Name = $VMName
            VhDPath = "$VHDPath\$VMName.vhdx"
            Generation = 2
            StartupMemory = $StartupMemory
            MaximumMemory = $MaximumMemory
            EnableGuestService = $true
            ProcessorCount = 2
            State = "Running"
            DependsOn = @("[xVHD]VHD$VMName")
        }

        $count = 1
        foreach ($i in $VMNetworkAdapter) {
            # Add Network adapter
            xVMNetworkAdapter "NIC-$VMName-$count" {
                id = "NIC-$VMName-$($i.SwitchName)-$count"
                Name = $i.SwitchName
                VMName = $VMName
                SwitchName = $i.SwitchName
                Ensure = "Present"
            }
            $count = $count + 1
        }

    }
}

$VMs = @(
    @{
        VMName = "DKH-01"
        VMNetworkAdapter = @(
            @{
                SwitchName = "ARC-SRV"
                IPaddress = "192.168.8.2"
                Subnet = "255.255.255.0"
                DefaultGateway = "192.168.8.254"
                DnsServer = "192.168.8.1"
            }
        )
    }
)

foreach ($i in $VMs)
{
    Build-LinuxVM -VMName $i.VMName -VMNetworkAdapter $i.VMNetworkAdapter -OutputPath "C:\Hyper-V\DSC\Linux"
    Start-DscConfiguration -Wait -Path C:\Hyper-V\DSC\Linux -Verbose -Force
}