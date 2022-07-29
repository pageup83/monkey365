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


Function Get-MonkeyAADRMStatusInfo{
    <#
        .SYNOPSIS
		Plugin to get information about AADRM status

        .DESCRIPTION
		Plugin to get information about AADRM status

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAADRMStatusInfo
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
        #Get Access Token from AADRM
        $access_token = $O365Object.auth_tokens.AADRM
        #Get AADRM Url
        $url = $O365Object.Environment.aadrm_service_locator
        if($null -ne $access_token){
            #Set Authorization Header
            $AuthHeader = ("MSOID {0}" -f $access_token.AccessToken)
            $requestHeader = @{"Authorization" = $AuthHeader}
        }
        #Create AADRM object
        $aadrm_feature_status = New-Object -TypeName PSCustomObject
    }
    Process{
        if($requestHeader -and $url){
            $msg = @{
                MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Office 365 Rights Management: Status", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $InformationAction;
                Tags = @('AADRMStatus');
            }
            Write-Information @msg
            $url = ("{0}/FunctionalState" -f $url)
            $params = @{
                Url = $url;
                Method = 'Get';
                Content_Type = 'application/json; charset=utf-8';
                Headers = $requestHeader;
                disableSSLVerification = $true;
            }
            #call AADRM endpoint
            $AADRM_Status = Invoke-UrlRequest @params
            if($AADRM_Status -eq 1){
                $aadrm_feature_status | Add-Member -type NoteProperty -name status -value "Enabled"
            }
            else{
                $aadrm_feature_status | Add-Member -type NoteProperty -name status -value "Disabled"
            }
        }
    }
    End{
        if($aadrm_feature_status){
            $aadrm_feature_status.PSObject.TypeNames.Insert(0,'Monkey365.AADRM.Status')
            [pscustomobject]$obj = @{
                Data = $aadrm_feature_status
            }
            $returnData.o365_aadrm_status = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Office 365 Rights Management: Status", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AADRMStatusEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
