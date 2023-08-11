﻿# Monkey365 - the PowerShell Cloud Security Tool for Azure and Microsoft 365 (copyright 2022) by Juan Garrido
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[CmdletBinding()]
param ()
$isO365Object = Get-Variable -Name O365Object -ErrorAction Ignore
if($null -ne $isO365Object){
    #Set Monkey365 current location
    Set-Location -Path $O365Object.InitialPath;
    #Import Localized data
    $LocalizedDataParams = $O365Object.LocalizedDataParams
    if($null -ne $LocalizedDataParams){
        Import-LocalizedData @LocalizedDataParams;
    }
    #Start Watcher
    <#
    if($null -ne (Get-Command -Name "Watch-AccessToken" -ErrorAction ignore)){
        Watch-AccessToken -Timer $O365Object.Timer
    }
    #>
    #set the default connection limit
    [System.Net.ServicePointManager]::DefaultConnectionLimit = 1024;
    [System.Net.ServicePointManager]::MaxServicePoints = 1000;
}


