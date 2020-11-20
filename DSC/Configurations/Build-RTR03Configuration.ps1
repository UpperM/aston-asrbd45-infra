#### LOAD GLOBAL VARIABLES
& C:\DSC\Tools\Set-Variables.ps1

############## EDIT VM NAME ##############
$VMName = "RTR-03"
##########################################

Configuration Build-RTR03Configuration
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
                Rename-NetAdapter -Name (Get-NetIPAddress -IPAddress 192.168.255.254).InterfaceAlias -NewName "WAN"
                Rename-NetAdapter -Name (Get-NetIPAddress -IPAddress 10.94*).InterfaceAlias -NewName "Salle"

                Write-Output "############### INSTALLATION DU ROLE ROUTING ############"
                Install-WindowsFeature Routing
                Set-Service -Name RemoteAccess -StartupType Automatic
                Start-Service -Name RemoteAccess
                
                
                Write-Output "############### AJOUT DES ROUTES ############"
                route add -p 192.168.8.0/24 192.168.255.8
                route add -p 192.168.12.0/24 192.168.255.8
                route add -p 192.168.128.0/24 192.168.255.128
                
                Write-Output "############### CONFIGURATION DU NAT ############"
                netsh routing ip nat install
                netsh routing ip nat add interface Salle
                netsh routing ip nat set interface Salle mode=full
                netsh routing ip nat add interface WAN
                netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol=icmpv4:8,any dir=in action=allow
                Rename-Computer -NewName "RTR-03" -Restart
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
Build-RTR03Configuration -OutputPath $OutPutPath
Rename-Item -Path $OutPutPath\localhost.mof -NewName "$VMName.mof" -Force
Move-Item -Path "$OutPutPath\$VMName.mof" -Destination $MOF_PATH