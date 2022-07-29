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


Function Get-MonkeyEXOCASMailbox{
    <#
        .SYNOPSIS
		Plugin to get information about mailboxes in Exchange Online

        .DESCRIPTION
		Plugin to get information about mailboxes in Exchange Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyEXOCASMailbox
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
        #Getting environment
        $Environment = $O365Object.Environment
        #Get EXO authentication
        $exo_auth = $O365Object.auth_tokens.ExchangeOnline
        $cas_mailBoxes = $null;
    }
    Process{
        if($null -ne $exo_auth){
            $msg = @{
                MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Exchange Online CAS (Client Access Settings) mailboxes", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $InformationAction;
                Tags = @('ExoCASMailboxesInfo');
            }
            Write-Information @msg
            #Get Mailboxes
            $param = @{
                Authentication = $exo_auth;
                Environment = $Environment;
                ObjectType = "CasMailbox";
                extraParameters = "PropertySet=All";
            }
            $cas_mailBoxes = Get-PSExoAdminApiObject @param
        }
    }
    End{
        if($cas_mailBoxes){
            $cas_mailBoxes.PSObject.TypeNames.Insert(0,'Monkey365.ExchangeOnline.CASMailboxes')
            [pscustomobject]$obj = @{
                Data = $cas_mailBoxes
            }
            $returnData.o365_exo_cas_mailboxes = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Exchange Online CAS (Client Access Settings) mailboxes", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('ExoCASMailboxesEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
