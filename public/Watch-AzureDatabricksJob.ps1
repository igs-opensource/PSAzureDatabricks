function Watch-AzureDatabricksJob {
    <#
        .SYNOPSIS
            Monitors a running Azure Databricks job for completion.
        .DESCRIPTION
            This function will remotely monitor a running Azure Databricks job, waiting until a job finishes. A "finished" job can be successful or not, it's just
            defined as a job that is no longer running. This function will return verbose messaging with the current status of a running job as well. Finally, this function
            has some built in error handling for some common Azure Databricks API errors.
        .PARAMETER Connection
            An object that represents an Azure Databricks API connection where you want to test your paths.
        .PARAMETER JobID
            The job ID you want to monitor.
        .PARAMETER RunID
            The run ID you want to monitor. The run ID in question should be an in-process run.
        .PARAMETER PollIntervalSeconds
            How often the API should be queried for the status of a job run. Defaults to every 60 seconds. As of this writing, best practice from the Azure Databricks
            team is NOT have this query more than once a minute, as it could potentially overload the API. This supposedly will be addressed soon, according to support.
        .NOTES
            Author: Drew Furgiuele (@pittfurg), http://www.port1433.com
            Website: https://www.igs.com
            Copyright: (c) 2019 by IGS, licensed under MIT
            License: MIT https://opensource.org/licenses/MIT
        .LINK
            
        .EXAMPLE
            PS C:\> Watch-AzureDatabricksJob -Connection $Connection -JobID 1 -RunID 100
            Wait for job ID 1, run ID 100 to finish while monitoring the status every 60 seconds. Returns an object that represents the job outcome.
    #>  
    Param (
        [Parameter(Mandatory=$true)] [object] $Connection,
        [Parameter(Mandatory=$true)] [int] $JobID,
        [Parameter(Mandatory=$true)] [int] $RunID,
        [Parameter(Mandatory=$false)] [int] $PollIntervalSeconds = 60
    )

    begin {
        $RunningStates = @('PENDING','RUNNING')
        $BadResults = @('FAILED','TIMEDOUT')
    }

    process {
        $JobObject = Get-AzureDatabricksJob -Connection $Connection | Where-Object {$_.JobID -eq $JobID}
        if ($JobObject) {
            Write-Verbose "Getting job status for Run ID $RunID..."
            $JobRunsForJob = Get-AzureDatabricksJobRun -Connection $Connection | Where-Object {$_.JobID -eq $JobID}
            if ($JobRunsForJob.RunID -contains $RunID) {
                $RunObject = Get-AzureDatabricksJobRun -Connection $Connection -RunID $RunID
                while ($RunObject.Status -in $RunningStates) {
                    Write-Verbose "Job is active, waiting $PollIntervalSeconds seconds..."
                    Start-Sleep -Seconds $PollIntervalSeconds
                    Write-Verbose "Getting job status for run ID $RunID..."
                    $RunObject = Get-AzureDatabricksJobRun -Connection $Connection -RunID $RunID
                }
                if ($RunObject.Result -in $BadResults) {
                    Write-Verbose "Bad result detected, stopping the job cluster"
                    $JobCluster = $RunObject.Cluster.ClusterID
                    $ActiveRuns = Get-AzureDatabricksJobRun -Connection $Connection -RunType Active | Where-Object {$_.JobID -ne $JobID -and $_.RunID -ne $RunID}
                    if ($JobCluster -in $ActiveRuns.Cluster.ClusterID) {
                        Write-Warning "Unable to stop cluster; other job runs are using it"
                    } else {
                        Stop-AzureDatabricksCluster -Connection $Connection -ClusterID $JobCluster
                        throw ("Job error encountered; cluster stop command issued")
                    }
                }
            } else {
                throw "Run ID $RunID not found for Job ID $JobID"
            }
        } else {
            throw "Job ID not found"
        }
        $RunObject
    }
}