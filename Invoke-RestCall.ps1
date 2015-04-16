function Invoke-RestCall {
<#

.SYNOPSIS

Performs a REST call against a CTERA host and returns the XML result set.



.DESCRIPTION

Performs a REST call against a CTERA host and returns the XML result set.



.OUTPUTS

This Cmdlet returns an XML document on success. On failure it returns $null.



.INPUTS

See PARAMETER section for a description of input parameters.



.EXAMPLE
[DFCHECK] Give proper example. Gets all possible 'query' operations of the CTERA REST query service.

$xmlResponse = Invoke-RestCall;
$xmlResponse.QueryList.Link;


.EXAMPLE

[DFCHECK] Give proper example. Gets all CTERA Cells.

$xmlResponse = Invoke-RestCall -Api "query" -QueryParameters "type=cell";
$xmlResponse.QueryResultRecords.CellRecord;


.LINK

Online Version: http://dfch.biz/biz/dfch/PS/Storebox/Api/Invoke-RestCall



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.
Requires a session to a CTERA host.

#>
[CmdletBinding(
	HelpURI='http://dfch.biz/biz/dfch/PS/Storebox/Api/Invoke-RestCall'
)]
[OutputType([string])]
Param 
(
	# A hashtable containing a WebRequestSession and an UriPortal string.
	[Parameter(Mandatory = $false, Position = 2)]
	[alias("s")]
	$Session = $biz_dfch_PS_Storebox_Api.Session
	,
	# The HTTP method of the REST call. Default is 'GET'. 
	# Possible values: 'GET', 'POST', 'DELETE'. 'PUT', 'PROPFIND'.
	[ValidateSet('GET', 'POST', 'PUT', 'DELETE', 'PROPFIND')]
	[Parameter(Mandatory = $false, Position = 1)]
	[alias("m")]
	[string] $Method = 'GET'
	, 
	# The command part of the REST call. Default is '/'.
	[Parameter(Mandatory = $false, Position = 0)]
	[alias("a")]
	[string] $Api = '/'
	,
	# The QueryString part of the REST call.
	[Parameter(Mandatory = $false, Position = 3)]
	[alias("q")]
	[string] $QueryParameters = $null
	, 
	# Optional body of the REST call when using a POST or PUT operation/method. 
	# Default is '$null'.
	[Parameter(Mandatory = $false, Position = 4)]
	[alias("b")]
	[string] $Body = $null 
)
BEGIN 
{
	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
	Log-Debug -fn $fn -msg ("CALL. Method '{0}'; Api: '{1}'." -f $Method, $Api) -fac 1;
}
PROCESS 
{
	[boolean] $fReturn = $false;
	try 
	{
		# Parameter validation
		if( $Session -isnot [System.Collections.Hashtable] ) 
		{
			Log-Error $fn ("Invalid input parameter type specified: Session. Aborting ...");
			throw($gotoFailure);
		}
		if(!$Session.ContainsKey('WebSession')) 
		{
			Log-Error $fn ("Invalid input parameter type specified: Session [{0}] does not contain key 'WebSession'. Aborting ..." -f $Session.GetType().FullName);
			throw($gotoFailure);
		}
		$WebRequestSession = $Session.WebSession;
		if( $WebRequestSession -isnot [Microsoft.PowerShell.Commands.WebRequestSession] ) 
		{
			Log-Error $fn ("Invalid input parameter type specified: WebRequestSession [{0}]. Aborting ..." -f $WebRequestSession.GetType().FullName);
			throw($gotoFailure);
		}
		if(!$Session.ContainsKey('UriPortal')) 
		{
			Log-Error $fn ("Invalid input parameter type specified: Session [{0}] does not contain key 'UriPortal'. Aborting ..." -f $Session.GetType().FullName);
			throw($gotoFailure);
		}
		$UriPortal = $Session.UriPortal;
		$UriAdmin = '{0}{1}' -f $UriPortal, $biz_dfch_PS_Storebox_Api.UriBase;
		if([string]::IsNullOrEmpty($Api) -or [string]::IsNullOrWhiteSpace($Api)) 
		{
			Log-Error $fn "Invalid or empty input parameter specified: Api. Aborting ...";
			throw($gotoFailure);
		}
		if([string]::Compare($Api, '/') -eq 0) 
		{
			$Api = '';
		}
		
		# create WebClient
		$wc = New-Object System.Net.WebClient;
		$wc.Encoding = [System.Text.Encoding]::UTF8;
		$wc.Headers.Clear();
		
		$Uri = ('{0}{1}?{2}' -f $UriAdmin, $Api, $QueryParameters).TrimEnd('?');
		$wc.Headers.Add("Cookie", $WebRequestSession.Cookies.GetCookieHeader($uri))
		$wc.Headers.Add('Content-Type', 'text/xml; charset=UTF-8');
		$wc.Headers.Add('Accept', '*/*');
		#$wc.Headers.Add('x-ctera-token', $WebRequestSession.Cookies.GetCookieHeader($uri));
		$wc.Headers.Add('x-ctera-token', $biz_dfch_PS_Storebox_Api.SessionCookie.Value);
		$wc.Headers.Add('User-Agent', $WebRequestSession.UserAgent);

		# Excessive logging
		# Log-Debug $fn ("Invoking '{0}' '{1}' ..." -f $Method, $Uri);
		[string] $response = '';
		if('GET'.Equals($Method.ToUpper()) ) 
		{
			$response = $wc.DownloadString($Uri);
		} 
		else 
		{
			$response = $wc.UploadString($Uri, $Method.ToUpper(), $Body);
		}
		if(!$response) 
		{
			Log-Error $fn ("Invoking '{0}' '{1}' FAILED. '{2}'" -f $Method, $Uri, $error[0]);
			throw($gotoFailure);
		}
		# Excessive logging
		# Log-Info $fn ("Invoking '{0}' '{1}' SUCCEEDED." -f $Method, $Uri);
		try 
		{
			# try to convert the response to XML
			# on failure we are probably not authenticated or something else went wrong
			$xmlResult = [xml] $response;
			$OutputParameter = $response;
			$fReturn = $true;
		}
		catch 
		{
			$e = New-CustomErrorRecord -m ("Executing '{0}' '{1}' FAILED as response is no XML. Maybe authentication expired?" -f $Method, $Uri) -cat InvalidData -o $response;
			throw($gotoError);
		}
	}
	catch 
	{
		if($gotoSuccess -eq $_.Exception.Message) 
		{
			$fReturn = $true;
		} 
		else 
		{
			[string] $ErrorText = "catch [$($_.FullyQualifiedErrorId)]";
			$ErrorText += (($_ | fl * -Force) | Out-String);
			$ErrorText += (($_.Exception | fl * -Force) | Out-String);
			$ErrorText += (Get-PSCallStack | Out-String);
			
			if($_.Exception.InnerException -is [System.Net.WebException]) 
			{
				Log-Critical $fn ("Operation '{0}' '{1}' FAILED [{2}]." -f $Method, $Uri, $_);
				$HttpWebResponse = $_.Exception.InnerException.Response;
				if($HttpWebResponse -is [System.Net.HttpWebResponse]) 
				{
					$sr = New-Object System.IO.StreamReader($HttpWebResponse.GetResponseStream(), $true);
					$Content = $sr.ReadToEnd();
					Log-Error $fn ("{0}`n{1}" -f $_.Exception.InnerException.Message, $Content) -v;
				}
				Log-Debug $fn $ErrorText -fac 3;
			}
			else 
			{
				Log-Error $fn $ErrorText -fac 3;
				if($gotoError -eq $_.Exception.Message) 
				{
					Log-Error $fn $e.Exception.Message;
					$PSCmdlet.ThrowTerminatingError($e);
				} 
				elseif($gotoFailure -ne $_.Exception.Message) 
				{ 
					Write-Verbose ("$fn`n$ErrorText"); 
				} 
				else 
				{
					# N/A
				}
			}
			$fReturn = $false;
			$OutputParameter = $null;
		}
	}
	finally 
	{
		# Clean up
		if($wc -is [System.Net.WebClient]) 
		{ 
			$wc.Dispose(); 
		}
	}
	return $OutputParameter;
}

END 
{
	$datEnd = [datetime]::Now;
	if(1000 -le ($datEnd - $datBegin).TotalMilliseconds)
	{
		Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;
	}
}
} # function
Set-Alias -Name Invoke-Command -Value Invoke-RestCall;
Export-ModuleMember -Function Invoke-RestCall -Alias Invoke-Command;

<##
 #
 #
 # Copyright 2014, 2015 Ronald Rink, d-fens GmbH
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
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUFBfi2FJzRVPRMeBlDaDGEyEn
# BZagghGYMIIEFDCCAvygAwIBAgILBAAAAAABL07hUtcwDQYJKoZIhvcNAQEFBQAw
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
# AQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBQO0piSMwqp4rx4obbL
# OcpG6kJjaTANBgkqhkiG9w0BAQEFAASCAQACK9HI1+iN1bd4KN9zW1LHcIETfLq8
# 2AZ3vRwo0A5s8qVRhUN3ZDAWNGb8rmX0j9Ob0dV3fas8pdNkbSJDobLTvsFs32lY
# 9CG8ljCIWHfoj3c8vGBL15Jx9PSVKzSM9Wtdhc1xuTBYAfOcRmtz24TTRgD1D8u7
# XnNfYDuVf0axmcO1y1cQDerU5ZZJVf/FjL6kQwx8wAjPwzqu3fGLvtjMZjeSDLsZ
# D7h4cTXTizyrCgEPpGoAASlmhHRC8BxGdSAPoCi+9yR2R1RV4o7AlMn6FOBFGBu+
# imv57VdjZGiX/PmLD0yuH3o2sqAkBoO8a7lHvdv8Elvo0zdGcSBbvALioYICojCC
# Ap4GCSqGSIb3DQEJBjGCAo8wggKLAgEBMGgwUjELMAkGA1UEBhMCQkUxGTAXBgNV
# BAoTEEdsb2JhbFNpZ24gbnYtc2ExKDAmBgNVBAMTH0dsb2JhbFNpZ24gVGltZXN0
# YW1waW5nIENBIC0gRzICEhEhBqCB0z/YeuWCTMFrUglOAzAJBgUrDgMCGgUAoIH9
# MBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTE1MDQx
# NjE1MDA1NlowIwYJKoZIhvcNAQkEMRYEFNfNPu+UrOwg/ZPnPVhA4UbTmizZMIGd
# BgsqhkiG9w0BCRACDDGBjTCBijCBhzCBhAQUs2MItNTN7U/PvWa5Vfrjv7EsKeYw
# bDBWpFQwUjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2Ex
# KDAmBgNVBAMTH0dsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gRzICEhEhBqCB
# 0z/YeuWCTMFrUglOAzANBgkqhkiG9w0BAQEFAASCAQCCzhbF6ipA00+IJV/aJqUo
# iKceC4LsNaWkAQopeir8oRIyPDmCaZsO4MIq7Jd0ZIz9gIMIKnp4DDQk8cvVwH37
# eE+T7x0mZHeHquSGtz5FEeO/AHEqtXY0S9u9IXCaA1lRKLszmplOHwnTiVmqHUBR
# I6UwFJ9osgHHAdrDGVbv4ELxtiLLkYio9zobP3VlOFeQ8Rx/fDmabiDISNmTm7zB
# /katgBR25H3oD3kTxUU5wftmM9f+FADRfXA9JcrYQUVa4FLGF/Qthz97lF0jTFF0
# N3pTkDtihR+bazrJcNi2eknrQy9uNt0ven88qrsOA0TzYjG3nrygTlJio/9CeGnA
# SIG # End signature block
