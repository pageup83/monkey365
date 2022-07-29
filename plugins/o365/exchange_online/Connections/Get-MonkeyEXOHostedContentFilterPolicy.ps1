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


Function Get-MonkeyEXOHostedContentFilterPolicy{
    <#
        .SYNOPSIS
		Plugin to get information about hosted content filter policy in Exchange Online

        .DESCRIPTION
		Plugin to get information about hosted content filter policy in Exchange Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyEXOHostedContentFilterPolicy
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
        $hosted_content_filter = $null
        #Check if already connected to Exchange
        $exo_session = Test-EXOConnection
        #Get Tenant info
        $tenant_info = $O365Object.Tenant
        #Get available domains for organisation
        $org_domains = $tenant_info.Domains | Select-Object -ExpandProperty id
    }
    Process{
        if($exo_session){
            $msg = @{
                MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Exchange Online Hosted content filter policy", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $InformationAction;
                Tags = @('ExoHostedContentInfo');
            }
            Write-Information @msg
            $hosted_content_filter = Get-HostedContentFilterInfo
            if($null -ne $hosted_content_filter){
                foreach($content_filter in $hosted_content_filter.GetEnumerator()){
                    $AllowedSenderDomains = $content_filter.Policy.AllowedSenderDomains
                    if($AllowedSenderDomains.Count -gt 0){
                        $all_domains = $AllowedSenderDomains | Select-Object -ExpandProperty Domain
                        $params = @{
                            ReferenceObject = $org_domains;
                            DifferenceObject = $all_domains;
                            IncludeEqual= $true;
                            ExcludeDifferent = $true;
                        }
                        $org_whitelisted = Compare-Object @params
                        #Check if own domain is already whitelisted
                        if($org_whitelisted){
                            $content_filter | Add-Member -type NoteProperty -name IsCompanyWhiteListed -value $true
                        }
                        else{
                            $content_filter | Add-Member -type NoteProperty -name IsCompanyWhiteListed -value $false
                        }
                    }
                    else{
                        $content_filter | Add-Member -type NoteProperty -name IsCompanyWhiteListed -value $false
                    }
                }
            }
        }
    }
    End{
        if($null -ne $hosted_content_filter){
            $hosted_content_filter.PSObject.TypeNames.Insert(0,'Monkey365.ExchangeOnline.HostedContentFilterPolicy')
            [pscustomobject]$obj = @{
                Data = $hosted_content_filter
            }
            $returnData.o365_exo_content_filter_info = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Exchange Online Hosted content filter policy", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('ExoHostedContentEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
