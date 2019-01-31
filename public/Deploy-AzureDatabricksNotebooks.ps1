function Deploy-AzureDatabricksNotebooks {
    <#
        .SYNOPSIS
            Copy the contents of one directory of a given Databricks workspace directory to another same (or different) Databricks instance while also
            backing up the existing contents to another directory.
        .DESCRIPTION
            This function was designed to help support a release strategy around promoting code from one instance of databricks to another. The idea is that the function will:
                1. Read the contents of a given source Databricks workspace directory, and
                2. Read the contents of a given target Databricks workspace directory (if it exists), and
                3. Back up any existing content in the target directory (if any) to an archive locatin within a given Databricks workspace, and
                4. Write the contents of the source workspace to the target directory
        .PARAMETER SourceConnection
            An object that represents an Azure Databricks API connection where you want to copy your files from.
        .PARAMETER SourcePath
            The base path you want to copy your files from. Note: this will recurseively copy everything in the given path.
        .PARAMETER DestinationConnection
            An object that represents an Azure Databricks API connection where you want to copy your files to.
        .PARAMETER DestinationPath
            The base path you want to copy your files to. If this path doesn't exist, it will be created.
        .PARAMETER ArchiveConnection
            An object that represents an Azure Databricks API connection where you want to back up your existing Databricks workspace files to (if they already exist)
        .PARAMETER ArchivePath
            The base path you want to backup your existing files to. A new folder will be created inside the given path with a directory name of the current UTC Date and Time to hold
            the files from the backup process.
        .NOTES
            Author: Drew Furgiuele (@pittfurg), http://www.port1433.com
            Website: https://www.igs.com
            Copyright: (c) 2019 by IGS, licensed under MIT
            License: MIT https://opensource.org/licenses/MIT
        .LINK
            
        .EXAMPLE
            PS C:\> Deploy-AzureDatabricksNotebooks -SourceConnection $AzureDatabricksConnection -SourcePath "/SomeDirectory" -DestinationConnection $AzureDatabricksConnection -DestinationPath "/NewDirectory"
            -ArchiveConnection $ArchiveConnection -ArchivePath "/SomeArchive"
            
            This will connect to the source Azure Databricks instance and read the contents from the /SomeDirectory workspace folder. Then, it will check to see it there's an existing folder on the target instance in the "/NewDirectory" folder.
            If the directory exists, the existing contents will be copied to a new folder with the current UTC date and time as an "integer string" in the "/SomeArchive" folder in the instance specified in the $ArchiveConnection. If the folder
            does not eixst, the target folder will be created before the files are copied over.
    #>
    Param (
        [Parameter(Mandatory=$true)] [object] $SourceConnection,
        [Parameter(Mandatory=$true)] [string] $SourcePath,
        [Parameter(Mandatory=$true)] [object] $DestinationConnection,
        [Parameter(Mandatory=$true)] [string] $DestinationPath,
        [Parameter(Mandatory=$true)] [object] $ArchiveConnection,
        [Parameter(Mandatory=$true)] [string] $ArchiveDestinationPath
    )

    begin {
        $WriteURI = $DestinationConnection.BaseURI.AbsoluteUri + "api/2.0/workspace/import"
    }    

    process {
        Write-Verbose "Getting content we need to deploy..."
        $ExportedContents = Export-AzureDatabricksContent -Connection $SourceConnection -Path $SourcePath

        Write-Verbose "Testing destination path (parent directories only)"
        $PathSegments = $DestinationPath.split("/")
        $TestPath = ""
        For ($s = 1; $s -lt $PathSegments.Count - 1; $s++) {
            $TestPath += ("/" + $PathSegments[$s])
            try {
                Get-AzureDatabricksWorkspace -Connection $DestinationConnection -Path $TestPath | Out-Null
                Write-Verbose "Got path $testpath..."
            } catch {
                Write-Warning "Unable to get path $testpath... creating it"
                New-AzureDatabricksDirectory -Connection $DestinationConnection -NewDirectoryPath $TestPath
            }
        }

        $TargetAlreadyExists = $false
        try {
            Get-AzureDatabricksWorkspace -Connection $DestinationConnection -Path $DestinationPath | Out-Null
            $TargetAlreadyExists = $true
        } catch {
            Write-Warning "Target directory doesn't exist. Nothing needs backed up. New folder will be created"
        }

        if ($TargetAlreadyExists) {
            Write-Verbose "Target location already exists!"
            Write-Verbose "Collecting existing content..."
            $ExistingContents = Export-AzureDatabricksContent -Connection $DestinationConnection -Path $DestinationPath
            $DateObject = Get-Date

            Write-Verbose "Deploying old objects to archive"
            $BackupRequest = New-AzureDatabricksRequest -Uri $WriteURI -AccessToken  $ArchiveConnection.AccessToken -UseBasicParsing $ArchiveConnection.UseBasicParsing -RequestMethod POST
            $BackupRequest.AddBody("content",$ExistingContents)
            $BackupRequest.AddBody("path",($ArchiveDestinationPath + "/" + ($DateObject.ToFileTimeUtc())))
            $BackupRequest.AddBody("format","DBC")
            $BackupRequest.AddBody("overwrite","false")
            $BackupRequest.Submit() | Out-Null

            Write-Verbose "Removing target deployment folder..."
            Remove-AzureDatabricksItem -Connection $DestinationConnection -Path $DestinationPath | Out-Null
        }

        $DeployRequest = New-AzureDatabricksRequest -Uri $WriteURI -AccessToken  $ArchiveConnection.AccessToken -UseBasicParsing $ArchiveConnection.UseBasicParsing -RequestMethod POST
        $DeployRequest.AddBody("content",$ExportedContents)
        $DeployRequest.AddBody("path",$DestinationPath)
        $DeployRequest.AddBody("format","DBC")
        $DeployRequest.AddBody("overwrite","false")
        $DeployResults = $DeployRequest.Submit()
        $DeployResults
    }
}