function Get-AzureDatabricksWorkspace {
    <#
        .SYNOPSIS
            Returns an object that represents objects within a specificed Azure Databricks workspace/folder
        .DESCRIPTION
            This function returns a list of objects and directory for a target workspace folder (or default root)
            recursively.
        .PARAMETER Connection
            An object that contains your current connection context, which you can obtain by running New-AzureDatabricksConnection
        .PARAMETER Path
            The base path you want to return the file/directory listing for.
        .NOTES
            Author: Drew Furgiuele (@pittfurg), http://www.port1433.com
            Website: https://www.igs.com
            Copyright: (c) 2019 by IGS, licensed under MIT
            License: MIT https://opensource.org/licenses/MIT
        .LINK
            
        .EXAMPLE
            PS C:\> Get-AzureDatabricksWorkspace -Connection $AzureDatabricksConnection
            Returns a listing of all files/directories in the root of your Azure Databricks workspace
    #>

    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$true)] [object] $Connection,
        [Parameter(Mandatory=$false)] [string] $Path = "/"
    )

    begin {
        $TargetURI = $Connection.BaseURI.AbsoluteUri + "api/2.0/workspace/list"
    }

    process {
        Write-Verbose "Querying workspace path $path..."
        $TargetURI += "?path=$path"
        $WorkSpace = New-AzureDatabricksRequest -Uri $TargetURI -AccessToken  $Connection.AccessToken -UseBasicParsing $Connection.UseBasicParsing
        $WorkSpace.RequestBody = $RequestBody
        $Response = $WorkSpace.Submit()
        ForEach ($o in $Response.Objects) {
            $Object = New-Object AzureDataBricksWorkSpace($o.object_type, $o.path)
            $Object
            if ($o.object_type -eq "DIRECTORY") {
                Get-AzureDatabricksWorkspace -Connection $Connection -Path ($o.Path)
            }    
        }
    }
}