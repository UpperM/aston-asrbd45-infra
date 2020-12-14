#### LOAD GLOBAL VARIABLES
& C:\DSC\Tools\Set-Variables.ps1

############## EDIT VM NAME ##############
$VMName = "RTR-01"
##########################################
Configuration Build-RTR01Configuration
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node "localhost"
    {

        WindowsFeature "Routing"
        {
            Name = "Routing"
            Ensure = "Present"
            
        }

        Script "Configuration" {
            GetScript = {

            }
            TestScript = {
                $false
            }
            SetScript = {
                Set-Service -Name RemoteAccess -StartupType Automatic
                Start-Service -Name RemoteAccess

                Write-Output "############### AJOUT DES ROUTES ############"
                route add -p 192.168.128.0/24 192.168.255.128
                route add -p 0.0.0.0/0 192.168.255.254

                Rename-NetAdapter -Name (Get-NetIPAddress -IPAddress 192.168.8.254).InterfaceAlias -NewName "ARC-SRV"
                Rename-NetAdapter -Name (Get-NetIPAddress -IPAddress 192.168.12.254).InterfaceAlias -NewName "ARC-CLI"
                Rename-NetAdapter -Name (Get-NetIPAddress -IPAddress 192.168.255.8).InterfaceAlias -NewName "WAN"

                Write-Output "############### CONFIGURATION DU RELAIS DHCP ############"
                netsh routing ip relay install
                netsh routing ip relay add dhcpserver 192.168.8.1
                #netsh routing ip relay add dhcpserver 192.168.128.1
                netsh routing ip relay add interface ARC-CLI
                netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol=icmpv4:8,any dir=in action=allow
                Rename-Computer -NewName "RTR-01"-Restart
            }
        }
    }
}

$OutPutPath = $env:TEMP
# Clean old .mof files
Remove-Item -Path "$OutPutPath\localhost.mof" -ErrorAction SilentlyContinue
Remove-Item -Path "$OutPutPath\$VMName.mof" -ErrorAction SilentlyContinue
Remove-Item -Path "$MOF_PATH\$VMName.mof" -ErrorAction SilentlyContinue

# Build new mof files
Build-RTR01Configuration -OutputPath $OutPutPath
Rename-Item -Path $OutPutPath\localhost.mof -NewName "$VMName.mof" -Force
Move-Item -Path "$OutPutPath\$VMName.mof" -Destination $MOF_PATH
