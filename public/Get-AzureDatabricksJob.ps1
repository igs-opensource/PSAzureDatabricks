function Get-AzureDatabricksJob {
    <#
        .SYNOPSIS
            Returns an array of objects representing all defined Azure Databricks job for a given connection.
        .DESCRIPTION
            Returns an array of objects representing all defined Azure Databricks job for a given connection.
        .PARAMETER Connection
            An object that represents an Azure Databricks API connection where you want to get a list of defined jobs from.
        .NOTES
            Author: Drew Furgiuele (@pittfurg), http://www.port1433.com
            Website: https://www.igs.com
            Copyright: (c) 2019 by IGS, licensed under MIT
            License: MIT https://opensource.org/licenses/MIT
        .LINK
            
        .EXAMPLE
            PS C:\> Get-AzureDatabricksJob -Connection $Connection
            Gets all defined jobs from the Azure Databricks instance $Connection
    
        #>     
    Param (
        [Parameter(Mandatory=$true)] [object] $Connection
    )

    begin {
        $TargetURI = $Connection.BaseURI.AbsoluteUri + "api/2.0/jobs/list"
    }

    process {
        $JobsRequest = New-AzureDatabricksRequest -Uri $TargetURI -AccessToken $Connection.AccessToken -UseBasicParsing $Connection.UseBasicParsing
        $JobsList = $JobsRequest.Submit()
        ForEach ($j in $JobsList.jobs) {
            $JobObject = New-Object AzureDatabricksJob
            $JobObject.JobID = $j.job_id
            $DateObject = New-Object -Type datetime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
            $DateObject = $DateObject.AddMilliseconds($j.created_time)
            $JobObject.CreatedTime = $DateObject
            $JobObject.CreatedBy = $j.creator_user_name

            $JobSettingsObject = New-Object AzureDatabricksJobSettings
            
            $JobObject.Name = $j.settings.name
            $JobSettingsObject.SparkVersion = $j.settings.new_cluster.spark_version
            $JobSettingsObject.NodeTypeID = $j.settings.new_cluster.node_type_id
            $JobSettingsObject.NumberOfWorkers = $j.settings.new_cluster.num_workers
            ForEach($e in $j.settings.email_notifications.on_start) {
                $JobSettingsObject.EmailStartNotification += $e
            }
            ForEach($e in $j.settings.email_notifications.on_success) {
                $JobSettingsObject.EmailSuccessNotification += $e
            }
            ForEach($e in $j.settings.email_notifications.on_failure) {
                $JobSettingsObject.EmailFailureNotification += $e
            }
            if ($j.email_notifications.no_alert_for_skipped_runs -eq "True") {
                $JobSettingsObject.NoAlertEmailsForSkippedRuns = $True
            }
            $JobSettingsObject.TimeoutSeconds = $j.settings.timeout_seconds
            $JobSettingsPropertyList = $j.settings.PSObject.Properties.Name
            switch ($JobSettingsPropertyList) {
                "notebook_task" {
                    $LibraryObject = New-Object AzureDatabricksJobLibrary
                    $LibraryObject.LibraryType = "Notebook"
                    $NotebookInfo = @{
                        NotebookPath = $j.settings.notebook_task.notebook_path
                        NotebookRevisionTimestamp = $j.settings.notebook_task.revision_timestamp
                    }
                    $LibraryObject.LibraryInfo = $NotebookInfo
                    $JobSettingsObject.Libraries += $LibraryObject
                    $NotebookParameters = $j.settings.notebook_task.base_parameters
                    ForEach ($n in $NotebookParameters) {
                        $ParameterProperties = $n.PSObject.Properties
                        ForEach ($pp in $ParameterProperties) {
                            $ParameterObject = New-Object AzureDataBricksParameterPair
                            $ParameterObject.Key = $pp.name
                            $ParameterObject.Value = $n.($pp.name)
                            $JobSettingsObject.Parameters += $ParameterObject
                        }
                    }
                }
            }
            $JobObject.JobSettings = $JobSettingsObject
            $JobObject
        }
    }
}