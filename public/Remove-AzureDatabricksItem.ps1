function Remove-AzureDatabricksItem {
    <#
        .SYNOPSIS
            Deletes an item from the Azure Databricks workspace.
        .DESCRIPTION
            Deletes an item from the Azure Databricks workspace. If the Path paramter points to a directory, the entire contents of the directory will be removed, recursively.
        .PARAMETER Connection
            An object that represents an Azure Databricks API connection where you want to delete from.
        .PARAMETER Path
            The path of the item you want to remove from your workspace. If a directory is supplied, it will remove it and the contents of the directory, recursively.
        .NOTES
            Author: Drew Furgiuele (@pittfurg), http://www.port1433.com
            Website: https://www.igs.com
            Copyright: (c) 2019 by IGS, licensed under MIT
            License: MIT https://opensource.org/licenses/MIT
        .LINK
            
        .EXAMPLE
            PS C:\> Remove-AzureDatabricksItem -Connection $Connection -Path "/users/Drew/SomeNotebook"
            Deletes the item "SomeNotebook" from the /users/Drew directory in your Azure Databricks workspace on the instance defined in $Connection
    #>    
    Param (
        [Parameter(Mandatory=$true)] [object] $Connection,
        [Parameter(Mandatory=$true)] [string] $Path
    )

    begin {
        $TargetURI = $Connection.BaseURI.AbsoluteUri + "api/2.0/workspace/delete"
    }

    process {
        $DeleteRequest = New-AzureDatabricksRequest -Uri $TargetURI -AccessToken  $Connection.AccessToken -UseBasicParsing $Connection.UseBasicParsing -RequestMethod POST -ExpectingNoReply
        $DeleteRequest.AddBody("path",$Path)
        $DeleteRequest.AddBody("recursive","true")
        $DeleteResult = $DeleteRequest.Submit()
        $DeleteResult
    }
}