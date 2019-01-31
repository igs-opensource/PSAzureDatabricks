function New-AzureDatabricksDirectory {
    <#
        .SYNOPSIS
            Returns an object that represents objects within a specificed Azure Databricks workspace/folder
        .DESCRIPTION
            This function returns a list of objects and directory for a target workspace folder (or default root)
            recursively.
        .PARAMETER Connection
            An object that contains your current connection context, which you can obtain by running New-AzureDatabricksConnection
        .PARAMETER NewDirectoryPath
            The new directory path you want to create. All base/previous directories must exist or Databricks will return an error.
            Also, if the path already exists, Databricks will return an error.
        .NOTES
            Author: Drew Furgiuele (@pittfurg), http://www.port1433.com
            Website: https://www.igs.com
            Copyright: (c) 2019 by IGS, licensed under MIT
            License: MIT https://opensource.org/licenses/MIT
        .LINK
            
        .EXAMPLE
            PS C:\> New-AzureDatabricksDirectory -Connection $AzureDatabricksConnection -NewDirectoryPath "/NewDirectory"
            Creates a new directory in the root of your Databricks instance named "NewDirectory"
    #>

    Param (
        [Parameter(Mandatory=$true)] [object] $Connection,
        [Parameter(Mandatory=$true)] [string] $NewDirectoryPath
    )

    begin {
        $TargetURI = $Connection.BaseURI.AbsoluteUri + "api/2.0/workspace/mkdirs"
    }

    process {
        $NewDirRequest = New-AzureDatabricksRequest -Uri $TargetURI -AccessToken  $Connection.AccessToken -UseBasicParsing $Connection.UseBasicParsing -RequestMethod POST
        $NewDirRequest.AddBody("path",$NewDirectoryPath)
        $NewDir = $NewDirRequest.Submit()
    }
}