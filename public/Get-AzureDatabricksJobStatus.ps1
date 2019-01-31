function Get-AzureDatabricksJobStatus {
    <#
        .SYNOPSIS
            Returns an object representing the status of a single job defined on an Azure Databricks instance.
        .DESCRIPTION
            Returns an object representing the status or outcome of all runs or a single job run defined on an Azure Databricks instance. You can provide a RunID to filter for a specific job, 
            and the function also supports filters for running or completed jobs.
        .PARAMETER Connection
            An object that represents an Azure Databricks API connection where you want to get a list of job runs from.
        .PARAMETER JobID
            The JobID of the job you want the status of.
        .PARAMETER RunType
            Filter for Active or Completed jobs.
        .NOTES
            Author: Drew Furgiuele (@pittfurg), http://www.port1433.com
            Website: https://www.igs.com
            Copyright: (c) 2019 by IGS, licensed under MIT
            License: MIT https://opensource.org/licenses/MIT
        .LINK
            
        .EXAMPLE
            PS C:\> Get-AzureDatabricksJobStatus -Connection $Connection
            Returns an array of objects that shows the outcome of all executions of all jobs on a given Azure Databricks instance.
        .EXAMPLE
            PS C:\> Get-AzureDatabricksJobRun -Connection $Connection -JobID 1
            Returns array of objects that shows the outcome executions of JobID 1 on a given Azure Databricks instance.
        #>         
    Param (
        #Should accept JobObject, SubmittedJobObject, or JobID int
        [Parameter(Mandatory=$true)] [object] $Connection,
        [Parameter(Mandatory=$false)] [int] $JobID
    )

    begin {
        $TargetURI = $Connection.BaseURI.AbsoluteUri + "api/2.0/jobs/runs/list"
        if ($JobID) {
            $TargetURI += "?job_id=$JobID"
        }
    }

    process {
        $JobsRequest = New-AzureDatabricksRequest -Uri $TargetURI -AccessToken $Connection.AccessToken -UseBasicParsing $Connection.UseBasicParsing
        $JobStatus = $JobsRequest.Submit()
        
        ForEach ($j in $JobStatus.Runs) {
            $JobStatusObject = New-Object AzureDatabricksJobStatus
            $JobStatusObject.JobID = $j.job_id
            $JobStatusObject.RunID = $j.run_id
            $JobStatusObject.Status = $j.state.life_cycle_state
            $JobStatusObject.Result = $j.state.result_state
            $JobStatusObject.Message = $j.state.state_message
            $DateObject = New-Object -Type datetime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
            $DateObject = $DateObject.AddMilliseconds($j.start_time)
            $JobStatusObject.StartTime = $DateObject
            $JobStatusObject.SetupDuration = $j.setup_duration
            $JobStatusObject.Duration = $j.execution_duration
            $JobStatusObject.CleanupDuration = $j.cleanup_duration
            $JobStatusObject.FinishTime = $DateObject.AddMilliseconds($j.setup_duration + $j.execution_duration + $j.cleanup_duration)
            $JobStatusObject.CreatedBy = $j.creator_user_name
            $JobStatusObject.JobName = $j.run_name
            $JobStatusObject
        }
       
    }
}