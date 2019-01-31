function Import-AzureDatabricksContent {
    <#
        .SYNOPSIS
            Copies content from your local machine to a remote Azure Databricks instance.
        .DESCRIPTION
            Copies content from your local machine to a remote Azure Databricks instance. The imported file should be of type ".dbc" (which you can create using the Export-AzureDatabricksContent function).
            Otherwise, it can be a byte array of content. The target directory should not exist, and will be created.
        .PARAMETER DBCFile
            A path to your local DBC file you want to import.
        .PARAMETER Connection
            An object that represents an Azure Databricks API connection where you want to copy your content to.
        .PARAMETER Path
            The path to copy your content into. The target folder should not exist (but any parent directories should).
        .NOTES
            Author: Drew Furgiuele (@pittfurg), http://www.port1433.com
            Website: https://www.igs.com
            Copyright: (c) 2019 by IGS, licensed under MIT
            License: MIT https://opensource.org/licenses/MIT
        .LINK
            
        .EXAMPLE
            PS C:\> Import-AzureDatabricksContent -DBCFile exportedContents.dbc -Connection $Connection -Path "/NewFolder"
            Copies the contents of the DBC file to the Databricks instance defined in $Connection into the path "NewFolder" in the root of the instance.
    #>     
    Param (
        [Parameter(Mandatory=$true)] [System.IO.FileInfo] $DBCFile,
        [Parameter(Mandatory=$true)] [object] $Connection,
        [Parameter(Mandatory=$true)] [string] $Path
    )

    begin {
        $WriteURI = $Connection.BaseURI.AbsoluteUri + "api/2.0/workspace/import"
    }    

    process {
        Write-Verbose "Getting content we need to deploy..."
        $bytes = [IO.File]::ReadAllBytes($DBCFile)
        $importContent = [Convert]::ToBase64String($bytes)

        $TestDestinationPath = Test-AzureDatabricksWorkspacePath -Connection $Connection -Path $Path -AutoCreateParentDirectories

        $TargetAlreadyExists = $false
        try {
            Get-AzureDatabricksWorkspace -Connection $Connection -Path $Path | Out-Null
            $TargetAlreadyExists = $true
        } catch {
            Write-Warning "Target directory doesn't exist. New folder will be created"
        }

        if ($TargetAlreadyExists) {
            throw "Target location already exists!"
        }

        $DeployRequest = New-AzureDatabricksRequest -Uri $WriteURI -AccessToken  $Connection.AccessToken -UseBasicParsing $Connection.UseBasicParsing -RequestMethod POST
        $DeployRequest.AddBody("content",$importContent)
        $DeployRequest.AddBody("path",$Path)
        $DeployRequest.AddBody("format","DBC")
        $DeployRequest.AddBody("overwrite","false")
        $DeployResults = $DeployRequest.Submit()
        $DeployResults
    }
}