function Backup-AzureDatabricksWorkspaceFolder {
    <#
        .SYNOPSIS
            Backs up the contents of an Azure Databricks workspace folder and copies it to a different path within a same (or different)
            Azure Databricks workspace.
        .DESCRIPTION
            This function is a great way to connect to your workspace and copy the contents to a different place. This function can take the same connection object
            for source and destination, or two different connections (which you can use for a simple deployment method from a non-production to production instance).
        .PARAMETER SourceConnection
            An object that represents an Azure Databricks API connection where you want to backup your files from.
        .PARAMETER SourcePath
            The base path you want to copy your files from. Note: this will recurseively copy everything in the given path.
        .PARAMETER DestinationConnection
            An object that represents an Azure Databricks API connection where you want to copy your files to.
        .PARAMETER DestinationPath
            The base path you want to copy your to. Note: this will recurseively copy everything in the given path.
        .NOTES
            Author: Drew Furgiuele (@pittfurg), http://www.port1433.com
            Website: https://www.igs.com
            Copyright: (c) 2019 by IGS, licensed under MIT
            License: MIT https://opensource.org/licenses/MIT
        .LINK
            
        .EXAMPLE
            PS C:\> Backup-AzureDatabricksWorkspaceFolder -SourceConnection $AzureDatabricksConnection -SourcePath "/SomeDirectory" -DestinationConnection $AzureDatabricksConnection -DestinationPath "/NewDirectory"
            Copies the contents of your "/SomeDirectory" folder in Azure Databricks to the folder "/NewDirectory" within the same Azure Databricks instance (note the same connection object)
    #>

    Param (
        [Parameter(Mandatory=$true)] [object] $SourceConnection,
        [Parameter(Mandatory=$true)] [string] $SourcePath,
        [Parameter(Mandatory=$true)] [object] $DestinationConnection,
        [Parameter(Mandatory=$true)] [string] $DestinationPath

    )

    begin {
        $WriteURI = $DestinationConnection.BaseURI.AbsoluteUri + "api/2.0/workspace/import"
    }    

    process {
        $ExistingContents = Export-AzureDatabricksContent -Connection $SourceConnection -Path $SourcePath
        $DateObject = Get-Date

        Write-Verbose "Deploying old objects to archive"
        $BackupRequest = New-AzureDatabricksRequest -Uri $WriteURI -AccessToken  $DestinationConnection.AccessToken -UseBasicParsing $DestinationConnection.UseBasicParsing -RequestMethod POST
        $BackupRequest.AddBody("content",$ExistingContents)
        $BackupRequest.AddBody("path",($DestinationPath + "/" + ($DateObject.ToFileTimeUtc())))
        $BackupRequest.AddBody("format","DBC")
        $BackupRequest.AddBody("overwrite","false")
        $BackupRequest.Submit() | Out-Null

        $BackupRequest
    }
}