#### LOAD GLOBAL VARIABLES
& C:\DSC\Tools\Set-Variables.ps1

############## EDIT VM NAME ##############
$VMName = "SRV-01"
##########################################

Configuration Build-SRV01Configuration
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node "localhost"
    {
        Script "Configuration" {
            GetScript = {

            }
            TestScript = {
                $false
            }
            SetScript = {
                Install-WindowsFeature DNS -IncludeManagementTools
                Install-WindowsFeature -Name DHCP -IncludeManagementTools
                Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
                
                Import-Module ADDSDeployment
            
                [string]$DomainName         = "aston.local"
                [string]$DomainNetbiosName  = "ASTON"
                [string]$Password           = "Install!"
                [string]$PathAD             = "C:\Windows"

                #Configuration de l'installation
                $Params = @{
                    SafeModeAdministratorPassword = (ConvertTo-SecureString $Password -AsPlainText -Force)
                    ForestMode                    = "WinThreshold"
                    DomainMode                    = "WinThreshold"
                    DomainName                    = $DomainName
                    DomainNetbiosName             = $DomainNetbiosName
                    DatabasePath                  = "$PathAD\NTDS"
                    SysvolPath                    = "$PathAD\SYSVOL"
                    LogPath                       = "$PathAD\NTDS"
                    InstallDns                    = $true
                    CreateDnsDelegation           = $false
                    
                    NoRebootOnCompletion          = $false
                    Force                         = $true
                }
            
                #Deploiement du domaine
                Install-ADDSForest @Params
                netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol=icmpv4:8,any dir=in action=allow
                Rename-Computer -NewName "SRV-01" -Restart
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
Build-SRV01Configuration -OutputPath $OutPutPath
Rename-Item -Path $OutPutPath\localhost.mof -NewName "$VMName.mof" -Force
Move-Item -Path "$OutPutPath\$VMName.mof" -Destination $MOF_PATH