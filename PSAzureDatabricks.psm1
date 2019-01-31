#Load private functions
$PrivateFunctions = Get-Childitem $PSScriptRoot/private/*.ps1
ForEach ($pr in $PrivateFunctions) {
    $CurrentFile = $pr.FullName
    . $pr.FullName
}

#Load public functions
$PublicFunctions = Get-Childitem $PSScriptRoot/public/*.ps1
ForEach ($pu in $PublicFunctions) {
    . $pu.FullName
}