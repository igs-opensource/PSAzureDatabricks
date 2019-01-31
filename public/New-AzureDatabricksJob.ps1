function New-AzureDatabricksJob {
<#
        .SYNOPSIS
            Dynamically create a job on an Azure Databricks cluster. Returns an object defining the job and the newly assigned job ID number.
        .DESCRIPTION
            You can use this function to create a new defined job on your Azure Databricks cluster. Currently only supports Notebook-based jobs. You can also dynamically pass in
            libraries to use in the job, as well as pre-defined parameters. Other non-requied options allow you to change the cluster node and driver types as well as total number
            of worker nodes (or to use an existing defined cluster).
        .PARAMETER Connection
            An object that represents an Azure Databricks API connection where you want to create your job.
        .PARAMETER JobName
            The name of the new job.
        .PARAMETER JobType
            The type of job to run. Currently only supports "Notebook" job types.
        .PARAMETER NotebookPath
            The path on your Azure Databricks instance where your job's notebook resides.
        .PARAMETER JobParameters
            What parameters you should pass into your notebook. Should be a hashtable (see notes).
        .PARAMETER JobLibaries
            What libraries you want to install on your cluster if you're going to be dynamically creating clusters. Should be a hashtable (see notes).
        .PARAMETER UseExistingCluster
            If you want this job to use a predefied Azure Databtricks cluster, specify a named cluster here.
        .PARAMETER NodeType
            For dynamic job clusters, what is the node type you want to use (defaults to: Standard_DS3_v2)
        .PARAMETER NumWorkers
            For dynamic job clusters, what is our max number of workers? (defaults to: 4)
        .PARAMETER SparkVersion
            What version of Spark should the dynamic cluster use? (defaults to: 4.2.x-scala2.11)
        .NOTES
            A sample of the hashtables needed for this function:
            
            $JobLibraries = @{
                'pypi' = 'simplejson=3.8.0'    
            }
            Each line of your hashtable should be either of type pypi or egg. If egg, specify the path to the egg.

            $Parameters = @{
                'Param1' = 'X'
                'Param2' = 2                    
            }
            Each line of your hashtable should a key/value pair of the name of the paramter in your notebook and the value you want to pass in.

            Author: Drew Furgiuele (@pittfurg), http://www.port1433.com
            Website: https://www.igs.com
            Copyright: (c) 2019 by IGS, licensed under MIT
            License: MIT https://opensource.org/licenses/MIT
        .LINK
            
        .EXAMPLE
            PS C:\> New-AzureDatabricksJob -Connection $Connection -JobName "New Job" -JobType Notebook -NotebookPath "/Users/Drew/SomeNotebook" -UseExistingCluster "DrewsCluster"
            Defines a new job called "New Job" to runs the notebook "SomeNotebook" on the existing cluster "DrewsCluster"
        .EXAMPLE
            PS C:\> New-AzureDatabricksJob -Connection $Connection -JobName "New Job" -JobType Notebook -NotebookPath "/Users/Drew/SomeNotebook" -UseExistingCluster "DrewsCluster" -JobParameters $Parameters
            Defines a new job called "New Job" to runs the notebook "SomeNotebook" on the existing cluster "DrewsCluster" and will use the paremeters in the hashtable $Parameters to pass to the notebook when it runs.
        .EXAMPLE
            PS C:\> New-AzureDatabricksJob -Connection $Connection -JobName "New Job" -JobType Notebook -NotebookPath "/Users/Drew/SomeNotebook"
            Defines a new job called "New Job" to runs the notebook "SomeNotebook" as a new cluster with the default node type, number of works, and Spark version.
        #>    
    Param (
        [Parameter(Mandatory=$true)] [object] $Connection,
        [Parameter(Mandatory=$true)] [string] $JobName,
        [Parameter(Mandatory=$true)] [ValidateSet('Notebook')] [string] $JobType,
        [Parameter(Mandatory=$true)] [string] $NotebookPath,
        [Parameter(Mandatory=$false)] [hashtable] $JobParameters,
        [Parameter(Mandatory=$false)] [hashtable] $JobLibraries,
        [Parameter(Mandatory=$false)] [string] $UseExistingCluster,
        [Parameter(Mandatory=$false,ParameterSetName="DynamicCluster")] [string] $NodeType = "Standard_DS3_v2",
        [Parameter(Mandatory=$false,ParameterSetName="DynamicCluster")] [int] $NumWorkers = 4,
        [Parameter(Mandatory=$false,ParameterSetName="DynamicCluster")] [string] $SparkVersion = "4.2.x-scala2.11"
    )
    
    begin {
        $TargetURI = $Connection.BaseURI.AbsoluteUri + "api/2.0/jobs/create"
    }

    process {
        $Databricks = New-AzureDatabricksRequest -Uri $TargetURI -AccessToken $Connection.AccessToken -RequestMethod POST  -UseBasicParsing $Connection.UseBasicParsing
        $Databricks.AddBody("name",$JobName)
        $Databricks.AddBody("timeout_seconds",3600)
        $Databricks.AddBody("max_retries",1)

        if ($UseExistingCluster) {
            $ClusterID = (Get-AzureDatabricksCluster -Connection $Connection | Where-Object {$_.Name -eq $UseExistingCluster}).ClusterID
            if (!$clusterID) {
                throw "Unable to find cluster!"
            }
            $Databricks.AddBody("existing_cluster_id",$ClusterID)
        } else {
            $Cluster = [pscustomobject] @{
                spark_version = "4.2.x-scala2.11"
                node_type_id = "Standard_DS3_v2"
                num_workers = 4
            }
            $Databricks.AddBody("new_cluster",$Cluster)
        }
        
        switch ($JobType) {
            "Notebook" {
                try {
                    $TestForNotebook = Get-AzureDatabricksNotebook -Connection $Connection -Path $NotebookPath
                    $NoteBook = [pscustomobject] @{
                        notebook_path = $NotebookPath    
                    }
                    if ($JobParameters) {
                        $Notebook.Add("base_parameters", $JobParameters)
                    }
                    $Databricks.AddBody("notebook_task",$Notebook)
                } catch {
                    throw "Unable to add notebook (does it exist?)"
                }
            }
        }

        if ($JobLibraries) {
            $Libraries = @()
            ForEach ($l in $JobLibraries.Keys) {
                Write-Verbose "Parsing library definition"
                switch ($l) {
                    "egg" {
                        Write-Verbose "I am in the egg!"
                        $Library = [PSCustomObject] @{
                            egg = $JobLibraries[$l]
                        }
                    }
                    "pypi" {
                        $SubLibrary = [PSCustomObject]  @{
                            package = $JobLibraries[$l]
                        }
                        $Library = [PSCustomObject]  @{
                            #pypi = ($SubLibrary | ConvertTo-Json)
                            pypi = $SubLibrary
                        }
                    }
                }
                $Libraries += $Library
            }
            $Databricks.AddBody("libraries",$Libraries)
        }
        $CreationResponse = $Databricks.Submit() #| ConvertFrom-Json
        $NewJobId = $CreationResponse.job_id
        Write-Verbose "Job created, new JobId = $NewJobId"
        Get-AzureDatabricksJob -Connection $Connection | Where-Object {$_.JobID -eq $NewJobID}
    }
}