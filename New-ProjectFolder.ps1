<#

.SYNOPSIS

Creates a storebox portal.



.DESCRIPTION

Creates a storebox portal.

$acl = @(); 
$acl += New-AclEntry -Name EdgarSchnittenfittich -Type localUser -Permission ReadWrite;
$acl += New-AclEntry -Name some-user -Type localUser -Permission ReadOnly;
$acl += New-AclEntry -Name ProjectsReadWrite -Type localGroup -Permission ReadWrite;
$acl += New-AclEntry -Name ProjectsReadOnly -Type localGroup -Permission ReadOnly;
New-ProjectFolder -Name EdgarSchnittenfittichProject -Owner EdgarSchnittenfittich -Description "this is a description" -Permissions $acl



.EXAMPLE

Creates a storebox portal.

$acl = @(); 
$acl += New-AclEntry -Name EdgarSchnittenfittich -Type localUser -Permission ReadWrite;
$acl += New-AclEntry -Name some-user -Type localUser -Permission ReadOnly;
$acl += New-AclEntry -Name ProjectsReadWrite -Type localGroup -Permission ReadWrite;
$acl += New-AclEntry -Name ProjectsReadOnly -Type localGroup -Permission ReadOnly;
New-ProjectFolder -Name EdgarSchnittenfittichProject -Owner EdgarSchnittenfittich -Description "this is a description" -Permissions $acl

#>
function New-ProjectFolder {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium",
	HelpURI='http://dfch.biz/biz/dfch/PS/Storebox/Api/New-ProjectFolder/'
)]
[OutputType([string])]
Param (
	[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Mandatory = $true, Position = 0, ParameterSetName = 'r')]
	$InputObject
    ,
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'p')]
	[string] $Name
    ,
	[Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'p')]
	[string] $Owner
    ,
	[Parameter(Mandatory = $false, Position = 2, ParameterSetName = 'p')]
	[string] $Description = ''
    ,
	[Parameter(Mandatory = $false, Position = 3, ParameterSetName = 'p')]
	[string] $Group = ''
    ,
	[Parameter(Mandatory = $false, ParameterSetName = 'p')]
	[switch] $ShowUnderRoot = $false
    ,
	[Parameter(Mandatory = $false, Position = 4, ParameterSetName = 'p')]
    [Alias('acl')]
	[hashtable[]] $Permissions = $null
    ,
	[Parameter(Mandatory = $false)]
	[switch] $Validate = $false
)
BEGIN {
$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL.") -fac 1;

$oProjectTemplate = Get-ObjTemplate ProjectCreateParams|ConvertFrom-Obj;
$r = Invoke-Command defaultGroup;
$dbSlim = ("<obj class='user-defined' ><att id='defaultGroup' >{0}</att></obj>" -f $r) | ConvertFrom-Obj;
$oAclRuleTemplate = Get-DefaultsObj ProjectACLRule | ConvertFrom-Obj;

} # BEGIN

PROCESS {
[boolean] $fReturn = $false;
$OutputParameter = $null;

try {
	# Parameter validation
	# N/A
    $obj = $null;

    $oProjectFolder = $oProjectTemplate.Clone();
    $r = @{};
    if($PSCmdlet.ParameterSetName -eq 'p') {
        $oProjectFolder.name = $Name;
        $oProjectFolder.description = $Description;
		if($ShowUnderRoot) { $oProjectFolder.ShowUnderRoot = 'true'; } else { $oProjectFolder.ShowUnderRoot = 'false'; }
        $r.Owner = $Owner;
        $r.Group = $Group;
        $r.Permissions = $Permissions;
    } else {
        $oProjectFolder.Name = $InputObject.Name;
        $oProjectFolder.Description = $InputObject.Description;
		if($InputObject.ShowUnderRoot) { $oProjectFolder.ShowUnderRoot = 'true'; } else { $oProjectFolder.ShowUnderRoot = 'false'; }
        $r.Owner = $InputObject.Owner;
        $r.Group = $InputObject.Group;
        $r.Permissions = $InputObject.Permissions;
    } # if
    if(!$r.Group) {
        $oProjectFolder.group = $dbSlim.defaultGroup;
    } else {
        $oProjectFolder.group = $r.Group;
    } # if
    $oUser = Invoke-Command ('users/{0}' -f $r.Owner) | ConvertFrom-Obj;
    $oProjectFolder.owner = 'objs/{0}' -f $oUser.uid;
    if(!$r.Permissions) {
        $oProjectFolder.Acl = @();
    } else {
        $aoAclRule = @();
        foreach($a in $r.Permissions) { 
            foreach($acl in $a.GetEnumerator()) { 
                $fReturn = $acl.Name -match '^(?<type>local.+)\\(?<name>.+)$'; 
                if(!$fReturn) {
                    $e = New-CustomErrorRecord -m ("Permissions contains invalid data on 'name' property: '{0}'" -f $acl.Name)-cat InvalidArgument -o $r.Permissions;
                    throw($gotoError);
                } # if
                switch($Matches.type) {
                'localUser' {
                    $oUser = Invoke-Command ('users/{0}' -f $Matches.name) | ConvertFrom-Obj;
                    $uid = $oUser.uid;
                }
                'localGroup' {
                    $oGroup = Invoke-Command ('localGroups/{0}' -f $Matches.name) | ConvertFrom-Obj;
                    $uid = $oGroup.uid;
                }
                default {
                    $e = New-CustomErrorRecord -m ("Permissions contains invalid data on 'name' property: '{0}'" -f $Matches.type)-cat InvalidArgument -o $r.Permissions;
                    throw($gotoError);
                }
                } # switch
                $oAclRule = $oAclRuleTemplate.Clone();
                $oAclRule.permissions = $acl.Value;
                $oAclRule.name = $Matches.name;
                $oAclRule.type = $Matches.type;
                $oAclRule.uid = $uid;
                $aoAclRule += $oAclRule.Clone();
            } # foreach
        } # foreach
        $oProjectFolder.Acl = $aoAclRule;
    } # if

    if($Validate) {
        $oProjectFolderValidate = $oProjectFolder.Clone();
        $oProjectFolderValidate.'#class' = 'PortalProject';
        $Parameters = $oProjectFolderValidate | ConvertTo-Xml;
        $Uri = 'projects';
        $Body = Format-ExtendedMethod -Name 'validate' -Parameters $Parameters;
        $r = Invoke-Command -Method 'POST' -Api $Uri -Body $Body;
        if(![System.Object]::Equals($r, $null)) {
            $e = New-CustomErrorRecord -m ("Validation of adding projectFolder '{0}' FAILED." -f $oProjectFolder.Name) -cat InvalidData -o $Body;
            throw($gotoError);
        } # 
    } # if
    $Parameters = $oProjectFolder | ConvertTo-Xml;
    $Body = Format-ExtendedMethod -Name 'addProject' -Parameters $Parameters;
	if(!$PSCmdlet.ShouldProcess($Name)) {
        $fReturn = $true;
        $OutputParameter = $null;
        throw($gotoSuccess);
    } # if
    $Uri = '/'
    $r = Invoke-Command -Method 'POST' -Api $Uri -Body $Body;
    if([System.Object]::Equals($r, $null)) {
        $e = New-CustomErrorRecord -m ("Adding projectFolder '{0}' FAILED." -f $oProjectFolder.Name) -cat InvalidData -o $Body;
        throw($gotoError);
    } # 
    $OutputParameter = ("<obj class='#uri'><att id='#uri'>{0}</att></obj>" -f $r) | ConvertFrom-Obj;
    $fReturn = $true;
			
} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} elseif($gotoNotFound -eq $_.Exception.Message) {
		$fReturn = $false;
		$OutputParameter = $null;
	} else {
		[string] $ErrorText = "catch [$($_.FullyQualifiedErrorId)]";
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception.InnerException -is [System.Net.WebException]) {
			Log-Critical $fn "Operation '$Method' '$Api' with UriServer '$UriServer' FAILED [$_].";
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
		    Log-Error $fn $ErrorText -fac 3;
		    if($gotoError -eq $_.Exception.Message) {
			    Log-Error $fn $e.Exception.Message;
			    $PSCmdlet.ThrowTerminatingError($e);
		    } elseif($gotoFailure -ne $_.Exception.Message) { 
			    Write-Verbose ("$fn`n$ErrorText"); 
		    } else {
			    # N/A
		    } # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
} # finally
return $OutputParameter;
} # PROCESS

END {
$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;
} # END

} # New-ProjectFolder
Set-Alias -Name New-Project -Value New-ProjectFolder;
Set-Alias -Name New-Folder -Value New-ProjectFolder;
Export-ModuleMember -Function New-ProjectFolder -Alias New-Project, New-Folder;

<##
 #
 #
 # Copyright 2013-2015 Ronald Rink, d-fens GmbH
 #
 # Licensed under the Apache License, Version 2.0 (the "License");
 # you may not use this file except in compliance with the License.
 # You may obtain a copy of the License at
 #
 # http://www.apache.org/licenses/LICENSE-2.0
 #
 # Unless required by applicable law or agreed to in writing, software
 # distributed under the License is distributed on an "AS IS" BASIS,
 # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 # See the License for the specific language governing permissions and
 # limitations under the License.
 #
 #>


# SIG # Begin signature block
# MIIW3AYJKoZIhvcNAQcCoIIWzTCCFskCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU2kywSGsOM+YrIPEGPylfeWn1
# fzugghGYMIIEFDCCAvygAwIBAgILBAAAAAABL07hUtcwDQYJKoZIhvcNAQEFBQAw
# VzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExEDAOBgNV
# BAsTB1Jvb3QgQ0ExGzAZBgNVBAMTEkdsb2JhbFNpZ24gUm9vdCBDQTAeFw0xMTA0
# MTMxMDAwMDBaFw0yODAxMjgxMjAwMDBaMFIxCzAJBgNVBAYTAkJFMRkwFwYDVQQK
# ExBHbG9iYWxTaWduIG52LXNhMSgwJgYDVQQDEx9HbG9iYWxTaWduIFRpbWVzdGFt
# cGluZyBDQSAtIEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAlO9l
# +LVXn6BTDTQG6wkft0cYasvwW+T/J6U00feJGr+esc0SQW5m1IGghYtkWkYvmaCN
# d7HivFzdItdqZ9C76Mp03otPDbBS5ZBb60cO8eefnAuQZT4XljBFcm05oRc2yrmg
# jBtPCBn2gTGtYRakYua0QJ7D/PuV9vu1LpWBmODvxevYAll4d/eq41JrUJEpxfz3
# zZNl0mBhIvIG+zLdFlH6Dv2KMPAXCae78wSuq5DnbN96qfTvxGInX2+ZbTh0qhGL
# 2t/HFEzphbLswn1KJo/nVrqm4M+SU4B09APsaLJgvIQgAIMboe60dAXBKY5i0Eex
# +vBTzBj5Ljv5cH60JQIDAQABo4HlMIHiMA4GA1UdDwEB/wQEAwIBBjASBgNVHRMB
# Af8ECDAGAQH/AgEAMB0GA1UdDgQWBBRG2D7/3OO+/4Pm9IWbsN1q1hSpwTBHBgNV
# HSAEQDA+MDwGBFUdIAAwNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFs
# c2lnbi5jb20vcmVwb3NpdG9yeS8wMwYDVR0fBCwwKjAooCagJIYiaHR0cDovL2Ny
# bC5nbG9iYWxzaWduLm5ldC9yb290LmNybDAfBgNVHSMEGDAWgBRge2YaRQ2XyolQ
# L30EzTSo//z9SzANBgkqhkiG9w0BAQUFAAOCAQEATl5WkB5GtNlJMfO7FzkoG8IW
# 3f1B3AkFBJtvsqKa1pkuQJkAVbXqP6UgdtOGNNQXzFU6x4Lu76i6vNgGnxVQ380W
# e1I6AtcZGv2v8Hhc4EvFGN86JB7arLipWAQCBzDbsBJe/jG+8ARI9PBw+DpeVoPP
# PfsNvPTF7ZedudTbpSeE4zibi6c1hkQgpDttpGoLoYP9KOva7yj2zIhd+wo7AKvg
# IeviLzVsD440RZfroveZMzV+y5qKu0VN5z+fwtmK+mWybsd+Zf/okuEsMaL3sCc2
# SI8mbzvuTXYfecPlf5Y1vC0OzAGwjn//UYCAp5LUs0RGZIyHTxZjBzFLY7Df8zCC
# BCgwggMQoAMCAQICCwQAAAAAAS9O4TVcMA0GCSqGSIb3DQEBBQUAMFcxCzAJBgNV
# BAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMRAwDgYDVQQLEwdSb290
# IENBMRswGQYDVQQDExJHbG9iYWxTaWduIFJvb3QgQ0EwHhcNMTEwNDEzMTAwMDAw
# WhcNMTkwNDEzMTAwMDAwWjBRMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFs
# U2lnbiBudi1zYTEnMCUGA1UEAxMeR2xvYmFsU2lnbiBDb2RlU2lnbmluZyBDQSAt
# IEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsk8U5xC+1yZyqzaX
# 71O/QoReWNGKKPxDRm9+KERQC3VdANc8CkSeIGqk90VKN2Cjbj8S+m36tkbDaqO4
# DCcoAlco0VD3YTlVuMPhJYZSPL8FHdezmviaJDFJ1aKp4tORqz48c+/2KfHINdAw
# e39OkqUGj4fizvXBY2asGGkqwV67Wuhulf87gGKdmcfHL2bV/WIaglVaxvpAd47J
# MDwb8PI1uGxZnP3p1sq0QB73BMrRZ6l046UIVNmDNTuOjCMMdbbehkqeGj4KUEk4
# nNKokL+Y+siMKycRfir7zt6prjiTIvqm7PtcYXbDRNbMDH4vbQaAonRAu7cf9DvX
# c1Qf8wIDAQABo4H6MIH3MA4GA1UdDwEB/wQEAwIBBjASBgNVHRMBAf8ECDAGAQH/
# AgEAMB0GA1UdDgQWBBQIbti2nIq/7T7Xw3RdzIAfqC9QejBHBgNVHSAEQDA+MDwG
# BFUdIAAwNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFsc2lnbi5jb20v
# cmVwb3NpdG9yeS8wMwYDVR0fBCwwKjAooCagJIYiaHR0cDovL2NybC5nbG9iYWxz
# aWduLm5ldC9yb290LmNybDATBgNVHSUEDDAKBggrBgEFBQcDAzAfBgNVHSMEGDAW
# gBRge2YaRQ2XyolQL30EzTSo//z9SzANBgkqhkiG9w0BAQUFAAOCAQEAIlzF3T30
# C3DY4/XnxY4JAbuxljZcWgetx6hESVEleq4NpBk7kpzPuUImuztsl+fHzhFtaJHa
# jW3xU01UOIxh88iCdmm+gTILMcNsyZ4gClgv8Ej+fkgHqtdDWJRzVAQxqXgNO4yw
# cME9fte9LyrD4vWPDJDca6XIvmheXW34eNK+SZUeFXgIkfs0yL6Erbzgxt0Y2/PK
# 8HvCFDwYuAO6lT4hHj9gaXp/agOejUr58CgsMIRe7CZyQrFty2TDEozWhEtnQXyx
# Axd4CeOtqLaWLaR+gANPiPfBa1pGFc0sGYvYcJzlLUmIYHKopBlScENe2tZGA7Bo
# DiTvSvYLJSTvJDCCBJ8wggOHoAMCAQICEhEhBqCB0z/YeuWCTMFrUglOAzANBgkq
# hkiG9w0BAQUFADBSMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBu
# di1zYTEoMCYGA1UEAxMfR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0EgLSBHMjAe
# Fw0xNTAyMDMwMDAwMDBaFw0yNjAzMDMwMDAwMDBaMGAxCzAJBgNVBAYTAlNHMR8w
# HQYDVQQKExZHTU8gR2xvYmFsU2lnbiBQdGUgTHRkMTAwLgYDVQQDEydHbG9iYWxT
# aWduIFRTQSBmb3IgTVMgQXV0aGVudGljb2RlIC0gRzIwggEiMA0GCSqGSIb3DQEB
# AQUAA4IBDwAwggEKAoIBAQCwF66i07YEMFYeWA+x7VWk1lTL2PZzOuxdXqsl/Tal
# +oTDYUDFRrVZUjtCoi5fE2IQqVvmc9aSJbF9I+MGs4c6DkPw1wCJU6IRMVIobl1A
# cjzyCXenSZKX1GyQoHan/bjcs53yB2AsT1iYAGvTFVTg+t3/gCxfGKaY/9Sr7KFF
# WbIub2Jd4NkZrItXnKgmK9kXpRDSRwgacCwzi39ogCq1oV1r3Y0CAikDqnw3u7sp
# Tj1Tk7Om+o/SWJMVTLktq4CjoyX7r/cIZLB6RA9cENdfYTeqTmvT0lMlnYJz+iz5
# crCpGTkqUPqp0Dw6yuhb7/VfUfT5CtmXNd5qheYjBEKvAgMBAAGjggFfMIIBWzAO
# BgNVHQ8BAf8EBAMCB4AwTAYDVR0gBEUwQzBBBgkrBgEEAaAyAR4wNDAyBggrBgEF
# BQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFsc2lnbi5jb20vcmVwb3NpdG9yeS8wCQYD
# VR0TBAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDBCBgNVHR8EOzA5MDegNaAz
# hjFodHRwOi8vY3JsLmdsb2JhbHNpZ24uY29tL2dzL2dzdGltZXN0YW1waW5nZzIu
# Y3JsMFQGCCsGAQUFBwEBBEgwRjBEBggrBgEFBQcwAoY4aHR0cDovL3NlY3VyZS5n
# bG9iYWxzaWduLmNvbS9jYWNlcnQvZ3N0aW1lc3RhbXBpbmdnMi5jcnQwHQYDVR0O
# BBYEFNSihEo4Whh/uk8wUL2d1XqH1gn3MB8GA1UdIwQYMBaAFEbYPv/c477/g+b0
# hZuw3WrWFKnBMA0GCSqGSIb3DQEBBQUAA4IBAQCAMtwHjRygnJ08Kug9IYtZoU1+
# zETOA75+qrzE5ntzu0vxiNqQTnU3KDhjudcrD1SpVs53OZcwc82b2dkFRRyNpLgD
# XU/ZHC6Y4OmI5uzXBX5WKnv3FlujrY+XJRKEG7JcY0oK0u8QVEeChDVpKJwM5B8U
# FiT6ddx0cm5OyuNqQ6/PfTZI0b3pBpEsL6bIcf3PvdidIZj8r9veIoyvp/N3753c
# o3BLRBrweIUe8qWMObXciBw37a0U9QcLJr2+bQJesbiwWGyFOg32/1onDMXeU+dU
# PFZMyU5MMPbyXPsajMKCvq1ZkfYbTVV7z1sB3P16028jXDJHmwHzwVEURoqbMIIE
# rTCCA5WgAwIBAgISESFgd9/aXcgt4FtCBtsrp6UyMA0GCSqGSIb3DQEBBQUAMFEx
# CzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMScwJQYDVQQD
# Ex5HbG9iYWxTaWduIENvZGVTaWduaW5nIENBIC0gRzIwHhcNMTIwNjA4MDcyNDEx
# WhcNMTUwNzEyMTAzNDA0WjB6MQswCQYDVQQGEwJERTEbMBkGA1UECBMSU2NobGVz
# d2lnLUhvbHN0ZWluMRAwDgYDVQQHEwdJdHplaG9lMR0wGwYDVQQKDBRkLWZlbnMg
# R21iSCAmIENvLiBLRzEdMBsGA1UEAwwUZC1mZW5zIEdtYkggJiBDby4gS0cwggEi
# MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDTG4okWyOURuYYwTbGGokj+lvB
# go0dwNYJe7HZ9wrDUUB+MsPTTZL82O2INMHpQ8/QEMs87aalzHz2wtYN1dUIBUae
# dV7TZVme4ycjCfi5rlL+p44/vhNVnd1IbF/pxu7yOwkAwn/iR+FWbfAyFoCThJYk
# 9agPV0CzzFFBLcEtErPJIvrHq94tbRJTqH9sypQfrEToe5kBWkDYfid7U0rUkH/m
# bff/Tv87fd0mJkCfOL6H7/qCiYF20R23Kyw7D2f2hy9zTcdgzKVSPw41WTsQtB3i
# 05qwEZ3QCgunKfDSCtldL7HTdW+cfXQ2IHItN6zHpUAYxWwoyWLOcWcS69InAgMB
# AAGjggFUMIIBUDAOBgNVHQ8BAf8EBAMCB4AwTAYDVR0gBEUwQzBBBgkrBgEEAaAy
# ATIwNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFsc2lnbi5jb20vcmVw
# b3NpdG9yeS8wCQYDVR0TBAIwADATBgNVHSUEDDAKBggrBgEFBQcDAzA+BgNVHR8E
# NzA1MDOgMaAvhi1odHRwOi8vY3JsLmdsb2JhbHNpZ24uY29tL2dzL2dzY29kZXNp
# Z25nMi5jcmwwUAYIKwYBBQUHAQEERDBCMEAGCCsGAQUFBzAChjRodHRwOi8vc2Vj
# dXJlLmdsb2JhbHNpZ24uY29tL2NhY2VydC9nc2NvZGVzaWduZzIuY3J0MB0GA1Ud
# DgQWBBTwJ4K6WNfB5ea1nIQDH5+tzfFAujAfBgNVHSMEGDAWgBQIbti2nIq/7T7X
# w3RdzIAfqC9QejANBgkqhkiG9w0BAQUFAAOCAQEAB3ZotjKh87o7xxzmXjgiYxHl
# +L9tmF9nuj/SSXfDEXmnhGzkl1fHREpyXSVgBHZAXqPKnlmAMAWj0+Tm5yATKvV6
# 82HlCQi+nZjG3tIhuTUbLdu35bss50U44zNDqr+4wEPwzuFMUnYF2hFbYzxZMEAX
# Vlnaj+CqtMF6P/SZNxFvaAgnEY1QvIXI2pYVz3RhD4VdDPmMFv0P9iQ+npC1pmNL
# mCaG7zpffUFvZDuX6xUlzvOi0nrTo9M5F2w7LbWSzZXedam6DMG0nR1Xcx0qy9wY
# nq4NsytwPbUy+apmZVSalSvldiNDAfmdKP0SCjyVwk92xgNxYFwITJuNQIto4zGC
# BK4wggSqAgEBMGcwUTELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24g
# bnYtc2ExJzAlBgNVBAMTHkdsb2JhbFNpZ24gQ29kZVNpZ25pbmcgQ0EgLSBHMgIS
# ESFgd9/aXcgt4FtCBtsrp6UyMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQow
# CKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcC
# AQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBRvE2JXisEDpFJ/OQlv
# OGa+hFnOBTANBgkqhkiG9w0BAQEFAASCAQA26W+xFUrNOUbmUVxkrCE9ZxzUcmfd
# LrhM4TvxK4QBI8sAoMmWwWexXlk7UZOZ2cJcuNvpyA4kCnwcZ7USgZFj25lmFOjR
# rkZF/r3zA+N2u2YXo4dfX17ZuLPSKOp/OZla8orGA9YJM653UB3hPoWy/vZfFW/j
# 6sqMn6Xisga7JvRnUyqKk3El2jKoD4TsHgXM3ceqxg4chsAGBl+jCmKOiEiAOdbQ
# LeEpP7TyrMqEsGzIF6OYziZIOZgL94tqJ+Ik2JqQMroXdyJGsKRkin30MMvC1xvE
# CXfnVcxlsyq9IcjaRIVV1EemaL3cXYGGKPTEm5Zmre010zTeDhrYg+RJoYICojCC
# Ap4GCSqGSIb3DQEJBjGCAo8wggKLAgEBMGgwUjELMAkGA1UEBhMCQkUxGTAXBgNV
# BAoTEEdsb2JhbFNpZ24gbnYtc2ExKDAmBgNVBAMTH0dsb2JhbFNpZ24gVGltZXN0
# YW1waW5nIENBIC0gRzICEhEhBqCB0z/YeuWCTMFrUglOAzAJBgUrDgMCGgUAoIH9
# MBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTE1MDQx
# NjE1MTA0NlowIwYJKoZIhvcNAQkEMRYEFNgOcMdE/3Tdh0d40jj6R8zd0ptuMIGd
# BgsqhkiG9w0BCRACDDGBjTCBijCBhzCBhAQUs2MItNTN7U/PvWa5Vfrjv7EsKeYw
# bDBWpFQwUjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2Ex
# KDAmBgNVBAMTH0dsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gRzICEhEhBqCB
# 0z/YeuWCTMFrUglOAzANBgkqhkiG9w0BAQEFAASCAQCD+wdspx1KDMAlvwhijEVw
# Ad3wdpHOq+vW0wTWuHGYQWIu1UrQUMmRdK82f2bVg2aglH4rJhnalMvYueYDIAmL
# dua7LDaXayd7NhASa9clV/5DKSQfXM1N9W+6KBBcrZqgdOlzB45TYzIJ5vpNGD9H
# Hlbzr6cmUqMoHATl9G+N5egOfRIeOOxiKu5AGLQp+VoFkacaJZwkPt+zyHXbzqMC
# Dufezt+rQdz7W+ocOXhNFH0kj/9cWFhQY8ZynhJlSBx00ythrsRVznEszQ+DKy4I
# uXgrX6tFvLzjWx1WmYtZtRSoE/k19l72lccoM3X+oQ4yXV1MdVeiSDS/9zSYaAro
# SIG # End signature block
