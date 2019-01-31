## Welcome to the PSAzure-Databricks project!

PSAzureDatabricks is an open source PowerShell module designed to make automating and scripting certain tasks within Azure Databricks easier. There are commands to support your configuration of Databricks clusters, code and content, and even Databricks jobs.

## Requirements
* PowerShell v5 and above, including PSCore 6!
* Cross-platform (Windows, Mac, and Linux)

## Getting Started

There's two ways to get and use this module. The first is to pull down the current pubished version on the PowerShell Gallery, which you can find here: https://www.powershellgallery.com/packages/PSAzureDatabricks

And to install it, just use:
```powershell
Install-Module -Name PSAzureDatabricks
```

Or if you want to download the source, just clone the repo and install it manually (see here for details: https://docs.microsoft.com/en-us/powershell/developer/module/installing-a-powershell-module

#### Setting up a connection to Databricks

Each of the functions in this module requires you to have a defined connection object to your instance of Azure Databricks. We've created a base function that returns an object that can be used for all other functions in this module that contains information about your base Databricks URL, Access Token and SSL and TLS settings. Once you have the module loaded, you'll need to create a conneciton object.

Example:
```powershell
Import-Module PSAzureDatabricks
$Connection = New-AzureDatabricksConnection -BaseURI https://eastus2.azuredatabricks.net -AccessToken x
```
## Some Usage Examples

Once you have your connection object defined, you can start using some of the included functions. You can check out each function inside the 'public' folder in this repository, or if you want to jump right in, here's some common usage examples

### Cluster Management

Get information about defined Azure Databricks clusters: 
```powershell
$ClusterObject = Get-AzureDatabricksCluster -Connection $Connection
```
Install a new library on an existing cluster:
```powershell
$hashtable = @{
    'pypi' = 'simplejson=3.8.0'    
}
Install-AzureDatabricksClusterLibrary -Connection $Connection -ClusterName "Drews Cluster"
-Libraries $hashtable
```

### Deploying (and backing up) Notebook Code
Export a workspace's content to a local archive:
```powershell
Export-AzureDatabricksContent -Connection $Connection -Path "/SomeDirectory" -ToFile Archive.zip
```
Note: the output of this function is a compressed .zip archive that represents the contents of the folder you want to back up. You should be able to open the files with any archive explorer tool (including your OS).

Deploy an archive to a target directory on a Databricks workspace (and backup any existing content to an archive location):
```powershell
Deploy-AzureDatabricksNotebooks -SourceConnection $AzureDatabricksConnection -SourcePath "/SomeDirectory" 
-DestinationConnection $AzureDatabricksConnection -DestinationPath "/NewDirectory" 
-ArchiveConnection $ArchiveConnection -ArchivePath "/SomeArchive"
```
### Starting, stopping, and monitoring Databricks Jobs
Get all databricks job definitions:
```powershell
Get-AzureDatabricksJob -Connection $Connection
```

Start a databricks job:
```powershell
Start-AzureDatabricksJob -Connection $Connection -JobID 1
```

Get all databricks job runs history:
```powershell
Get-AzureDatabricksJobRun -Connection $Connection
```

Stop a databricks job:
```powershell
Stop-AzureDatabricksJob -Connection $Connection -JobID 1
```
## We want your help!
Got a good idea for a new function for Azure Databricks? Want to improve what's already here by extending an existing function. Find a bug? Go ahead and throw an issue on the tracker, or better yet, submit a PR!

## License Information
MIT License

Copyright 2019 IGS

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
