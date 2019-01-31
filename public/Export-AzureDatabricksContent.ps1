function Export-AzureDatabricksContent {
    <#
        .SYNOPSIS
            Exports the contents of a Databricks workspace.
        .DESCRIPTION
            This function is designed to make it easier to export the raw contents of an Azure Databricks workspace to either an byte array object the represents
            the raw contents of the directory, or to an actual archive file you can save to your local file system.
        .PARAMETER Connection
            An object that represents an Azure Databricks API connection where you want to get your workspace files from.
        .PARAMETER Path
            The base path you want to copy your files from. Note: this will recurseively copy everything in the given path.
        .PARAMETER ToFile
            An object that represents a target file on your local file system. If supplied, the raw bytes will be written to disk in the form on archive you can open (.zip file).
        .NOTES
            Author: Drew Furgiuele (@pittfurg), http://www.port1433.com
            Website: https://www.igs.com
            Copyright: (c) 2019 by IGS, licensed under MIT
            License: MIT https://opensource.org/licenses/MIT
        .LINK
            
        .EXAMPLE
            PS C:\> $Contents = Export-AzureDatabricksContent -Connection $AzureDatabricksConnection -Path "/SomeDirectory" 
            Returns an object representing the raw bytes of the contents of the /SomeDirectory folder on the Azure Databricks instance defined in $AzureDatabricksConnection

        .EXAMPLE
            PS C:\> Export-AzureDatabricksContent -Connection $AzureDatabricksConnection -Path "/SomeDirectory" -ToFile Archive.zip
            Saves the contents of the /SomeDirectory folder on the Azure Databricks instance defined in $AzureDatabricksConnection to a local file in your current working folder
            in a file named Archive.zip.
    #>
    Param (
        [Parameter(Mandatory=$true)] [object] $Connection,
        [Parameter(Mandatory=$true)] [string] $Path,
        [Parameter(Mandatory=$false)] [System.IO.FileInfo] $ToFile
    )

    begin {
        $TargetURI = $Connection.BaseURI.AbsoluteUri + "api/2.0/workspace/export?path=$Path&format=DBC"
    }

    process {
        $ExportedContentsRequest = New-AzureDatabricksRequest -Uri $TargetURI -AccessToken $Connection.AccessToken -RequestMethod Get -UseBasicParsing $Connection.UseBasicParsing
        $ContentsObject = $ExportedContentsRequest.Submit()
        if ($ToFile) {
            $bytes = [Convert]::FromBase64String($ContentsObject.Content)
            [IO.File]::WriteAllBytes($ToFile, $bytes)
        } else {
            $ContentsObject.Content
        }
    }
}