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


Function Get-MonkeyEXOComplianceTag{
    <#
        .SYNOPSIS
		Plugin to get information about compliance tags from Exchange Online

        .DESCRIPTION
		Plugin to get information about compliance tags from Exchange Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyEXOComplianceTag
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
        [Parameter(Mandatory= $false, HelpMessage="Background Plugin ID")]
        [String]$pluginId
    )
    Begin{
        $compliance_tags = $null;
        $exo_session = Test-EXOConnection -ComplianceCenter
    }
    Process{
        if($null -ne $exo_session){
            $msg = @{
                MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Security and Compliance tags", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $InformationAction;
                Tags = @('SecCompTagsInfo');
            }
            Write-Information @msg
            #Get Compliance tags
            $compliance_tags = Get-ComplianceTag
        }
    }
    End{
        if($compliance_tags){
            $compliance_tags.PSObject.TypeNames.Insert(0,'Monkey365.SecurityCompliance.Tag')
            [pscustomobject]$obj = @{
                Data = $compliance_tags
            }
            $returnData.o365_secomp_compliance_tag = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Security and Compliance tags", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('SecCompTagsEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
