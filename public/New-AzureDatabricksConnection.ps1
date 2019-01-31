function New-AzureDatabricksConnection {
<#
        .SYNOPSIS
            Extablishes a connection to an Azure Databricks instance via a predefined access token and base API URL.
        .DESCRIPTION
            This function returns a connection object that is required for all other functions in this module, and this function should be the first thing you
            call to return a connection object. Supports PS5 and PSCore 6, and different TLS configurations for HTTPS.
        .PARAMETER BaseUI
            The base URI of your Azure Databricks instance (e.g. https://eastus2.azuredatabricks.net)
        .PARAMETER AccessToken
            Your Azure Databricks access token. You'll need one of these before you start. Details here: https://docs.databricks.com/api/latest/authentication.html#generate-a-token
        .PARAMETER Protocol
            If needed you can specify a TLS or SSL protocol, or "All." Use this if you receive certificate and/or HTTPS errors with your current security settings.
        .PARAMETER UseBasicParsing
            A pass-thru parameter for the underlying Invoke-WebRequest functions these functions rely on. Use if needed.
        .NOTES
            Author: Drew Furgiuele (@pittfurg), http://www.port1433.com
            Website: https://www.igs.com
            Copyright: (c) 2019 by IGS, licensed under MIT
            License: MIT https://opensource.org/licenses/MIT
        .LINK
            
        .EXAMPLE
            PS C:\> $Connection = New-AzureDatabricksConnection -BaseURI https://eastus2.azuredatabricks.net -AccessToken x
            Creates a new connection object in $Connection that contains your base URI and API key for all other functions in the module.
    #>    
    Param (
        [Parameter(Mandatory=$true)] [Uri] $BaseURI,
        [Parameter(Mandatory=$true)] [string] $AccessToken,
        [Parameter(Mandatory=$false)] [ValidateSet('SSL3','TLS','TLS11','TLS12','All')] [string] $Protocol,
        [Parameter(Mandatory=$false)] [switch] $UseBasicParsing
    )

    begin {
        if ($Protocol) {
            if ($Protocol -eq "All") {
                $UseProtocols = 'SSL3,TLS,TLS11,TLS12'
            } else {
                $UseProtocols = $Protocol
            }
            $SecurityMethod = [System.Net.SecurityProtocolType]"$UseProtocols"
            [System.Net.ServicePointManager]::SecurityProtocol = $SecurityMethod
        }
    }

    process {
        $ConnectionObject = New-Object AzureDataBricksConnection($BaseURI, $AccessToken, $UseProtocols, $UseBasicParsing)
        $ConnectionObject.UseBasicParsing
        if (Test-AzureDatabricksConnection $ConnectionObject) {
            return $ConnectionObject
        } else {
            return $null
        }
    }
}