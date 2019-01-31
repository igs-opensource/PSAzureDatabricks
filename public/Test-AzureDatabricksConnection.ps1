function Test-AzureDatabricksConnection {
    <#
        .SYNOPSIS
            A simple function to test the connectivity to an Azure Databricks instance.
        .DESCRIPTION
            This function will return $True if the defined connection object can successfully connect to an Azure Databricks instance, or
            $False if there's an error.
        .PARAMETER ConnectionObject
            An object that represents an Azure Databricks API connection where you want to stop your job.
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
        [Parameter(Mandatory=$true)] [Object] $ConnectionObject
    )

    begin {
        $TargetURI = $ConnectionObject.BaseURI.AbsoluteUri + "api/2.0/token/list"
    }

    process {
        if ($ConnectionObject.BaseURI.IsAbsoluteUri -eq $False) {
            throw "Connection is not referecing an absolute URI"
        }
        if ($ConnectionObject.BaseURI.Authority.ToUpper() -notlike "*.AZUREDATABRICKS.NET") {
            throw "This command is only intended to be used against Azure Databricks API uris/urls"
        }
        Write-Verbose "Testing connection to $TargetURI..."
        $TestConnection = New-AzureDatabricksRequest -Uri $TargetURI -AccessToken  $ConnectionObject.AccessToken -UseBasicParsing $ConnectionObject.UseBasicParsing
        $Response = $TestConnection.Submit()
        
        if ($Response.TimeStamp) {
            return $true
        } else {
            return $false
        }
    }
}