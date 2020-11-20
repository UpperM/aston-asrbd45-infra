#### LOAD GLOBAL VARIABLES
& C:\DSC\Tools\Set-Variables.ps1

Function Remove-AllVMs {
    Param
    (
        [Parameter(
            Mandatory=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $VMName
    )
    $VM = Get-VM -Name $VMName
    $VM | Stop-VM -Force -TurnOff
    $VM | Remove-VM -Force
    Remove-Item -Path "$VHD_PATH\$VMName.vhdx"
}

foreach ($i in Get-VM) {
    $i | Remove-AllVMs
}
