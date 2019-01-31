function Get-AzureDatabricksCluster {
    <#
        .SYNOPSIS
            Returns an object representing defined Azure Databricks clusters.
        .DESCRIPTION
            Returns an object representing defined Azure Databricks clusters. If a cluster ID is supplied, it will filter for a specific cluster, otherwise it will return an
            array of cluster objects.
        .PARAMETER Connection
            An object that represents an Azure Databricks API connection where you want to get your clusters from.
        .PARAMETER ClusterID
            The cluster ID of the specific databricks cluster you want to return.
        .NOTES
            Author: Drew Furgiuele (@pittfurg), http://www.port1433.com
            Website: https://www.igs.com
            Copyright: (c) 2019 by IGS, licensed under MIT
            License: MIT https://opensource.org/licenses/MIT
        .LINK
            
        .EXAMPLE
            PS C:\> Get-AzureDatabricksCluster -Connection $Connection
            Returns an array of Databricks cluster objects defined in the Azure databricks instance defined in $Connection
    
        .EXAMPLE
            PS C:\> Get-AzureDatabricksCluster -Connection $Connection -ClusterID 1
            Returns an object that represents cluster ID number 1 on the Azure Databricks instances defined in $Connection
        #>    
    Param (
        [Parameter(Mandatory=$true)] [object] $Connection,
        [Parameter(Mandatory=$false)] [string] $ClusterID
    )

    begin {
        if ($ClusterID) {
            $TargetURI = $Connection.BaseURI.AbsoluteUri + "api/2.0/clusters/get?cluster_id=$ClusterID"
        } else {
            $TargetURI = $Connection.BaseURI.AbsoluteUri + "api/2.0/clusters/list"
        }
    }

    process {
        $ClusterRequest = New-AzureDatabricksRequest -Uri $TargetURI -AccessToken $Connection.AccessToken -UseBasicParsing $Connection.UseBasicParsing -RequestMethod GET
        $ClusterResponse = $ClusterRequest.Submit()
        $AllClusters = @()
        if ($ClusterResponse.PSObject.Properties.name -match "clusters") {
            $AllClusters = $ClusterResponse.clusters
        } else {
            $AllClusters += $ClusterResponse
        }
        foreach ($c in $AllClusters)
        {
            $Cluster = New-Object AzureDatabricksCluster
            $Cluster.ClusterID = $c.cluster_id
            $Cluster.NumberOfWorkers = $c.num_workers
            $Cluster.AutoscaleMinWorkers = $c.autoscale.min_workers
            $Cluster.AutoscaleMaxWorkers = $c.autoscale.max_workers
            $Cluster.Creator = $c.creator_user_name
            if ($c.driver) {
                $Driver = New-Object AzureDatabricksSparkNode
                $Driver.PrivateIP = $c.driver.private_ip
                $Driver.PublicDNS = $c.driver.public_dns
                $Driver.NodeID = $c.driver.node_id
                $Driver.InstanceID = $c.driver.instance_id
                $DateObject = New-Object -Type datetime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
                $DateObject = $DateObject.AddMilliseconds($c.driver.start_timestamp)
                $Driver.LaunchTime = $DateObject
                $Driver.HostPrivateIP = $c.driver.host_private_ip
                $Cluster.Driver = $Driver
            }
            ForEach ($e in $c.executors) {
                $Executor = New-Object AzureDatabricksSparkNode
                $Executor.PrivateIP = $e.private_ip
                $Executor.PublicDNS = $e.public_dns
                $Executor.NodeID = $e.node_id
                $Executor.InstanceID = $e.driver.instance_id
                $DateObject = New-Object -Type datetime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
                $DateObject = $DateObject.AddMilliseconds($e.driver.start_timestamp)
                $Executor.LaunchTime = $DateObject
                $Executor.HostPrivateIP = $e.driver.host_private_ip
                $Cluster.SparkNodes += $Executor                
            }
            $Cluster.SparkContextID = $c.spark_context_id
            $Cluster.JBDCPort = $c.jdbc_port
            $Cluster.Name = $c.cluster_name
            $Cluster.SparkVersion = $c.spark_version
            $Cluster.NodeTypeID = $c.node_type_id
            $Cluster.DriverNodeTypeID = $c.driver_node_type_id
            $Cluster.SparkEnvironment = $c.spark_env_vars
            $Cluster.AutoTerminateMinutes = $c.autotermination_minutes
            $Cluster.EnableElasticDisk = $c.enable_elastic_disk
            $Cluster.ClusterState = $c.state
            $Cluster.ClusterStateMessage = $c.state_message
            $DateObject = New-Object -Type datetime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
            $DateObject = $DateObject.AddMilliseconds($c.start_time)
            $Cluster.StartTime = $DateObject
            if ($c.terminated_time -gt 0) {
                $DateObject = New-Object -Type datetime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
                $DateObject = $DateObject.AddMilliseconds($c.terminated_time)
                $Cluster.TerminatedTime = $DateObject
            } else {
                $Cluster.TerminatedTime    = $null
            }
            if ($c.last_state_loss_time -gt 0) {
                $DateObject = New-Object -Type datetime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
                $DateObject = $DateObject.AddMilliseconds($c.last_state_loss_time)
                $Cluster.LastStateLossTime = $DateObject
            } else {
                $Cluster.LastStateLossTime = $null
            }
            if ($c.last_activity_time -gt 0) {
                $DateObject = New-Object -Type datetime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
                $DateObject = $DateObject.AddMilliseconds($c.last_activity_time)
                $Cluster.LastActivityTime = $DateObject
            } else {
                $Cluster.LastActivityTime = $null
            }
            $Cluster.ClusterMemoryMB = $c.cluster_memory_mb
            $Cluster.ClusterCores = $c.cluster_cores
            $Cluster.TerminationCode = $c.termination_reason.code
            $Cluster.Tags = $c.default_tags
            $Cluster
        }
    }
}