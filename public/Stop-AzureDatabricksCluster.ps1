function Stop-AzureDatabricksCluster {
    <#
        .SYNOPSIS
            Stops a running Azure Databricks cluster.
        .DESCRIPTION
            This function will stop an already-running Azure Databricks cluster by cluster ID.
        .PARAMETER Connection
            An object that represents an Azure Databricks API connection where you want to remove your job from.
        .PARAMETER ClusterID
            The cluster ID you want to stop.
            Author: Drew Furgiuele (@pittfurg), http://www.port1433.com
            Website: https://www.igs.com
            Copyright: (c) 2019 by IGS, licensed under MIT
            License: MIT https://opensource.org/licenses/MIT
        .LINK
            
        .EXAMPLE
            PS C:\> Stop-AzureDatabricksCluster -Connection $Connection -ClusterID 1
            Stops cluster id 1 on the Azure Databricks instance defined in $Connection
    #>      

    Param (
        [Parameter(Mandatory=$true)] [object] $Connection,
        [Parameter(Mandatory=$true)] [string] $ClusterID
    )

    begin {
        $TargetURI = $Connection.BaseURI.AbsoluteUri + "api/2.0/clusters/delete"
    }

    process {
        $ClusterObject = Get-AzureDatabricksCluster -Connection $Connection -ClusterID $ClusterID
        if ($ClusterObject) {
            $DeleteRequest = New-AzureDatabricksRequest -Uri $TargetURI -AccessToken $Connection.AccessToken -RequestMethod POST -UseBasicParsing $Connection.UseBasicParsing -ExpectingNoReply
            $DeleteRequest.AddBody("cluster_id",$ClusterID)
            $DeleteRequest.Submit() | Out-Null
            $ClusterObject = Get-AzureDatabricksCluster -Connection $Connection -ClusterID $ClusterID
            $ClusterObject
        } else {
            throw ("Cluster not found")
        }
    }
}