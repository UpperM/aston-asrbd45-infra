[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Modules = @(
    'xHyper-V'
)


foreach ($m in $Modules) {
    Find-Module $m | Install-Module
}