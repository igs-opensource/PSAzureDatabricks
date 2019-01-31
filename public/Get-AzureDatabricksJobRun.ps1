function Get-AzureDatabricksJobRun {
    <#
        .SYNOPSIS
            Returns an object representing the status or outcome(s) of a single job on an Azure Databricks instance.
        .DESCRIPTION
            Returns an object representing the status or outcome of all or a single job run(s) on an Azure Databricks instance. You can provide a RunID to filter for a specific job, 
            and the function also supports filters for running or completed jobs.
        .PARAMETER Connection
            An object that represents an Azure Databricks API connection where you want to get a list of job runs from.
        .PARAMETER RunID
            RunID of a given run ID to return, otherwise the object returns all runs for every defined job.
        .PARAMETER RunType
            Filter for Active or Completed jobs.
        .NOTES
            Author: Drew Furgiuele (@pittfurg), http://www.port1433.com
            Website: https://www.igs.com
            Copyright: (c) 2019 by IGS, licensed under MIT
            License: MIT https://opensource.org/licenses/MIT
        .LINK
            
        .EXAMPLE
            PS C:\> Get-AzureDatabricksJobRun -Connection $Connection
            Returns an array of objects detailing all Job Runs on a the Azure Databricks connection defined in $Connection
        .EXAMPLE
            PS C:\> Get-AzureDatabricksJobRun -Connection $Connection -RunID 1
            Returns an array of objects detailing Job Run number 1 on a the Azure Databricks connection defined in $Connection
        .EXAMPLE
            PS C:\> Get-AzureDatabricksJobRun -Connection $Connection -Active
            Returns an array of objects detailing all currently running Job Runs on a the Azure Databricks connection defined in $Connection
        #>     
    Param (
        [Parameter(Mandatory=$true)] [object] $Connection,
        [Parameter(Mandatory=$false)] [int] $RunID,
        [Parameter(Mandatory=$false)] [ValidateSet('Active','Completed')] [string] $RunType

    )

    begin {
        if ($RunId) {
            $TargetURI = $Connection.BaseURI.AbsoluteUri + "api/2.0/jobs/runs/get?run_id=$RunID"
        } else {
            $TargetURI = $Connection.BaseURI.AbsoluteUri + "api/2.0/jobs/runs/list"
            switch ($RunType) {
                "Active" {
                    $TargetURI += "?active_only=true"
                }
                "Completed" {
                    $TargetURI += "?completed_only=true"
                }
            }
        }
    }

    process {
        $RunsRequest = New-AzureDatabricksRequest -Uri $TargetURI -AccessToken $Connection.AccessToken -UseBasicParsing $Connection.UseBasicParsing
        $RunList = $RunsRequest.Submit()
        $AllRuns = @()
        if ($RunList.PSObject.Properties.name -match "runs") {
            $AllRuns = $RunList.runs
        } else {
            $AllRuns += $Runlist
        }
        ForEach ($a in $AllRuns) {
            if($a.job_id) {
                $RunObject = New-Object AzureDatabricksJobStatus
                $RunObject.JobID = $a.job_id
                $RunObject.RunID = $a.run_id
                $RunObject.Status = $a.state.life_cycle_state
                $RunCluster = New-Object AzureDatabricksJobStatusClusterInfo
                $RunCluster.ClusterID = $a.cluster_instance.cluster_id
                $RunCluster.SparkContextID = $a.cluster_instance.spark_context_id
                $RunObject.Cluster  = $RunCluster
                $RunObject.Result = $a.state.result_state
                $RunObject.Message = $a.state.state_message
                $DateObject = New-Object -Type datetime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
                $DateObject = $DateObject.AddMilliseconds($a.start_time)
                $RunObject.StartTime = $DateObject
                $RunObject.SetupDuration = $a.setup_duration
                $RunObject.Duration = $a.execution_duration
                $RunObject.CleanupDuration = $a.cleanup_duration
                $RunObject.FinishTime = $DateObject.AddMilliseconds($a.setup_duration + $a.execution_duration + $a.cleanup_duration)
                $RunObject.CreatedBy = $a.creator_user_name
                $RunObject.JobName = $a.run_name
                $RunObject
            }
        }
    }
}