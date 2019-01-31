@{
    RootModule = 'PSAzureDatabricks.psm1'
    ModuleVersion = '0.2.0'
    GUID = '4c738f34-b3c9-45d5-9e2a-99cab643be17'
    Author = 'dfurgiuele'
    CompanyName = 'IGS'
    Copyright = '(c) dfurgiuele. All rights reserved.'
    Description = 'A series of functions and classes to support automation around Azure Databricks'
    PowerShellVersion = '5.0'
    FunctionsToExport = @(
        'Get-AzureDatabricksJob',
        'Get-AzureDatabricksNotebook'
        'New-AzureDatabricksConnection',
        'New-AzureDatabricksJob',
        'Remove-AzureDatabricksJob',
        'Start-AzureDatabricksJob',
        'Stop-AzureDatabricksJob',
        'Test-AzureDatabricksConnection',
        'Get-AzureDatabricksNotebook',
        'Get-AzureDatabricksJobStatus',
        'Get-AzureDatabricksJobRun',
        'Watch-AzureDatabricksJob',
        'Deploy-AzureDatabricksNotebooks',
        'Get-AzureDatabricksCluster',
        'Stop-AzureDatabricksCluster',
        'Export-AzureDatabricksContent',
        'Remove-AzureDatabricksItem',
        'Test-AzureDatabricksWorkspacePath',
        'Import-AzureDatabricksContent',
        'Backup-AzureDatabricksWorkspaceFolder',
        'Install-AzureDatabricksClusterLibrary',
        'Get-AzureDatabricksClusterLibraries'
    )
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
    ScriptsToProcess = @("./private/Classes.ps1")
    PrivateData = @{
        PSData = @{
            Tags = @("AzureDatabricks","Databricks")
            LicenseUri = 'https://github.com/igs-opensource/PSAzureDatabricks/blob/master/LICENSE'
            ProjectUri = 'https://github.com/igs-opensource/PSAzureDatabricks'
            # IconUri = ''
            # ReleaseNotes = ''

        }
    }
    # HelpInfoURI = ''
}