#### LOAD GLOBAL VARIABLES
& C:\DSC\Tools\Set-Variables.ps1

configuration Build-VM
{

    param(
        [System.string]$VMName,
        [System.String]$HyperHost = $env:COMPUTERNAME,
        $VMNetworkAdapter,
        $StartupMemory = 512MB,
        $MaximumMemory = 1024MB
    )

    Import-DscResource –ModuleName xHyper-V
    Import-DscResource –ModuleName PSDesiredStateConfiguration

    node ("$HyperHost")
    {
        # Check for Parent VHD file
        File ParentVHDFile
        {
            Ensure = "Present"
            DestinationPath = $WINDOWS_SRV_MASTER
            Type = "File"
        }

        # Check the destination VHD folder
        File VHDFolder
        {
            Ensure = "Present"
            DestinationPath = $VHD_PATH
            Type = "Directory"
            DependsOn = "[File]ParentVHDFile"
        }
        
        # Create VHD for VM
        xVHD "VHD$VMName"
        {
            Ensure = "Present"
            Name = "$VMName"
            Generation = "vhdx"
            Path = $VHD_PATH
            ParentPath = $WINDOWS_SRV_MASTER
            MaximumSizeBytes = 64Gb
            Type = "Differencing"
            DependsOn = @("[File]VHDFolder")
        }
        # Fichier Unattend
        xVhdFile $VMName {
            #ResourceName
            VhdPath       = "$VHD_PATH\$($VMName).vhdx"
            FileDirectory = @(

                MSFT_xFileDirectory {
                    SourcePath      = "$CONFIG_PATH\unattend.xml"
                    DestinationPath = "\Windows\Panther\unattend.xml"
                    Type            = "File"
                    Ensure          = "Present"
                    Force           = $true
                }

                MSFT_xFileDirectory {
                    SourcePath      = "$MOF_PATH\$VMName.mof"
                    DestinationPath = "\Windows\System32\Configuration\pending.mof"
                    Type            = "File"
                    Ensure          = "Present"
                    Force           = $true
                }
            )
        }

        # Create VM
        xVMHyperV "VMachine$VMName"
        {
            Ensure = "Present"
            Name = $VMName
            VhDPath = "$VHD_PATH\$VMName.vhdx"
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
                NetworkSetting = xNetworkSettings
                {
                    IpAddress = $i.IPAddress
                    Subnet = $i.Subnet
                    DefaultGateway = $i.DefaultGateway
                    DnsServer = $i.DnsServer
                }
            }
            $count = $count + 1
        }

    }
}

$VMs = @(
    $VMs = @(
        @{
            VMName = "RTR-01"
            VMNetworkAdapter = @(
                @{
                    SwitchName = "ARC-SRV"
                    IPaddress = "192.168.8.254"
                    Subnet = "255.255.255.0"
                    DnsServer = "192.168.8.1"
                },
                @{
                    SwitchName = "ARC-CLI"
                    IPaddress = "192.168.12.254"
                    Subnet = "255.255.255.0"
                    DnsServer = "192.168.8.1"
                },
                @{
                    SwitchName = "WAN"
                    IPaddress = "192.168.255.8"
                    Subnet = "255.255.255.0"
                    DefaultGateway = "192.168.255.254"
                    DnsServer = "192.168.8.1"
                }
            )
        },
        @{
            VMName = "RTR-02"
            VMNetworkAdapter = @(
                @{
                    SwitchName = "WAN"
                    IPaddress = "192.168.255.128"
                    Subnet = "255.255.255.0"
                    DnsServer = "192.168.8.1"
                },
                @{
                    SwitchName = "BOU-LAN"
                    IPaddress = "192.168.128.254"
                    Subnet = "255.255.255.0"
                    DnsServer = "192.168.8.1"
                }
            )
        },
        @{
            VMName = "RTR-03"
            VMNetworkAdapter = @(
                @{
                    SwitchName = "WAN"
                    IPaddress = "192.168.255.254"
                    Subnet = "255.255.255.0"
                    DnsServer = "192.168.8.1"
                },
                @{
                    SwitchName = "Salle"
                }
            )
        },
        @{
            VMName = "SRV-01"
            VMNetworkAdapter = @(
                @{
                    SwitchName = "ARC-SRV"
                    IPaddress = "192.168.8.1"
                    Subnet = "255.255.255.0"
                    DnsServer = "192.168.8.1"
                    DefaultGateway = "192.168.8.254"
                }
            )
        },
        @{
            VMName = "SRV-02"
            VMNetworkAdapter = @(
                @{
                    SwitchName = "ARC-SRV"
                    IPaddress = "192.168.8.2"
                    Subnet = "255.255.255.0"
                    DnsServer = "192.168.8.1"
                    DefaultGateway = "192.168.8.254"
                }
            )
        },
        @{
            VMName = "RMS"
            VMNetworkAdapter = @(
                @{
                    SwitchName = "ARC-SRV"
                    IPaddress = "192.168.8.40"
                    Subnet = "255.255.255.0"
                    DnsServer = "192.168.8.1"
                    DefaultGateway = "192.168.8.254"
                }
            )
        },
        @{
            VMName = "FS"
            VMNetworkAdapter = @(
                @{
                    SwitchName = "ARC-SRV"
                    IPaddress = "192.168.8.25"
                    Subnet = "255.255.255.0"
                    DnsServer = "192.168.8.1"
                    DefaultGateway = "192.168.8.254"
                }
            )
        },
        @{
            VMName = "Root-CA"
            VMNetworkAdapter = @(
                @{
                    SwitchName = "ARC-SRV"
                    IPaddress = "192.168.8.51"
                    Subnet = "255.255.255.0"
                    DnsServer = "192.168.8.1"
                    DefaultGateway = "192.168.8.254"
                }
            )
        },
        @{
            VMName = "Issuing-CA"
            VMNetworkAdapter = @(
                @{
                    SwitchName = "ARC-SRV"
                    IPaddress = "192.168.8.52"
                    Subnet = "255.255.255.0"
                    DnsServer = "192.168.8.1"
                    DefaultGateway = "192.168.8.254"
                }
            )
        },
        @{
            VMName = "WEB"
            VMNetworkAdapter = @(
                @{
                    SwitchName = "WAN"
                    IPaddress = "192.168.255.100"
                    Subnet = "255.255.255.0"
                    DnsServer = "192.168.8.1"
                    DefaultGateway = "192.168.255.254"
                }
            )
        },
        @{
            VMName = "WEBAPP"
            VMNetworkAdapter = @(
                @{
                    SwitchName = "WAN"
                    IPaddress = "192.168.255.110"
                    Subnet = "255.255.255.0"
                    DnsServer = "192.168.8.1"
                    DefaultGateway = "192.168.255.254"
                }
            )
        }
    )
)

foreach ($i in $VMs)
{
    Build-VM -VMName $i.VMName -VMNetworkAdapter $i.VMNetworkAdapter -OutputPath $MOF_PATH
    Start-DscConfiguration -Wait -Path $MOF_PATH -Verbose -Force
}