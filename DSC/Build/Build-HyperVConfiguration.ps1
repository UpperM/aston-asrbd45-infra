#### LOAD GLOBAL VARIABLES
& C:\DSC\Tools\Set-Variables.ps1


configuration Build-HyperVConfiguration
{
    # Possibilité d’évaluation des expressions pour obtenir la liste des nœuds
    # Exemple : $AllNodes.Where("Role -eq Web").NodeName
    Import-DscResource -ModuleName xHyper-V
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    node ("$env:COMPUTERNAME")
    {

        WindowsFeature HyperV {
            Ensure = "present"
            Name = "Hyper-V"
            IncludeAllSubFeature = $true
        
        } 

        File VMsFolder
        {
            Type            = "Directory"
            DestinationPath = $VM_PATH
            Ensure          = "Present"
        }

        File VHDsFolder
        {
            Type            = "Directory"
            DestinationPath = $VHD_PATH
            Ensure          = "Present"
        }

        File MasterFolder
        {
            Type            = "Directory"
            DestinationPath = $MASTER_PATH
            Ensure          = "Present"
        }

        File ISOFolder
        {
            Type            = "Directory"
            DestinationPath = $ISO_PATH
            Ensure          = "Present"
        }

        xVMSwitch "ARC-SRV"
        {
            Name = "ARC-SRV"
            Type = "Internal"
            Ensure = "Present"
        }

        xVMSwitch "BOU-LAN"
        {
            Name = "BOU-LAN"
            Type = "Internal"
            Ensure = "Present"
        }

        xVMSwitch "ARC-CLI"
        {
            Name = "ARC-CLI"
            Type = "Internal"
            Ensure = "Present"
        }

        xVMSwitch "WAN"
        {
            Name = "WAN"
            Type = "Internal"
            Ensure = "Present"
        }
        
        xVMHost "HyperVHostPaths"
        {
            IsSingleInstance    = 'Yes'
            VirtualHardDiskPath = "$VHD_PATH"
            VirtualMachinePath  = "$VM_PATH"
        }
    }
}

$OutPutPath = $MOF_PATH
Remove-Item -Path "$OutPutPath\$env:COMPUTERNAME.mof" -ErrorAction SilentlyContinue
Build-HyperVConfiguration -OutputPath $OutPutPath
Start-DscConfiguration -Wait -Path $OutPutPath -Verbose