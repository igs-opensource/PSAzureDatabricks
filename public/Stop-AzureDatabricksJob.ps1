function Stop-AzureDatabricksJob {
    <#
        .SYNOPSIS
            Stops a running Azure Databricks job.
        .DESCRIPTION
            This function will stop an already-running Azure Databricks job by job ID.
        .PARAMETER Connection
            An object that represents an Azure Databricks API connection where you want to stop your job.
        .PARAMETER ClusterID
            The cluster ID you want to stop.
        .NOTES
            Author: Drew Furgiuele (@pittfurg), http://www.port1433.com
            Website: https://www.igs.com
            Copyright: (c) 2019 by IGS, licensed under MIT
            License: MIT https://opensource.org/licenses/MIT
        .LINK
            
        .EXAMPLE
            PS C:\> Stop-AzureDatabricksJob -Connection $Connection -JobID 1
            Stops job id 1 on the Azure Databricks instance defined in $Connection
    #>      
    Param (
        [Parameter(Mandatory=$true)] [object] $Connection,
        [Parameter(Mandatory=$true)] [int] $RunID,
        [Parameter(Mandatory=$false)] [switch] $Force
    )

    begin {
        $TargetURI = $Connection.BaseURI.AbsoluteUri + "api/2.0/jobs/runs/cancel"
    }

    process {
        $RunStatus = Get-AzureDatabricksJobRun -Connection $Connection -RunID $RunID
        if (($RunStatus.Status -eq "PENDING" -or $RunStatus.Status -eq "RUNNING") -or $Force) {
            $StopJob = New-AzureDatabricksRequest -Uri $TargetURI -AccessToken $Connection.AccessToken -RequestMethod POST -ExpectingNoReply
            $StopJob.AddBody("run_id","$RunID")
            $StopJob.Submit()
            $CancelResult.RequestBody
            $CancelledJob = New-Object AzureDatabricksCancelledJob
            $CancelledJob.JobID = $JobID
            $CancelledJob.RunID = $RunID
        } else {
            Write-Warning "Job not in a RUNNING or PENDING state; to force stop command anyway, use -Force"
        }
    }
}