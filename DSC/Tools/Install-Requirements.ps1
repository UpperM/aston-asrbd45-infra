


$Modules = @(
    'xHyper-V',
    'xVMNetworkAdapter'

)


foreach ($m in $Modules) {
    Find-Module $m | Install-Module
}