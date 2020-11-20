$Modules = @(
    'xHyper-V'
)


foreach ($m in $Modules) {
    Find-Module $m | Install-Module
}