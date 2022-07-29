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


Function Get-MonkeyAzSecurityStatusInfo{
    <#
        .SYNOPSIS
		Plugin to get information about Security Statuses from Azure

        .DESCRIPTION
		Plugin to get information about Security Statuses from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzSecurityStatusInfo
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
        #Import Localized data
        $LocalizedDataParams = $O365Object.LocalizedDataParams
        Import-LocalizedData @LocalizedDataParams;
        #Get Environment
        $Environment = $O365Object.Environment
        #Get Azure RM Auth
        $rm_auth = $O365Object.auth_tokens.ResourceManager
        #Get config
        $AzureSecStatus = $O365Object.internal_config.resourceManager | Where-Object {$_.name -eq "azureSecurityStatuses"} | Select-Object -ExpandProperty resource
        #Get resource groups
        $resource_groups = $O365Object.ResourceGroups
        #set array
        $security_statuses = @()
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure Security Status", $O365Object.current_subscription.DisplayName);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureSecStatusInfo');
        }
        Write-Information @msg
        #Get all Security Status
        $params = @{
            Authentication = $rm_auth;
            Provider = $AzureSecStatus.provider;
            ObjectType = "securityStatuses";
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "GET";
            APIVersion = $AzureSecStatus.api_version;
        }
        $AllStatus = Get-MonkeyRMObject @params
        #iterate over all resource_groups
        foreach($resource_group in $resource_groups){
            $matched = $AllStatus | Where-Object {$_.id -like ("{0}*" -f $resource_group.id)}
            if($matched){
                #Add to array
                $security_statuses+=$matched
            }
        }

    }
    End{
        if($security_statuses){
            $security_statuses.PSObject.TypeNames.Insert(0,'Monkey365.Azure.SecurityStatus')
            [pscustomobject]$obj = @{
                Data = $security_statuses
            }
            $returnData.az_security_status = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Security Status", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureKeySecStatusEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
