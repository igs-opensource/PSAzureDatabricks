function Test-AzureDatabricksWorkspacePath {
    <#
        .SYNOPSIS
            Tests a given Azure Databricks workspace path.
        .DESCRIPTION
            This function will test for the presence of a given Azure Databricks workspace path/folder. If the folder does not exist, it throws an exception.
            Supports the ability to have any missing parent paths created via the -AutoCreateParentDirectories path.
        .PARAMETER Connection
            An object that represents an Azure Databricks API connection where you want to test your paths.
        .PARAMETER Path
            The workspace path you want to test.
        .PARAMETER AutoCreateParentDirectories
            A flag that determines whether or not any missing parent directories should be created as part of this test. For example, 
            if the tested path is "/Code/Drew/Notebooks" is tested with this switch parameter, and the folders "Code" and "Drew" do not exist, they will be auto-created.
            Note: this will NOT create the full target path, just any missing parent folders/directories.

        .NOTES
            Author: Drew Furgiuele (@pittfurg), http://www.port1433.com
            Website: https://www.igs.com
            Copyright: (c) 2019 by IGS, licensed under MIT
            License: MIT https://opensource.org/licenses/MIT
        .LINK
            
        .EXAMPLE
            PS C:\> Test-AzureDatabricksWorkspacePath -Connection $Connection -Path "/users/drew"
            Test for the presence of the full path of /users/drew on the Azure Databricks workspace defined in $Connection

            PS C:\> Test-AzureDatabricksWorkspacePath -Connection $Connection -Path "/users/drew" -AutoCreateParentDirectories
            Test for the presence of the full path of /users/drew on the Azure Databricks workspace defined in $Connection. If the path /users does not exist
            it will be created, but the /drew path will not be created.

    #>     
    Param (
        [Parameter(Mandatory=$true)] [object] $Connection,
        [Parameter(Mandatory=$true)] [string] $Path,
        [Parameter(Mandatory=$false)] [switch] $AutoCreateParentDirectories
    )

    process {
        Write-Verbose "Testing path (parent directories only)..."
        $PathSegments = $Path.split("/")
        $TestPath = ""
        For ($s = 1; $s -lt $PathSegments.Count - 1; $s++) {
            $TestPath += ("/" + $PathSegments[$s])
            try {
                Get-AzureDatabricksWorkspace -Connection $DestinationConnection -Path $TestPath | Out-Null
                Write-Verbose "Got path $testpath..."
            } catch {
                if ($AutoCreateParentDirectories) {
                    Write-Warning "Unable to get path $testpath... creating it"
                    New-AzureDatabricksDirectory -Connection $DestinationConnection -NewDirectoryPath $TestPath
                } else {
                    throw ("Unable to resolve path; made it as far as $testpath")
                }
            }
        }
        return $true
    }
}