class AzureDatabricksWorkspace {
    [string] $ObjectType
    [string] $ObjectPath

    AzureDataBricksWorkSpace ([string] $ObjectType, [string] $ObjectPath) {
        $this.ObjectType = $ObjectType
        $this.ObjectPath = $ObjectPath
    }

}

class DatabricksRequestObject {
    [string] $RequestURI
    [string] $RequestMethod
    [hashtable] $RequestHeaders = [pscustomobject] @{}
    [hashtable] $RequestBody = [pscustomobject] @{}
    [bool] $IgnoreResponse = $False
    [bool] $UseBasicParsing = $False
    hidden $RequestResponse
    hidden [int] $UnavailableRetries = 0
    hidden [int] $MaxUnavailableRetries = 5
    hidden [string] $RawResponse 

    AddHeader([string] $Key, [string] $Value) {
        $this.RequestHeaders.Add($key, $Value)
    }

    AddBody([string] $key, $Value) {
        $this.RequestBody.Add($key, $Value)                
    }

    [System.Object] Submit() {
        [string] $ReasonText = $null
        [string] $WhereFrom = $null

        $ResponseObject = [PSCustomObject] @{
            TimeStamp = Get-Date
            ResponseIgnored = $False
        }
        $IWRParams = @{
            URI=$this.RequestURI;
            Headers=$this.RequestHeaders;
            Method=$this.RequestMethod;
        }
        if ($this.RequestMethod -eq "POST") {
            $IWRParams.Add('Body',($this.RequestBody | ConvertTo-Json -Depth 99))
        }
        if ($this.UseBasicParsing -eq $True) {
            $IWRParams.Add('UseBasicParsing',$True)
        }
        try {
            $this.RawResponse = Invoke-WebRequest @IWRParams
        } catch {
            if ($_.ErrorDetails.Message) {
                $ErrorMessages = ($_.ErrorDetails.Message).Split([System.Environment]::NewLine)
                $WhereFrom = $ErrorMessages | Where-Object {$_ -like "Problem Accessing*"}
                $ReasonPosition = $ErrorMessages.IndexOf($WhereFrom)
                $ReasonText = $ErrorMessages[$ReasonPosition+1].Trim()
                if ($ReasonText.Contains("TEMPORARILY_UNAVAILABLE")) {
                    $this.UnavailableRetries = $this.UnavailableRetries + 1
                    if ($this.UnavailableRetries -ge $this.MaxUnavailableRetries) {
                        $TotalRetries = $this.UnavailableRetries
                        throw "The Databricks API has been unavailable for $TotalRetries. There must be a larger issue. Please check the Databricks services."
                    } else {
                        Write-Warning "The Databricks API was temporarily unavailable. Let's wait 120 seconds and try again"
                        Start-Sleep -Seconds 120
                        $this.Submit()
                    }
                } elseif ($ReasonText.Contains("INTERNAL_ERROR")) {
                    $this.UnavailableRetries = $this.UnavailableRetries + 1
                    if ($this.UnavailableRetries -ge $this.MaxUnavailableRetries) {
                        $TotalRetries = $this.UnavailableRetries
                        throw "The Databricks API has been unavailable for $TotalRetries. There must be a larger issue. Please check the Databricks services."
                    } else {
                        Write-Warning "The Databricks API returned an internal error. Let's wait 120 seconds and try again"
                        Start-Sleep -Seconds 120
                        $this.Submit()
                    }                
                } else {
                    throw ($WhereFrom + " " + $ReasonText)
                }
            } else {
                $ErrorMessage = $_
                throw ("Generic error: $ErrorMessage")                
            }
        }
        if ($this.IgnoreResponse -eq $False) {
            $ResponseJSON = $this.RawResponse | ConvertFrom-Json
            $ReturnedProperties = $ResponseJSON | Get-Member | Where-Object {$_.MemberType -eq "NoteProperty"}
            ForEach ($r in $ReturnedProperties) {
                $ResponseObject | Add-Member -MemberType NoteProperty -Name $r.Name -Value ($ResponseJSON.($r.Name))
            }
        } else {
            $ResponseObject.ResponseIgnored = $True
        }
        return $ResponseObject
    }
}

class AzureDatabricksJob {
    [int] $JobID
    [string] $Name
    [object] $JobSettings
    [datetime] $CreatedTime
    [string] $CreatedBy
}

class AzureDatabricksJobSettings {
    [string] $SparkVersion
    [string] $NodeTypeID
    [int] $NumberOfWorkers
    [object[]] $Libraries
    [object[]] $Parameters
    [string[]] $EmailStartNotification
    [string[]] $EmailSuccessNotification
    [string[]] $EmailFailureNotification
    [bool] $NoAlertEmailsForSkippedRuns
    [int] $TimeoutSeconds
    [int] $MaxRetries

    [string] ToString() {
        return "{Settings}"
    }
}

class AzureDataBricksParameterPair {
    [string] $Key
    [string] $Value

    [string] ToString() {
        return $this.Key
    }
}

class AzureDatabricksJobLibrary {
    [string] $LibraryType
    [pscustomObject] $LibraryInfo

    [string] ToString() {
        return $this.LibraryType
    }

}
class AzureDatabricksJobStatus {
    [int] $JobID
    [string] $JobName
    [int] $RunID
    [string] $Status
    [object] $Cluster
    [string] $Result
    [string] $Message
    [datetime] $StartTime
    [int64] $SetupDuration
    [int64] $Duration
    [int64] $CleanupDuration
    [datetime] $FinishTime
    [string] $CreatedBy
}

class AzureDatabricksJobStatusClusterInfo {
    [string] $ClusterID
    [string] $SparkContextID

    [String] ToString()
    {
        return "{ClusterID: " + $this.ClusterID + ", SparkContextID: " + $this.SparkContextID + "}"
    }

}

class AzureDataBricksNotebook {
    [String] $NotebookName
    [String] $NotebookPath

    AzureDataBricksNotebook([string] $NotebookName, [string] $NotebookPath) {
        $this.NotebookName = $NotebookName
        $this.NotebookPath = $NotebookPath
    }
}
class AzureDataBricksConnection {
    [uri] $BaseURI
    [string] $AccessToken
    [string] $Protocols
    [bool] $UseBasicParsing = $False

    AzureDataBricksConnection([Uri] $BaseURI, [string] $AccessToken, [string] $Protocols, [bool] $UseBasicParsing) {
        $this.BaseURI = $BaseURI
        $this.AccessToken = $AccessToken
        $this.Protocols = $Protocols
        $this.UseBasicParsing = $UseBasicParsing
    }

    [String] ToString()
    {
        return ($this.BaseURI).ToString() + ":" + $this.AccessToken
    }
}
class AzureDatabricksSubmittedRun {
    [int] $JobID
    [int] $RunID
    [int] $NumberInJob
}
class AzureDatabricksCancelledJob {
    [int] $JobID
    [int] $RunID
}

class AzureDatabricksDeletedJob {
    [int] $JobID
    [string] $Name
    [DateTime] $CreatedTime
    [string] $CreatedBy
    [DateTime] $DeletedTime
}

class AzureDatabricksCluster {
    [string] $ClusterID
    [string] $Name
    [int] $NumberOfWorkers
    [int] $AutoscaleMinWorkers
    [int] $AutoscaleMaxWorkers
    [int] $ClusterMemoryMB
    [int] $ClusterCores
    [string] $Creator
    [string] $DriverNodeTypeID
    [object] $Driver
    [string] $NodeTypeID
    [object[]] $SparkNodes
    [int64] $SparkContextID
    [int] $JBDCPort
    [string] $SparkVersion
    [PSCustomObject] $SparkEnvironment
    [int] $AutoTerminateMinutes
    [bool] $EnableElasticDisk
    [string] $ClusterState
    [string] $ClusterStateMessage
    [nullable[datetime]] $StartTime
    [nullable[datetime]] $TerminatedTime
    [nullable[datetime]] $LastStateLossTime
    [nullable[datetime]] $LastActivityTime
    [string] $TerminationCode
    [PSCustomObject] $Tags
}

class AzureDatabricksSparkNode {
    [string] $PrivateIP
    [string] $PublicDNS
    [string] $NodeID
    [string] $InstanceID
    [datetime] $LaunchTime
    [string] $HostPrivateIP

    [string] ToString() {
        return "{SparkNode}"
    }
}