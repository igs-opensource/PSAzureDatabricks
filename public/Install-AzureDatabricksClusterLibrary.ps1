function Install-AzureDatabricksClusterLibrary {
    <#
        .SYNOPSIS
            Installs a client library on an existing defined Azure Databricks cluster.
        .DESCRIPTION
            This function will enable to quickly add libraries to existing Databricks cluster. Currently only supports .egg and pypi files.
        .PARAMETER Connection
            An object that represents an Azure Databricks API connection where you want to copy your content to.
        .PARAMETER ClusterName
            The name of the cluster you want to install the libraries on.
        .PARAMETER Libraries
            A hashtable containing the library type and name of the library you want to add.
        .NOTES
            A sample of the hashtable needed for this function:
            
            $hashtable = @{
                'pypi' = 'simplejson=3.8.0'    
            }

            Each line of your hashtable should be either of type pypi or egg. If egg, specify the path to the egg.

            Author: Drew Furgiuele (@pittfurg), http://www.port1433.com
            Website: https://www.igs.com
            Copyright: (c) 2019 by IGS, licensed under MIT
            License: MIT https://opensource.org/licenses/MIT
        .LINK
            
        .EXAMPLE
            PS C:\> Install-AzureDatabricksClusterLibrary -Connection $Connection -ClusterName "Drews Cluster" -Libraries $Libraries
            Installs the libraries listed in the hashtable variable $Libraries in the cluster "Drews Cluster" on the Databricks instance defined in $Connection
    #>         
    Param (
        [Parameter(Mandatory=$true)] [object] $Connection,
        [Parameter(Mandatory=$true)] [string] $ClusterName,
        [Parameter(Mandatory=$true)] [hashtable] $Libraries
    )
    
    begin {
        $TargetURI = $Connection.BaseURI.AbsoluteUri + "api/2.0/libraries/install"
    }

    process {
        $Databricks = New-AzureDatabricksRequest -Uri $TargetURI -AccessToken $Connection.AccessToken -RequestMethod POST  -UseBasicParsing $Connection.UseBasicParsing -ExpectingNoReply

        $ClusterID = (Get-AzureDatabricksCluster -Connection $Connection | Where-Object {$_.Name -eq $ClusterName}).ClusterID
        if (!$clusterID) {
            throw "Unable to find cluster!"
        }
        $Databricks.AddBody("cluster_id",$ClusterID)

        $NewLibraries = @()
        ForEach ($l in $Libraries.Keys) {
            Write-Verbose "Parsing library definition"
            switch ($l) {
                "egg" {
                    Write-Verbose "Parsing egg..."
                    $Library = [PSCustomObject] @{
                        egg = $Libraries[$l]
                    }
                }
                "pypi" {
                    $SubLibrary = [PSCustomObject]  @{
                        package = $Libraries[$l]
                    }
                    $Library = [PSCustomObject]  @{
                        pypi = $SubLibrary
                    }
                }
            }
            $NewLibraries += $Library
        }
        $Databricks.AddBody("libraries",$NewLibraries)
        $Databricks.Submit() | Out-Null

        Write-Verbose "Libraries installed!"
        Get-AzureDatabricksCluster -Connection $Connection -ClusterID $ClusterID
    }
}