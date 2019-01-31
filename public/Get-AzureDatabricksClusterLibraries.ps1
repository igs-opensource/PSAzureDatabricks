function Get-AzureDatabricksClusterLibraries {
    <#
        .SYNOPSIS
            Returns an object detailing all configured libraries for a defined Azure Databricks cluster.
        .DESCRIPTION
            Returns an object detailing all configured libraries for a defined Azure Databricks cluster. This will list all types of libraries and thier current status as well.
        .PARAMETER Connection
            An object that represents an Azure Databricks API connection where you want to get your clusters from.
        .PARAMETER ClusterID
            The cluster ID of the specific databricks cluster you want to return library information about.
        .NOTES
            Author: Drew Furgiuele (@pittfurg), http://www.port1433.com
            Website: https://www.igs.com
            Copyright: (c) 2019 by IGS, licensed under MIT
            License: MIT https://opensource.org/licenses/MIT
        .LINK
            
        .EXAMPLE
            PS C:\> Get-AzureDatabricksClusterLibraries -Connection $Connection $ClusterID 1
            Gets the configuration and status of all libraries for cluster ID number one the defined Azure Databricks connection $Connection
    
        #>        
    Param (
        [Parameter(Mandatory=$true)] [object] $Connection,
        [Parameter(Mandatory=$true)] [string] $ClusterID
    )
    
    begin {
        $TargetURI = $Connection.BaseURI.AbsoluteUri + "api/2.0/libraries/cluster-status?cluster_id=$ClusterID"
    }

    process {
        $Databricks = New-AzureDatabricksRequest -Uri $TargetURI -AccessToken $Connection.AccessToken -RequestMethod GET  -UseBasicParsing $Connection.UseBasicParsing
        $ClusterLibraryStatus = $Databricks.Submit()

        $ClusterLibraryStatus
    }
}