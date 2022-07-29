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

Function Remove-MonkeyPsSession {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Remove-MonkeyPsSession
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact="Medium")]
    Param (
        [Parameter(Mandatory = $false, HelpMessage = 'Force without message')]
        [switch]$Force
    )
    Begin{
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
    }
    Process{
        if ($Force -or $PSCmdlet.ShouldProcess("ShouldProcess?")){
            $ConfirmPreference = 'None'
            foreach($raw_sess in $o365_sessions.GetEnumerator()){
                if($null -ne $raw_sess.Value -and $raw_sess.Value -is [System.Management.Automation.Runspaces.PSSession]){
                    $sess = $raw_sess.Value
                    $msg = @{
                        MessageData = ($message.ClosingRemoteSession -f $sess.ComputerName);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'debug';
                        Tags = @('RemoteSessionClosingMessage');
                    }
                    Write-Debug @msg
                    Remove-PSSession -Session $sess
                }
            }
        }
    }
    End{
        #Clear var
        $o365_sessions.Clear()
    }
}
