#### LOAD GLOBAL VARIABLES
& C:\DSC\Tools\Set-Variables.ps1

############## EDIT VM NAME ##############
$VMName = "CLI-02"
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

                $Domain = "aston.local"
                $Password = ConvertTo-SecureString -AsPlainText "Install!" -Force
                $Username = "ASTON\Administrateur"
                $Credential = New-Object System.Management.Automation.PSCredential ($Username, $Password)
                Add-Computer -DomainName $Domain -Credential $Credential
                netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol=icmpv4:8,any dir=in action=allow
                Rename-Computer -NewName "CLI-02" -Restart
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