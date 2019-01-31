function Remove-AzureDatabricksJob {
    <#
        .SYNOPSIS
            Deletes a defined Azure Databricks job.
        .DESCRIPTION
            Deletes a defined Azure Databricks job. Returns an object representing the deleted job with details.
        .PARAMETER Connection
            An object that represents an Azure Databricks API connection where you want to remove your job from
        .PARAMETER JobID
            The name of the cluster you want to install the libraries on.
        .NOTES
            Author: Drew Furgiuele (@pittfurg), http://www.port1433.com
            Website: https://www.igs.com
            Copyright: (c) 2019 by IGS, licensed under MIT
            License: MIT https://opensource.org/licenses/MIT
        .LINK
            
        .EXAMPLE
            PS C:\> Remove-AzureDatabricksJob -Connection $Connection -JobID 1
            Removes the job matching job id 1 on the Azure Databricks instance defined in $Connection
    #>    
    Param (
        [Parameter(Mandatory=$true)] [object] $Connection,
        [Parameter(Mandatory=$true)] [int] $JobID
    )

    begin {
        $TargetURI = $Connection.BaseURI.AbsoluteUri + "api/2.0/jobs/delete"
    }

    process {
        $JobInfo = Get-AzureDatabricksJob -Connection $Connection | Where-Object {$_.JobID -eq $JobID}

        if ($JobInfo) {
            $DeleteJob = New-AzureDatabricksRequest -Uri $TargetURI -AccessToken $Connection.AccessToken -RequestMethod POST -ExpectingNoReply -UseBasicParsing $Connection.UseBasicParsing
            $DeleteJob.AddBody("job_id",$JobID)
            $DeleteResult = $DeleteJob.Submit()
            $DeletedJobObject = New-Object AzureDatabricksDeletedJob
            $DeletedJobObject.JobID = $JobID
            $DeletedJobObject.Name = $JobInfo.Name
            $DeletedJobObject.CreatedTime = $JobInfo.CreatedTime
            $DeletedJobObject.CreatedBy = $JobInfo.CreatedBy
            $DeletedJobObject.DeletedTime = Get-Date
            $DeletedjobObject
        } else {
            throw "Job ID $JobID not found"
        }
    }
}