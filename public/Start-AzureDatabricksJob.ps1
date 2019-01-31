function Start-AzureDatabricksJob {
    <#
        .SYNOPSIS
            Starts an Azure Databricks Job by Job ID
        .DESCRIPTION
            Starts a predfined job on an Azure Databricks instance. This function will wait for the job complete by default. If you want
            the function to NOT wait for the job to finish, include the -RunAsync switch parameter.
        .PARAMETER Connection
            An object that represents an Azure Databricks API connection where you want to remove your job from
        .PARAMETER JobID
            The Job ID of the job you want to start.
        .PARAMETER Parameters
            Any dynamic parameters you want to pass the notebook defined in your job step. Should be passed in as a hashtable (see notes)
        .PARAMETER RunAsync
            A flag to indicate if the function should wait for the job to stop or not. True will run the job without waiting for a result.
        .NOTES
            A sample of the hashtables needed for this function:
            
            $Parameters = @{
                'ParameterName' = 'value1'
                'ParameterName2' = 2
            }
            
            Each line of your hashtable should a key/value pair of the name of the paramter in your notebook-based job and the value(s) you want to pass in.

            Author: Drew Furgiuele (@pittfurg), http://www.port1433.com
            Website: https://www.igs.com
            Copyright: (c) 2019 by IGS, licensed under MIT
            License: MIT https://opensource.org/licenses/MIT
        .LINK
            
        .EXAMPLE
            PS C:\> Start-AzureDatabricksJob -Connection $Connection -JobID 1
            Starts job id 1 on the Azure Databricks instance defined in $Connection

            PS C:\> Start-AzureDatabricksJob -Connection $Connection -JobID 1 -RunAsync
            Starts job id 1 on the Azure Databricks instance defined in $Connection without waiting for the job to complete.

            PS C:\> Start-AzureDatabricksJob -Connection $Connection -JobID 1 -Parameters $Params
            Starts job id 1 on the Azure Databricks instance defined in $Connection while also passing in the paramters defined in the hashtable $Params
            for the notebook referenced in the job
    #>      
    Param (
        [Parameter(Mandatory=$true)] [object] $Connection,
        [Parameter(Mandatory=$true)] [int] $JobID,
        [Parameter(Mandatory=$false)] [hashtable] $Parameters,
        [Parameter(Mandatory=$false)] [switch] $RunAsync
    )

    begin {
        $TargetURI = $Connection.BaseURI.AbsoluteUri + "api/2.0/jobs/run-now"
        $BadResults = @('SKIPPED','INTERNAL_ERROR')
        $BadStatuses = @('FAILED','TIMEDOUT','CANCELLED')
    }

    process {
        $RunJob = New-AzureDatabricksRequest -Uri $TargetURI -AccessToken $Connection.AccessToken -RequestMethod POST -UseBasicParsing $Connection.UseBasicParsing
        $RunJob.AddBody("job_id",$JobID)
        $JobInfo = Get-AzureDatabricksJob -Connection $Connection | Where-Object {$_.JobID -eq $JobID}
        $JobName = $JobInfo.Name
        if (!$JobInfo) {
            throw "Job ID $JobID not found, stopping..."
        }
        if ($Parameters) {
            switch ($JobInfo.JobSettings.Libraries.LibraryType) {
                "Notebook" {
                    $RunJob.AddBody("notebook_params", $Parameters)
                }
            }
        }
        Write-Verbose "Starting job `"$JobName`" (job ID $JobID)..."
        $SubmitResult = $RunJob.Submit()
        $SubmittedJob = New-Object AzureDatabricksSubmittedRun
        $SubmittedJob.JobID = $JobID
        $SubmittedJob.RunID = $SubmitResult.run_id
        $JobRunID = $SubmittedJob.RunID
        $SubmittedJob.NumberInJob = $SubmittedResult.number_in_job
        Write-Verbose "Succesfully started job `"$JobName`" (job ID $JobID), as run ID $JobRunID"
        if ($RunAsync) {
            Write-Information "Job started asynchronusly, please monitor the job for the result"
            $AzureDatabricksJobStatus = Get-AzureDatabricksJobRun -Connection $Connection -RunID $SubmittedJob.RunID
        } else {
            Write-Information "Waiting for job completion..."
            $AzureDatabricksJobStatus = Watch-AzureDatabricksJob -Connection $Connection -JobID $SubmittedJob.JobID -RunID $SubmittedJob.RunID
            if ($AzureDatabricksJobStatus.Status -in $BadResults -or $AzureDatabricksJobStatus.Result -in $BadStatuses) {
                $JobMessage = $AzureDatabricksJobStatus.Message
                throw "Job failed! Reason: $JobMessage. See the UI for more info."
            }
            $AzureDatabricksJobStatus
        }
        $AzureDatabricksJobStatus
    }
}