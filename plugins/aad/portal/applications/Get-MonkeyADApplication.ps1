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



Function Get-MonkeyADApplication{
    <#
        .SYNOPSIS
		Plugin to get azure apps from Azure AD

        .DESCRIPTION
		Plugin to get azure apps from Azure AD

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyADApplication
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
        $AADConfig = $O365Object.internal_config.azuread
        #Get Environment
        $Environment = $O365Object.Environment
        #Get Azure Active Directory Auth
        $AADAuth = $O365Object.auth_tokens.Graph
        $all_role_assignments = @()
        $all_apps = @()
        $user_consent_apps = @()
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Applications", $O365Object.TenantID);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureGraphApplications');
        }
        Write-Information @msg
        #Get applications
        $params = @{
            Authentication = $AADAuth;
            ObjectType = "applications";
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "GET";
            APIVersion = $AADConfig.api_version;
        }
        $all_applications = Get-MonkeyGraphObject @params
        if ($all_applications){
            $msg = @{
                MessageData = ($message.MonkeyResponseCountMessage -f $all_applications.Count);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $InformationAction;
                Tags = @('AzureGraphApplicationsCount');
            }
            Write-Information @msg
            #Get app owners, role assignments, etc..
            foreach($app in $all_applications){
                #working with Key credential expiration date
                if($app.keyCredentials){
                    $i = 0
                    for($i=0; $i -le $app.keyCredentials.Count;$i++){
                        if($app.keyCredentials[$i].endDate){
                            $endDate = Get-Date $app.keyCredentials[$i].endDate
                            $timeSpan = New-TimeSpan -Start (Get-Date) -End $endDate
                            if($timeSpan){
                            $app.keyCredentials[$i] | Add-Member -type NoteProperty -name expireInDays -value $timeSpan.Days
                            }
                        }
                        $i+=1
                    }
                }
                #working with password credential expiration date
                if($app.passwordCredentials){
                    $i = 0
                    for($i=0; $i -le $app.passwordCredentials.Count;$i++){
                        if($app.passwordCredentials[$i].endDate){
                            $endDate = Get-Date $app.passwordCredentials[$i].endDate
                            $timeSpan = New-TimeSpan -Start (Get-Date) -End $endDate
                            if($timeSpan){
                                $app.passwordCredentials[$i] | Add-Member -type NoteProperty -name expireInDays -value $timeSpan.Days
                            }
                        }
                        $i+=1
                    }
                }
                $objectType = ("applications('{0}')/owners" -f $app.objectId)
                $params = @{
                    Authentication = $AADAuth;
                    ObjectType = $objectType;
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                    APIVersion = $AADConfig.api_version;
                }
                $owners = Get-MonkeyGraphObject @params
                if($owners){
                    $app | Add-Member -type NoteProperty -name Owners -value $owners
                }
                else{
                    $app | Add-Member -type NoteProperty -name Owners -value $null
                }
                #Get Role Assignments
                $objectType = ("servicePrincipalsByAppId/{0}/appRoleAssignedTo" -f $app.appId)
                $params = @{
                    Authentication = $AADAuth;
                    ObjectType = $objectType;
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                    APIVersion = $AADConfig.api_version;
                }
                $app_assigned_roles = Get-MonkeyGraphObject @params
                if($null -ne $app_assigned_roles){
                    #Get roles
                    foreach($app_role in $app_assigned_roles){
                        if($app_role.resourceId){
                            $objectType = ("servicePrincipals/{0}" -f $app_role.resourceId)
                            #Get servicePrincipals
                            $params = @{
                                Authentication = $AADAuth;
                                ObjectType = $objectType;
                                Environment = $Environment;
                                ContentType = 'application/json';
                                Method = "GET";
                                APIVersion = $AADConfig.api_version;
                            }
                            $raw_app = Get-MonkeyGraphObject @params
                            if($null -ne $raw_app){
                                $all_apps+=$raw_app
                                #Get permission ID
                                if($raw_app.appRoles){
                                    $permission = $raw_app.appRoles | Where-Object {$_.id -eq $app_role.id}
                                }
                                else{
                                    $permission = $null
                                }
                                #Check if admin consented
                                if($raw_app.oauth2Permissions -and $null -ne $permission){
                                    $app_role_perm = $raw_app.oauth2Permissions | Where-Object {$_.value -eq $permission.value}
                                }
                                else{
                                    $app_role_perm = $null
                                }
                                #Check for detailed description
                                if($null -ne $permission){
                                    $new_app_role = [PSCustomObject]@{
                                        ClientDisplayName = $app_role.principalDisplayName;
                                        ResourceDisplayName = $app_role.resourceDisplayName;
                                        ClientPrincipalId = $app_role.principalId;
                                        ResourceObjectId = $app_role.resourceId;
                                        RoleId = $app_role.id;
                                        RoleDisplayName = $permission.displayName;
                                        RoleDescription = $permission.description;
                                        Permission = $permission.value;
                                        PermissionId = $permission.id;
                                        isEnabled = $permission.isEnabled;
                                        PermissionTypes = $permission.allowedMemberTypes;
                                    }
                                    if($null -ne $permission.origin){
                                        $new_app_role | Add-Member -type NoteProperty -name PermissionOrigin -value $permission.origin.ToString()
                                    }
                                    else{
                                        $new_app_role | Add-Member -type NoteProperty -name PermissionOrigin -value $null
                                    }
                                    if($null -ne $app_role_perm){
                                        $new_app_role | Add-Member -type NoteProperty -name AdminConsentDescription -value $app_role_perm.adminConsentDescription
                                        $new_app_role | Add-Member -type NoteProperty -name AdminConsentDisplayName -value $app_role_perm.adminConsentDisplayName
                                        $new_app_role | Add-Member -type NoteProperty -name ConsentId -value $app_role_perm.id
                                        $new_app_role | Add-Member -type NoteProperty -name ConsentType -value $app_role_perm.type
                                        $new_app_role | Add-Member -type NoteProperty -name ConsentEnabled -value $app_role_perm.isEnabled
                                        $new_app_role | Add-Member -type NoteProperty -name UserConsentDescription -value $app_role_perm.userConsentDescription
                                        $new_app_role | Add-Member -type NoteProperty -name UserConsentDisplayName -value $app_role_perm.userConsentDisplayName
                                        $new_app_role | Add-Member -type NoteProperty -name ConsentValue -value $app_role_perm.value
                                    }
                                    else{
                                        $new_app_role | Add-Member -type NoteProperty -name AdminConsentDescription -value $permission.description
                                        $new_app_role | Add-Member -type NoteProperty -name AdminConsentDisplayName -value $permission.displayName
                                        $new_app_role | Add-Member -type NoteProperty -name ConsentId -value $null
                                        $new_app_role | Add-Member -type NoteProperty -name ConsentType -value "Admin"
                                        $new_app_role | Add-Member -type NoteProperty -name ConsentEnabled -value $true
                                        $new_app_role | Add-Member -type NoteProperty -name UserConsentDescription -value $permission.description
                                        $new_app_role | Add-Member -type NoteProperty -name UserConsentDisplayName -value $permission.displayName
                                        $new_app_role | Add-Member -type NoteProperty -name ConsentValue -value $permission.value
                                    }
                                    #Add to Array
                                    $all_role_assignments+=$new_app_role
                                }
                            }
                        }
                    }
                    #Add assigned Roles to app
                    $app | Add-Member -type NoteProperty -name assigned_roles -value $all_role_assignments
                }
            }
        }
        #Get delegated permissions
        $params = @{
            Authentication = $AADAuth;
            ObjectType = "oauth2PermissionGrants";
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "GET";
            APIVersion = $AADConfig.api_version;
        }
        $oauth_grants = Get-MonkeyGraphObject @params
        if($oauth_grants){
            foreach($grant in $oauth_grants){
                if($grant.PrincipalId){
                    $object = Get-MonkeyADObjectByObjectId -ObjectId $grant.PrincipalId
                }
                else{
                    $object = $null
                }
                $raw_app = $all_role_assignments | Where-Object {$_.ClientPrincipalId -eq $grant.clientId} | Select-Object -First 1
                if($null -ne $raw_app){
                    if($grant.Scope){
                        foreach($scope in $grant.Scope.Split(" ")){
                            $grantDetails =  [PSCustomObject]@{
                                "PermissionType" = "Delegated"
                                "ClientObjectId" = $grant.ClientId
                                "ClientDisplayName" = $raw_app.ClientDisplayName
                                "ResourceDisplayName" = $raw_app.ResourceDisplayName
                                "ResourceObjectId" = $grant.ResourceId
                                "Permission" = $scope
                                "ConsentType" = $grant.ConsentType
                                "PrincipalObjectId" = if($grant.PrincipalId){$grant.PrincipalId}else{$null};
                                "PrincipalDisplayName" = if($null -ne $object){$object.displayName}else{$null};
                                "PrincipalUserPrincipalName" = if($null -ne $object){$object.userPrincipalName}else{$null};
                            }
                            #Add to Array
                            $user_consent_apps+=$grantDetails
                        }
                    }
                }
                else{
                    #Get app and resource
                    $objectType = ("servicePrincipals/{0}" -f $grant.clientId)
                    $params = @{
                        Authentication = $AADAuth;
                        ObjectType = $objectType;
                        Environment = $Environment;
                        ContentType = 'application/json';
                        Method = "GET";
                        APIVersion = $AADConfig.api_version;
                    }
                    $raw_app = Get-MonkeyGraphObject @params
                    $objectType = ("servicePrincipals/{0}" -f $grant.resourceId)
                    $params = @{
                        Authentication = $AADAuth;
                        ObjectType = $objectType;
                        Environment = $Environment;
                        ContentType = 'application/json';
                        Method = "GET";
                        APIVersion = $AADConfig.api_version;
                    }
                    $resource_app = Get-MonkeyGraphObject @params
                    if($raw_app -and $resource_app -and $grant.Scope){
                        foreach($scope in $grant.Scope.Split(" ")){
                            $grantDetails =  [PSCustomObject]@{
                                "PermissionType" = "Delegated"
                                "ClientObjectId" = $grant.ClientId
                                "ClientDisplayName" = $raw_app.appDisplayName
                                "ResourceDisplayName" = $resource_app.appDisplayName
                                "ResourceObjectId" = $grant.ResourceId
                                "Permission" = $scope
                                "ConsentType" = $grant.ConsentType
                                "PrincipalObjectId" = if($grant.PrincipalId){$grant.PrincipalId}else{$null};
                                "PrincipalDisplayName" = if($null -ne $object){$object.displayName}else{$null};
                                "PrincipalUserPrincipalName" = if($null -ne $object){$object.userPrincipalName}else{$null};
                            }
                            #Add to Array
                            $user_consent_apps+=$grantDetails
                        }
                    }
                }
            }
        }
    }
    End{
        if ($all_applications){
            $all_applications.PSObject.TypeNames.Insert(0,'Monkey365.AzureAD.app_registrations')
            [pscustomobject]$obj = @{
                Data = $all_applications
            }
            $returnData.aad_app_registrations = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Applications", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureGraphApplicationsEmptyResponse');
            }
            Write-Warning @msg
        }
        if ($all_role_assignments){
            $all_role_assignments.PSObject.TypeNames.Insert(0,'Monkey365.AzureAD.app_role_assignments')
            [pscustomobject]$obj = @{
                Data = $all_role_assignments
            }
            $returnData.aad_app_role_assignments = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Applications Role Assignments", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureGraphAppRBACEmptyResponse');
            }
            Write-Warning @msg
        }
        #Add user consented apps
        if ($user_consent_apps){
            $user_consent_apps.PSObject.TypeNames.Insert(0,'Monkey365.AzureAD.app.user.consent')
            [pscustomobject]$obj = @{
                Data = $user_consent_apps
            }
            $returnData.aad_user_consented_apps = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "User consented applications", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureGraphAppUserConsentEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
