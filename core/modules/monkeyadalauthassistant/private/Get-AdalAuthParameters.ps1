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

Function Get-AdalAuthParameters{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-AdalAuthParameters
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
     # psboundparameters
     [Parameter(Mandatory = $false, HelpMessage = 'Parameters')]
     [object] $parameters
    )
    #Skip any parameters
    $skip=@(
        'Admin','rootSite','Endpoint', 'oneDrive'
    )
    $body = @{}
    foreach ($param in $parameters.GetEnumerator()){
        if ($param.key -in $skip) { continue }
        $body.add($param.Key, $param.Value)
    }
    $body
}
