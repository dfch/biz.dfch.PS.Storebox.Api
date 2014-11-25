function Invoke-FileTransfer {
<#

.SYNOPSIS

Performs a REST call against a CTERA host and returns the XML result set.



.DESCRIPTION

Performs a REST call against a CTERA host and returns the XML result set.



.OUTPUTS

This Cmdlet returns an XML document on success. On failure it returns $null.



.INPUTS

See PARAMETER section for a description of input parameters.



.PARAMETER Session

A hashtable containing a WebRequestSession and an UriPortal string.



.PARAMETER Method

The HTTP method of the REST call. Default is 'GET'. Possible values: 'GET', 'POST', 'DELETE'. 'PUT'.

Alias: m


.PARAMETER Api

The command part of the REST call. Default is 'query'. For possible values see the vCD REST reference.

Alias: a


.PARAMETER QueryParameters

The QueryString part of the REST call. For possible values see the vCD REST reference.

Alias: q


.PARAMETER Body

Optional body of the REST call when using a POST or PUT operation/method. Default is '$null'. For possible values see the vCD REST reference.

Alias: b


.EXAMPLE 
 

Invoke-CteraFileTransfer -Upload MyProjectFolder -Path C:\myFile.txt -AutomaticFileName 

Upload file to Project folder 


.EXAMPLE

[DFCHECK] Give proper example. Gets all possible 'query' operations of the CTERA REST query service.

$xmlResponse = Invoke-FileTransfer;
$xmlResponse.QueryList.Link;


.LINK

Online Version: http://dfch.biz/biz/dfch/PS/Storebox/Api/Invoke-FileTransfer



.NOTES

See module manifest for dependencies and further requirements.


#>
[CmdletBinding(
	SupportsShouldProcess=$true,
	ConfirmImpact="High",
	HelpURI='http://dfch.biz/biz/dfch/PS/Storebox/Api/Invoke-FileTransfer'
)]
[OutputType([string])]
Param (
	[Parameter(Mandatory = $false, Position = 2)]
	[alias("s")]
	$Session = $biz_dfch_PS_Storebox_Api.Session
	,
	[Parameter(Mandatory = $true, ParameterSetName = 'u')]
	[alias("u")]
	[switch] $Upload
	, 
	[Parameter(Mandatory = $true, ParameterSetName = 'd')]
	[alias("d")]
	[switch] $Download
	, 
	[Parameter(Mandatory = $true, ParameterSetName = 'del')]
	[alias("del")]
	[switch] $Delete
	, 
	[Parameter(Mandatory = $true, ParameterSetName = 'm')]
	[alias("m")]
	[switch] $Move
	, 
	[Parameter(Mandatory = $true, ParameterSetName = 'c')]
	[alias("c")]
	[switch] $Copy
	, 
	[Parameter(Mandatory = $false)]
	[Alias('p')]
	[Alias('Portal')]
	[string] $PortalName = $biz_dfch_PS_Storebox_Api.PortalName
	,
	[Parameter(Mandatory = $false, Position = 0)]
	[alias("Source")]
	[string] $Api = '/'
	,
	[Parameter(Mandatory = $false, ParameterSetName = 'u')]
	[Parameter(Mandatory = $false, ParameterSetName = 'd')]
	[switch] $AutomaticFileName = $true
	, 
	[Parameter(Mandatory = $false, ParameterSetName = 'u')]
	[switch] $Folder = $false
	, 
	[Parameter(Mandatory = $false, Position = 1, ParameterSetName = 'u')]
	[Parameter(Mandatory = $false, Position = 1, ParameterSetName = 'd')]
	[string] $Path = $PWD
	,
	[Parameter(Mandatory = $false, ParameterSetName = 'u')]
	[switch] $CreateDirectory = $false
	,
	[Parameter(Mandatory = $false, ParameterSetName = 'd')]
	[switch] $ListAvailable = $false
	,
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'm')]
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'c')]
	[string] $NewUri
) # Param
BEGIN {

$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. ParameterSetName '{0}'; Api: '{1}'." -f $PSCmdlet.ParameterSetName, $Api) -fac 1;

}
PROCESS {

[boolean] $fReturn = $false;

try {
	# Parameter validation
	if( $Session -isnot [System.Collections.Hashtable] ) {
		Log-Error $fn ("Invalid input parameter type specified: Session. Aborting ...");
		throw($gotoFailure);
	} # if
	if(!$Session.ContainsKey('WebSession')) {
		Log-Error $fn ("Invalid input parameter type specified: Session [{0}] does not contain key 'WebSession'. Aborting ..." -f $Session.GetType().FullName);
		throw($gotoFailure);
	} #if
	$WebRequestSession = $Session.WebSession;
	if( $WebRequestSession -isnot [Microsoft.PowerShell.Commands.WebRequestSession] ) {
		Log-Error $fn ("Invalid input parameter type specified: WebRequestSession [{0}]. Aborting ..." -f $WebRequestSession.GetType().FullName);
		throw($gotoFailure);
	} # if
	if(!$Session.ContainsKey('UriPortal')) {
		Log-Error $fn ("Invalid input parameter type specified: Session [{0}] does not contain key 'UriPortal'. Aborting ..." -f $Session.GetType().FullName);
		throw($gotoFailure);
	} #if
	if(!$PortalName) {
		Log-Error $fn ("Invalid input parameter type specified: 'PortalName' is not set. Aborting ...");
		throw($gotoFailure);
	} #if
	$UriAdmin = '{0}{1}' -f $Session.UriPortal, $biz_dfch_PS_Storebox_Api.UriBaseLocal;
	if($Api.StartsWith($UriAdmin)) { $Api = $Api.Replace($UriAdmin, ''); }
	if($Api.StartsWith($biz_dfch_PS_Storebox_Api.UriBaseLocal)) { $Api = $Api.Replace($biz_dfch_PS_Storebox_Api.UriBaseLocal, ''); }
	$Api = $Api.TrimStart('/');
	if(!$Api.StartsWith('webdav')) { $Api = 'webdav/{0}' -f $Api; }
	$Api = $Api.TrimStart('/');
	if([string]::IsNullOrEmpty($Api) -or [string]::IsNullOrWhiteSpace($Api)) {
		Log-Error $fn "Invalid or empty input parameter specified: Api. Aborting ...";
		throw($gotoFailure);
	} # if
	switch($PSCmdlet.ParameterSetName) {
	'd' {
		$Method = 'GET';
	} # 'd'
	'u' {
		$Method = 'PUT';
		$fReturn = Test-Path -Path $Path;
		if($fReturn) { 
			$File = Get-Item -Path $Path;
		} else {
			$fReturn = Test-Path -LiteralPath $Path; 
		} # if
		if($fReturn -and !$File) {
			$File = Get-Item -LiteralPath $Path;
		} elseif($File) {
			# good - we got a file object
			$Path = $File.FullName;
		} else {
			$e = New-CustomErrorRecord -m ("Unsupported ParameterSetName '{0}'." -f $PSCmdlet.ParameterSetName) -cat ObjectNotFound -o $Path;
			throw($gotoError);
		} # if
	} # 'u'
	'del' {
	$Method = 'DELETE';
	} # 'del'
	'm' {
	$Method = 'MOVE';
	} # 'm'
	'c' {
	$Method = 'COPY';
	} # 'c'
	default {
	$e = New-CustomErrorRecord -m ("Unsupported ParameterSetName '{0}'." -f $PSCmdlet.ParameterSetName) -cat InvalidArgument -o $PSCmdlet.ParameterSetName;
	throw($gotoError);
	}
	} # switch
	
	if($PSCmdlet.ParameterSetName -eq 'd') {
		$Uri = ('{0}{1}') -f $UriAdmin, $Api;
		[Uri] $UriUri = $Uri;
		if($AutomaticFileName) {
			$Path = Join-Path -Path $Path -ChildPath $UriUri.Segments[-1];
		} # if
		$Uri = $UriUri.AbsoluteUri;
	} # if
	if($PSCmdlet.ParameterSetName -eq 'u') {
		[Uri] $UriPath = $Path;
		$Uri = ('{0}{1}') -f $UriAdmin, $Api;
		[Uri] $UriUri = $Uri;
		if($AutomaticFileName) {
			$Uri = '{0}/{1}' -f $UriUri.AbsoluteUri.TrimEnd('/'), $UriPath.Segments[-1];
			[Uri] $UriUri = $Uri;
		} # if
		$Uri = $UriUri.AbsoluteUri;
	} # if
	if($PSCmdlet.ParameterSetName -eq 'del') {
		$Uri = ('{0}{1}') -f $UriAdmin, $Api;
		[Uri] $UriUri = $Uri;
		$Uri = $UriUri.AbsoluteUri;
	} # if

	$QueryParameters = 'portalName={0}' -f $PortalName;
	$Uri = ('{0}?{1}' -f $Uri, $QueryParameters).TrimEnd('?');
	[Uri] $UriUri = $Uri;
	$Uri = $UriUri.AbsoluteUri;

	# create WebClient
	$wc = New-Object System.Net.WebClient;
	$wc.Encoding = [System.Text.Encoding]::UTF8;
	$wc.Headers.Clear();
	
	$wc.Headers.Add("Cookie", $WebRequestSession.Cookies.GetCookieHeader($uri))
	#$wc.Headers.Add('Content-Type', 'text/xml; charset=UTF-8');
	$wc.Headers.Add('Content-Type', 'application/octet-stream');
	$wc.Headers.Add('Accept', '*/*');
	#$wc.Headers.Add('x-ctera-token', $WebRequestSession.Cookies.GetCookieHeader($uri));
	$wc.Headers.Add('x-ctera-token', $biz_dfch_PS_Storebox_Api.SessionCookie.Value);
	$wc.Headers.Add('User-Agent', $WebRequestSession.UserAgent);

	$msg = "Invoking '{0}' '{1}' [on '{2}'] ..." -f $Method, $Uri, $Path;
	Log-Debug $fn $msg;
	if(!$PSCmdlet.ShouldProcess($msg)) {
		$fReturn = $false;
	} else {
		[string] $response = '';
		$Method = $Method.ToUpper();
		if($Method -eq 'GET') {
			if($ListAvailable) {
				$Method = 'PROPFIND';
				$response = $wc.UploadString($Uri, $Method, '');
				Log-Debug $fn ("response count '{0}'" -f $r.multistatus.response.Count);
				# $response = $true;
			} else {
				$response = $wc.DownloadFile($Uri, $Path);
				$response = $true;
			} # if
		} elseif($Method -eq 'DELETE') {
			$response = $wc.UploadString($Uri, $Method, '');
		} else {
			if($CreateDirectory) {
				$Method = 'MKCOL';
				$response = $wc.UploadString($Uri, $Method, '');
			} else {
				$response = $wc.UploadFile($Uri, $Method, $Path);
			} # if
		} # if
		if(!$response) {
			Log-Error $fn ("Invoking '{0}' '{1}' FAILED. '{2}'" -f $Method, $Uri, $error[0]);
			throw($gotoFailure);
		} # if
		Log-Info $fn ("Invoking '{0}' '{1}' SUCCEEDED." -f $Method, $Uri);
		$OutputParameter = $response;
		$fReturn = $true;
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
			Log-Critical $fn ("Operation '{0}' '{1}' FAILED [{2}]." -f $Method, $Uri, $_);
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
	if($wc -is [System.Net.WebClient]) { $wc.Dispose(); }
} # finally
return $OutputParameter;

} # PROCESS
END {
	$datEnd = [datetime]::Now;
	Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;
} # END
} # function
if($MyInvocation.ScriptName) { Export-ModuleMember -Function Invoke-FileTransfer; } 



# SIG # Begin signature block
# MIIW3AYJKoZIhvcNAQcCoIIWzTCCFskCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUrtwcJbh1Zs3f8WWbPAfSRwZO
# JpugghGYMIIEFDCCAvygAwIBAgILBAAAAAABL07hUtcwDQYJKoZIhvcNAQEFBQAw
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
# AQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBSPbtdUfGO+JdWH9xMd
# enKHiHvJjDANBgkqhkiG9w0BAQEFAASCAQCO1A6C4vOKTpSE06TB9jpa099K3M85
# Px4YqOUE4rV6xXKsmWXPQ8XamtRCuZ06Lr8XZYUs48Rl2sbPtSE6YS5AMoGAbujr
# PMeYLdGpACc/2wNVT8CVsqzoWf/icz3DOi0rKgo3hSFhLE39/OICSfGyAXvpWr8k
# IWOPBXAwNfjzvG7U6iGiK9KduWM7eWVOTshMJZJWh5YlWqYq+HMidb/S/3snvOt1
# 0W69z3cGe8TeXgcr/jVyLtiKOfEz7ClhfclAddFNlbcD3zJVsF1comXYL/dCvrdn
# 3VxItuWCVt/2CeME6/U8z8RnJFSpHA9x5thMYOe53+OnMVPeDQHmhp63oYICojCC
# Ap4GCSqGSIb3DQEJBjGCAo8wggKLAgEBMGgwUjELMAkGA1UEBhMCQkUxGTAXBgNV
# BAoTEEdsb2JhbFNpZ24gbnYtc2ExKDAmBgNVBAMTH0dsb2JhbFNpZ24gVGltZXN0
# YW1waW5nIENBIC0gRzICEhEhQFwfDtJYiCvlTYaGuhHqRTAJBgUrDgMCGgUAoIH9
# MBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTE0MTEy
# NTE2MjU0MFowIwYJKoZIhvcNAQkEMRYEFCvpNn5Enagtja1qw0t+EzVPtXbQMIGd
# BgsqhkiG9w0BCRACDDGBjTCBijCBhzCBhAQUjOafUBLh0aj7OV4uMeK0K947NDsw
# bDBWpFQwUjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2Ex
# KDAmBgNVBAMTH0dsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gRzICEhEhQFwf
# DtJYiCvlTYaGuhHqRTANBgkqhkiG9w0BAQEFAASCAQCdUObkb2psu59VgL63S+gO
# 3wJmM121sIbcstS4oLEIL+xI48VST025M+Avtu1lRBJC9A1Us3DcamMN5noNgmAu
# rcgFUz1Sf+VuqlYaT8tGITJxOOc9mAVWUnz7YvoQ7LOMtwk0Qj96uvWcXS0o9DvN
# uEXNiaCx+PaKgsXXlG9lUlKfglLx8DYEOaspZ3s/zCkG0M/D9+bph34HuT5Yci4K
# uNWv86R1Ptx9sCPc9gXHpdNJia6raj5sqVVsJz0tAk/owvJDJlOGVxA6bFqJzjCO
# izZKYL3r2q46WrVp3bMq2+QUMmvY+23pxMZWC9KJoe11fIYE1TccSWx+8W/8M1co
# SIG # End signature block
