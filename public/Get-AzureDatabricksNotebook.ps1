function Get-AzureDatabricksNotebook {
    <#
        .SYNOPSIS
            Returns an array of objects representing saved notebooks in an Azure Databricks instance.
        .DESCRIPTION
            Returns an array of objects representing saved notebooks in an Azure Databricks instance. Each object contains the name of the saved Notebook as well as the absolute path
            in the Databricks instance that the Notebook is saved in. Note: this function is NOT recursive and paths ARE case senstiive!
        .PARAMETER Connection
            An object that represents an Azure Databricks API connection where you want to get a list of job runs from.
        .PARAMETER Path
            The path to scan for Notebooks. Defaults to the root of the instance workspace.
        .PARAMETER NotebookName
            The name of the notebook to filter on, if any.
        .NOTES
            Author: Drew Furgiuele (@pittfurg), http://www.port1433.com
            Website: https://www.igs.com
            Copyright: (c) 2019 by IGS, licensed under MIT
            License: MIT https://opensource.org/licenses/MIT
        .LINK
            
        .EXAMPLE
            PS C:\> Get-AzureDatabricksNotebook -Connection $Connection
            Returns an array of notebook objects that contain the file name and path to the notebook in the root (/) directory on the Databricks instance.
        .EXAMPLE
            PS C:\> Get-AzureDatabricksNotebook -Connection $Connection -Path "/User/Drew"
            Returns an array of notebook objects that contain the file name and path to the notebook in the "/User/Drew" directory on the Databricks instance.
        .EXAMPLE
            PS C:\> Get-AzureDatabricksNotebook -Connection $Connection -NotebookName "DrewsNotebook"
            Returns an array of notebook objects that contain the file name in the root directory on the Databricks instance named "DrewsNotebook"
        #>     
    Param (
        [Parameter(Mandatory=$true)] [object] $Connection,
        [Parameter(Mandatory=$false)] [string] $Path = "/",
        [Parameter(Mandatory=$false)] [string] $NotebookName
    )

    process {
        $ObjectList = Get-AzureDatabricksWorkspace -Connection $Connection -Path $Path
        ForEach ($o in $ObjectList)
        {
            if ($o.ObjectType -eq "NOTEBOOK") {
                $FullPath = $o.ObjectPath
                $SplitPath = $FullPath.Split("/")
                $TotalLength = $SplitPath.Length
                $NotebookName = $SplitPath[$TotalLength - 1]
                $NoteBook = New-Object AzureDatabricksNotebook($NotebookName, $o.ObjectPath)
                $NoteBook
            }
        }
    }
}
