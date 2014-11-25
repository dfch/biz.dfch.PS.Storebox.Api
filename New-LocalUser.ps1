function New-LocalUser {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium",
	HelpURI='http://dfch.biz/biz/dfch/PS/Storebox/Api/New-LocalUser/'
)]
[OutputType([hashtable])]
PARAM (
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'param')]
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'global')]
	[alias('n')]
	[alias('cn')]
	[alias('Identity')]
	[alias('u')]
	[alias('user')]
	[string] $UserName
	,
	[Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'param')]
	[Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'global')]
	[alias('mail')]
	[alias('email')]
	[string] $EmailAddress
	,
	[Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'param')]
	[Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'global')]
	[alias('givenName')]
	[string] $FirstName
	,
	[Parameter(Mandatory = $true, Position = 3, ParameterSetName = 'param')]
	[Parameter(Mandatory = $true, Position = 3, ParameterSetName = 'global')]
	[alias('sn')]
	[string] $LastName
	,
	[Parameter(Mandatory = $false, Position = 6, ParameterSetName = 'param')]
	[Parameter(Mandatory = $false, Position = 6, ParameterSetName = 'global')]
	[alias('pw')]
	$Password = $(New-SecurePassword)
	,
	[Parameter(Mandatory = $false, Position = 5, ParameterSetName = 'param')]
	[alias('org')]
	[string] $Company = ''
	,
	[Parameter(Mandatory = $false, Position = 6, ParameterSetName = 'param')]
	[Parameter(Mandatory = $false, Position = 6, ParameterSetName = 'global')]
	[alias('Description')]
	[alias('c')]
	[string] $Comment = ''
	,
	[Parameter(Mandatory = $false, Position = 7, ParameterSetName = 'param')]
	[int] $UUID
	,
	[ValidateSet('active', 'inactive')]
	[Parameter(Mandatory = $false, Position = 8, ParameterSetName = 'param')]
	[alias('s')]
	[alias('accountStatus')]
	[string] $Status = 'active'
	,
	[ValidateSet('EndUser', 'ReadOnlyAdmin', 'ReadWriteAdmin', 'Support', 'Disabled')]
	[Parameter(Mandatory = $false, Position = 9, ParameterSetName = 'param')]
	[Parameter(Mandatory = $false, Position = 9, ParameterSetName = 'global')]
	[alias('r')]
	[string] $Role = 'EndUser'
	,
	[Parameter(Mandatory = $false, Position = 10, ParameterSetName = 'param')]
	[Parameter(Mandatory = $false, Position = 10, ParameterSetName = 'global')]
	[alias('requirePasswordChangeOn')]
	[datetime] $PasswordExpires = 0
	,
	[Parameter(Mandatory = $false, ParameterSetName = 'global')]
	[alias('GlobalAdmin')]
	[switch] $Global = $false
)
BEGIN {
	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
	Log-Debug -fn $fn -msg ("CALL. ParameterSetName: '{0}'" -f $PSCmdlet.ParameterSetName) -fac 1;
	
	$fReturn = $false;
	$OutputParameter = @();
	$ParameterSetName = $PSCmdlet.ParameterSetName;
} # BEGIN

PROCESS {
try {
	# Parameter validation
	# N/A

    if($Password -is [System.Security.SecureString]) {
        $credUser = New-Object PSCredential -ArgumentList $Name, $Password
        $Password = $credUser.GetNetworkCredential().Password;
    } # if
    if($UUID -eq 0) {
        $UUID = '';
    } # if

	if($Global) {
		$UserTemplate = Get-DefaultsObj -Name 'PortalAdmin' | ConvertFrom-Obj;
		
		$UserTemplate.name = [System.Web.HttpUtility]::HtmlEncode($UserName);
		$UserTemplate.email = [System.Web.HttpUtility]::HtmlEncode($EmailAddress);
		$UserTemplate.firstName = [System.Web.HttpUtility]::HtmlEncode($FirstName);
		$UserTemplate.lastName = [System.Web.HttpUtility]::HtmlEncode($LastName);
		$UserTemplate.password = [System.Web.HttpUtility]::HtmlEncode($Password);
		$UserTemplate.role = [System.Web.HttpUtility]::HtmlEncode($Role);
		$UserTemplate.comment = [System.Web.HttpUtility]::HtmlEncode($Comment);
		$UserTemplate.requirePasswordChangeOn = [System.Web.HttpUtility]::HtmlEncode($PasswordExpires.ToString('yyyy-MM-dd'));
		
		$Body = Format-ExtendedMethod -name add -p ($UserTemplate | ConvertTo-Xml);
	} else {
		$sUserDefaults = Get-DefaultsObj -Name 'PortalUser';
		$oUserDefaults = ConvertFrom-Obj -XmlString $sUserDefaults;
		[xml] $xUserDefaults = $sUserDefaults;

		# set Name
		$n = $xUserDefaults.obj.SelectSingleNode("att[@id = 'name']");
		$n.set_InnerXML( ('<val>{0}</val>' -f [System.Web.HttpUtility]::HtmlEncode($UserName)) );
		# set Email
		$n = $xUserDefaults.obj.SelectSingleNode("att[@id = 'email']");
		$n.set_InnerXML( ('<val>{0}</val>' -f [System.Web.HttpUtility]::HtmlEncode($EmailAddress)) );
		# set LastName
		$n = $xUserDefaults.obj.SelectSingleNode("att[@id = 'lastName']");
		$n.set_InnerXML( ('<val>{0}</val>' -f [System.Web.HttpUtility]::HtmlEncode($LastName)) );
		# set FirstName
		$n = $xUserDefaults.obj.SelectSingleNode("att[@id = 'firstName']");
		$n.set_InnerXML( ('<val>{0}</val>' -f [System.Web.HttpUtility]::HtmlEncode($FirstName)) );
		# set Password
		$n = $xUserDefaults.obj.SelectSingleNode("att[@id = 'password']");
		$n.set_InnerXML( ('<val>{0}</val>' -f [System.Web.HttpUtility]::HtmlEncode($Password)) );
		# set Status
		$n = $xUserDefaults.obj.SelectSingleNode("att[@id = 'accountStatus']");
		$n.set_InnerXML( ('<val>{0}</val>' -f [System.Web.HttpUtility]::HtmlEncode($Status)) );
		# set Role
		$n = $xUserDefaults.obj.SelectSingleNode("att[@id = 'role']");
		$n.set_InnerXML( ('<val>{0}</val>' -f [System.Web.HttpUtility]::HtmlEncode($Role)) );
		# set UUID
		if($UUID -ne 0) {
			$n = $xUserDefaults.obj.SelectSingleNode("att[@id = 'uuid']");
			$n.set_InnerXML( ('<val>{0}</val>' -f [System.Web.HttpUtility]::HtmlEncode($UUID)) );
		} # if
		# set PasswordExpiry
		if($PasswordExpires.Ticks -ne 0) {
			$n = $xUserDefaults.obj.SelectSingleNode("att[@id = 'requirePasswordChangeOn']");
			$n.set_InnerXML( ('<val>{0}</val>' -f [System.Web.HttpUtility]::HtmlEncode($PasswordExpires.ToString('yyyy-MM-dd'))) );
		} # if
		# set comment
		if($Comment) {
			$n = $xUserDefaults.obj.SelectSingleNode("att[@id = 'comment']");
			$n.set_InnerXML( ('<val>{0}</val>' -f [System.Web.HttpUtility]::HtmlEncode($Comment)) );
		} # if
		# set company
		if($Company) {
			$n = $xUserDefaults.obj.SelectSingleNode("att[@id = 'company']");
			$n.set_InnerXML( ('<val>{0}</val>' -f [System.Web.HttpUtility]::HtmlEncode($Company)) );
		} # if

		$oUserDefaults = $xUserDefaults.OuterXml | ConvertFrom-Obj;
		$Body = Format-ExtendedMethod -name add -p $xUserDefaults.OuterXml;
	} # if

    if($PSCmdlet.ShouldProcess($UserName)) {
		if($Global) {
			$r = Invoke-Command -Method "POST" -Api 'administrators' -Body $Body;
		} else {
			$r = Invoke-Command -Method "POST" -Api 'users' -Body $Body;
		} # if
        if(!$r) {
		    $e = New-CustomErrorRecord -m ("Creating localUser '{0}' FAILED." -f $UserName) -cat NotSpecified -o $Body;
		    throw($gotoError);
        } # if
        $tmpLocalUser = ConvertFrom-Obj -XmlString ("<obj class='#uri'><att id='#uri'>{0}</att></obj>" -f $r);
        Log-Info $fn ("Created localUser '{0}' [{1}]." -f $UserName, $tmpLocalUser.'#uri') -Verbose:$Verbose;
	    $OutputParameter = $tmpLocalUser.Clone();
    } # if

} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
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
} # function
Export-ModuleMember -Function New-LocalUser;


# SIG # Begin signature block
# MIIW3AYJKoZIhvcNAQcCoIIWzTCCFskCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUwwmSCd8DiBmQHDARWFlXaGtY
# Oh6gghGYMIIEFDCCAvygAwIBAgILBAAAAAABL07hUtcwDQYJKoZIhvcNAQEFBQAw
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
# DiTvSvYLJSTvJDCCBJ8wggOHoAMCAQICEhEhQFwfDtJYiCvlTYaGuhHqRTANBgkq
# hkiG9w0BAQUFADBSMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBu
# di1zYTEoMCYGA1UEAxMfR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0EgLSBHMjAe
# Fw0xMzA4MjMwMDAwMDBaFw0yNDA5MjMwMDAwMDBaMGAxCzAJBgNVBAYTAlNHMR8w
# HQYDVQQKExZHTU8gR2xvYmFsU2lnbiBQdGUgTHRkMTAwLgYDVQQDEydHbG9iYWxT
# aWduIFRTQSBmb3IgTVMgQXV0aGVudGljb2RlIC0gRzEwggEiMA0GCSqGSIb3DQEB
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
# hZuw3WrWFKnBMA0GCSqGSIb3DQEBBQUAA4IBAQACMRQuWFdkQYXorxJ1PIgcw17s
# LOmhPPW6qlMdudEpY9xDZ4bUOdrexsn/vkWF9KTXwVHqGO5AWF7me8yiQSkTOMjq
# IRaczpCmLvumytmU30Ad+QIYK772XU+f/5pI28UFCcqAzqD53EvDI+YDj7S0r1tx
# KWGRGBprevL9DdHNfV6Y67pwXuX06kPeNT3FFIGK2z4QXrty+qGgk6sDHMFlPJET
# iwRdK8S5FhvMVcUM6KvnQ8mygyilUxNHqzlkuRzqNDCxdgCVIfHUPaj9oAAy126Y
# PKacOwuDvsu4uyomjFm4ua6vJqziNKLcIQ2BCzgT90Wj49vErKFtG7flYVzXMIIE
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
# AQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBSpeITOBo9svX6+FFnX
# 9rFDrkVGCzANBgkqhkiG9w0BAQEFAASCAQC7tYXVAXsE3tJ57LLir8zBwaUfPxSi
# d889fpED8q1lnTyPgvRaSDm8nL25oNJdgWv6/GF5oxzbzHxZbMgJWStEfvu/u6Lx
# orJ4hAJbRrs1gtTywazyUcSniqT/Hqnqggpze0MU/fbuzSLIfG18OsgNagDH09dS
# +J+gdNXW+QgBfLm0L+fyMkvttlGsyv95cUlYzYbr0+EGsKs3nbgEJBu15/gFdRAm
# yF9ChTLY+/BZORRcmwgjybqJprz9mlPmy0kP1MIJS/efIqdSrqtStuwjaRVA3LG1
# tAUzwaUW67LRBOXIcjTWIExpVBkzDLk3iwQof3aei6CJVx1+ak5G8hbFoYICojCC
# Ap4GCSqGSIb3DQEJBjGCAo8wggKLAgEBMGgwUjELMAkGA1UEBhMCQkUxGTAXBgNV
# BAoTEEdsb2JhbFNpZ24gbnYtc2ExKDAmBgNVBAMTH0dsb2JhbFNpZ24gVGltZXN0
# YW1waW5nIENBIC0gRzICEhEhQFwfDtJYiCvlTYaGuhHqRTAJBgUrDgMCGgUAoIH9
# MBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTE0MTEy
# NTE2MjU0MlowIwYJKoZIhvcNAQkEMRYEFESAqk3RWAaPkVEl7E52S7CCGm1yMIGd
# BgsqhkiG9w0BCRACDDGBjTCBijCBhzCBhAQUjOafUBLh0aj7OV4uMeK0K947NDsw
# bDBWpFQwUjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2Ex
# KDAmBgNVBAMTH0dsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gRzICEhEhQFwf
# DtJYiCvlTYaGuhHqRTANBgkqhkiG9w0BAQEFAASCAQA6/zecM8Yz/AJwbG8LqcDQ
# tdi7vNY3hYLK7oGiqkt/pNtxrCowNERD4tghQ0mHW/wzKbcZgw4hhp2+DW0AH2pp
# 3vIsuaEWtADafwMtYGVRvnm0aLneVmfGATqevha9slAKbmtJarXAZqvO++MNCIv6
# FAtitR+8bUWCrgmC7b+XvlcmFNzKwGUROygSRKRygt6fdwKRTt7q8nQ95h5P+9k4
# m1mb/r5lVCXTXXa9MtSydjV+x/9KGcryLxy+wBKNe6wNsbjAByo6S7c3qDNP/px7
# sPZh6GuGjtT30afCjDBIwUeY+hEze0Qv8/8pBcpmxN118apSWEFNTwXuZYaUbLs9
# SIG # End signature block
