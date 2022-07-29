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


Function Get-MonkeyEXOAdminAuditLogConfig{
    <#
        .SYNOPSIS
		Plugin to get information about audit log config from Exchange Online

        .DESCRIPTION
		Plugin to get information about audit log config from Exchange Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyEXOAdminAuditLogConfig
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
        $O365_logConfig = $null
        #Check if already connected to Exchange Online
        $exo_session = Test-EXOConnection -ComplianceCenter
    }
    Process{
        if($null -ne $exo_session){
            $msg = @{
                MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Security and Compliance Admin audit log config", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $InformationAction;
                Tags = @('SecCompLogConfigInfo');
            }
            Write-Information @msg
            #Get O365 log config
            $O365_logConfig = Get-AdminAuditLogConfig
        }
    }
    End{
        if($O365_logConfig){
            $O365_logConfig.PSObject.TypeNames.Insert(0,'Monkey365.SecurityCompliance.logConfig')
            [pscustomobject]$obj = @{
                Data = $O365_logConfig
            }
            $returnData.o365_secomp_log_config = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Security and Compliance Admin audit log config", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('SecCompLogConfigEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
