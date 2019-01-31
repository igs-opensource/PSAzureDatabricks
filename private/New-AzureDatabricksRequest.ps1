function New-AzureDatabricksRequest {
    <#
        .SYNOPSIS
            The main helper function that is responsible for creating the base connection object that opens and communicates with the Azure Databricks API.
        .DESCRIPTION
            This helper function creates a basic connection object that contains all the required information for a given specified API request. All other functions
            have a dependancy on this function. This function should only be called from within other functions.
        .PARAMETER Uri
            The base URI of the API path being called
        .PARAMETER AccessToken
            The required access token that has been created to allow access to the Databricks API (see: https://docs.databricks.com/api/latest/authentication.html)
        .PARAMETER RequestMethod
            What kind of API call to make (https GET or POST)
        .PARAMETER ExpectingNoReply
            Should the response from the API be parsed or ignored? Some API calls return empty JSON objects that cannot be parsed like most other responses. This optional switch
            tells our request that we should "ignore" the response from the API
        .PARAMETER UseBasicParsing
            How should we handle the response from the API (robust or basic)?
        .NOTES
            Author: Drew Furgiuele (@pittfurg), http://www.port1433.com
            Website: https://www.igs.com
            Copyright: (c) 2019 by IGS, licensed under MIT
            License: MIT https://opensource.org/licenses/MIT
        .LINK
            
        .EXAMPLE
    #>    
    Param (
        [Parameter(Mandatory=$true)] [uri] $Uri,
        [Parameter(Mandatory=$true)] [string] $AccessToken,
        [Parameter(Mandatory=$false)] [ValidateSet("GET","POST")] [string] $RequestMethod = "GET",
        [Parameter(Mandatory=$false)] [switch] $ExpectingNoReply,
        [Parameter(Mandatory=$false)] [bool] $UseBasicParsing = $False
    )        

    process {
        $DatabricksRequestObject = New-Object DatabricksRequestObject
        $DatabricksRequestObject.RequestURI = $Uri
        $DatabricksRequestObject.RequestMethod = $RequestMethod
        if ($UseBasicParsing -eq $True) {
            $DatabricksRequestObject.UseBasicParsing = $True
        }
        $DatabricksRequestObject.AddHeader("Authorization","Bearer $AccessToken")
        if ($ExpectingNoReply) {
            $DatabricksRequestObject.IgnoreResponse = $True
        }
        $DatabricksRequestObject
    }
}