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
$xmlResponse = Invoke-FileTransfer -Api "query" -QueryParameters "type=cell";
$xmlResponse.QueryResultRecords.CellRecord;
.EXAMPLE

Upload file to Project folder

Invoke-FileTransfer -Upload MyProjectFolder -Path C:\myFile.txt -AutomaticFileName

.LINK

Online Version: http://dfch.biz/biz/dfch/PS/Storebox/Api/Invoke-FileTransfer



.NOTES

See module manifest for dependencies and further requirements.


#>
[CmdletBinding(
	SupportsShouldProcess = $true
	,
	ConfirmImpact = 'High'
	,
	HelpURI = 'http://dfch.biz/biz/dfch/PS/Storebox/Api/Invoke-FileTransfer'
)]
[OutputType([string])]
Param 
(
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
BEGIN 
{

$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
# Log-Debug -fn $fn -msg ("CALL. ParameterSetName '{0}'; Api: '{1}'." -f $PSCmdlet.ParameterSetName, $Api) -fac 1;

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
	if(!$PortalName) 
	{
		Log-Error $fn ("Invalid input parameter type specified: 'PortalName' is not set. Aborting ...");
		throw($gotoFailure);
	}
	$UriAdmin = '{0}{1}' -f $Session.UriPortal, $biz_dfch_PS_Storebox_Api.UriBaseLocal;
	if($Api.StartsWith($UriAdmin)) 
	{ 
		$Api = $Api.Replace($UriAdmin, ''); 
	}
	if($Api.StartsWith($biz_dfch_PS_Storebox_Api.UriBaseLocal)) 
	{ 
		$Api = $Api.Replace($biz_dfch_PS_Storebox_Api.UriBaseLocal, ''); 
	}
	$Api = $Api.TrimStart('/');
	if(!$Api.StartsWith('webdav')) 
	{ 
		$Api = 'webdav/{0}' -f $Api; 
	}
	$Api = $Api.TrimStart('/');
	if([string]::IsNullOrEmpty($Api) -or [string]::IsNullOrWhiteSpace($Api)) 
	{
		Log-Error $fn "Invalid or empty input parameter specified: Api. Aborting ...";
		throw($gotoFailure);
	}
	switch($PSCmdlet.ParameterSetName) 
	{
		'd' 
		{
			$Method = 'GET';
		}
		'u' 
		{
			$Method = 'PUT';
			$fReturn = Test-Path -Path $Path;
			if($fReturn) 
			{ 
				$File = Get-Item -Path $Path;
			} 
			else 
			{
				$fReturn = Test-Path -LiteralPath $Path; 
			}
			if($fReturn -and !$File) 
			{
				$File = Get-Item -LiteralPath $Path;
			} 
			elseif($File) 
			{
				# good - we got a file object
				$Path = $File.FullName;
			} 
			else 
			{
				$e = New-CustomErrorRecord -m ("Unsupported ParameterSetName '{0}'." -f $PSCmdlet.ParameterSetName) -cat ObjectNotFound -o $Path;
				throw($gotoError);
			}
		}
		'del' 
		{
			$Method = 'DELETE';
		}
		'm' 
		{
			$Method = 'MOVE';
		}
		'c' 
		{
			$Method = 'COPY';
		}
		default 
		{
			$e = New-CustomErrorRecord -m ("Unsupported ParameterSetName '{0}'." -f $PSCmdlet.ParameterSetName) -cat InvalidArgument -o $PSCmdlet.ParameterSetName;
			throw($gotoError);
		}
	}
	
	if($PSCmdlet.ParameterSetName -eq 'd') 
	{
		$Uri = ('{0}{1}') -f $UriAdmin, $Api;
		[Uri] $UriUri = $Uri;
		if($AutomaticFileName) 
		{
			$Path = Join-Path -Path $Path -ChildPath $UriUri.Segments[-1];
		}
		$Uri = $UriUri.AbsoluteUri;
	}
	if($PSCmdlet.ParameterSetName -eq 'u')
	{
		[Uri] $UriPath = $Path;
		$Uri = ('{0}{1}') -f $UriAdmin, $Api;
		[Uri] $UriUri = $Uri;
		if($AutomaticFileName) 
		{
			$Uri = '{0}/{1}' -f $UriUri.AbsoluteUri.TrimEnd('/'), $UriPath.Segments[-1];
			[Uri] $UriUri = $Uri;
		}
		$Uri = $UriUri.AbsoluteUri;
	}
	if($PSCmdlet.ParameterSetName -eq 'del') 
	{
		$Uri = ('{0}{1}') -f $UriAdmin, $Api;
		[Uri] $UriUri = $Uri;
		$Uri = $UriUri.AbsoluteUri;
	}

	$QueryParameters = 'portalName={0}' -f $PortalName;
	$Uri = ('{0}?{1}' -f $Uri, $QueryParameters).TrimEnd('?');
	[Uri] $UriUri = $Uri;
	$Uri = $UriUri.AbsoluteUri;

	# create WebClient
	$wc = New-Object System.Net.WebClient;
	$wc.Encoding = [System.Text.Encoding]::UTF8;
	$wc.Headers.Clear();
	
	$wc.Headers.Add("Cookie", $WebRequestSession.Cookies.GetCookieHeader($uri))
	$wc.Headers.Add('Content-Type', 'application/octet-stream');
	$wc.Headers.Add('Accept', '*/*');
	$wc.Headers.Add('x-ctera-token', $biz_dfch_PS_Storebox_Api.SessionCookie.Value);
	$wc.Headers.Add('User-Agent', $WebRequestSession.UserAgent);

	$msg = "Invoking '{0}' '{1}' [on '{2}'] ..." -f $Method, $Uri, $Path;
	# Log-Debug $fn $msg;
	if(!$PSCmdlet.ShouldProcess($msg)) 
	{
		$fReturn = $false;
	} 
	else 
	{
		[string] $response = '';
		$Method = $Method.ToUpper();
		if($Method -eq 'GET') 
		{
			if($ListAvailable) 
			{
				$Method = 'PROPFIND';
				$response = $wc.UploadString($Uri, $Method, '');
				# Log-Debug $fn ("response count '{0}'" -f $r.multistatus.response.Count);
				# $response = $true;
			} 
			else 
			{
				$response = $wc.DownloadFile($Uri, $Path);
				$response = $true;
			}
		} elseif($Method -eq 'DELETE') 
		{
			$response = $wc.UploadString($Uri, $Method, '');
		} 
		else 
		{
			if($CreateDirectory) 
			{
				$Method = 'MKCOL';
				$response = $wc.UploadString($Uri, $Method, '');
			} 
			else 
			{
				$response = $wc.UploadFile($Uri, $Method, $Path);
			}
		}
		if(!$response) 
		{
			Log-Error $fn ("Invoking '{0}' '{1}' FAILED. '{2}'" -f $Method, $Uri, $error[0]);
			throw($gotoFailure);
		}
		# Log-Info $fn ("Invoking '{0}' '{1}' SUCCEEDED." -f $Method, $Uri);
		$OutputParameter = $response;
		$fReturn = $true;
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
	if(($datEnd - $datBegin).TotalMilliseconds -gt 1000)
	{
		Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]. ParameterSetName '{3}'. Api '{4}'" -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'), $PSCmdlet.ParameterSetName, $Api) -fac 2;
	}
}

} # function
if($MyInvocation.ScriptName) { Export-ModuleMember -Function Invoke-FileTransfer; }
 

# SIG # Begin signature block
# MIIaVQYJKoZIhvcNAQcCoIIaRjCCGkICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUAEPM5gsl/rCW6wgIISsd3TJ/
# bsCgghURMIIDdTCCAl2gAwIBAgILBAAAAAABFUtaw5QwDQYJKoZIhvcNAQEFBQAw
# VzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExEDAOBgNV
# BAsTB1Jvb3QgQ0ExGzAZBgNVBAMTEkdsb2JhbFNpZ24gUm9vdCBDQTAeFw05ODA5
# MDExMjAwMDBaFw0yODAxMjgxMjAwMDBaMFcxCzAJBgNVBAYTAkJFMRkwFwYDVQQK
# ExBHbG9iYWxTaWduIG52LXNhMRAwDgYDVQQLEwdSb290IENBMRswGQYDVQQDExJH
# bG9iYWxTaWduIFJvb3QgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQDaDuaZjc6j40+Kfvvxi4Mla+pIH/EqsLmVEQS98GPR4mdmzxzdzxtIK+6NiY6a
# rymAZavpxy0Sy6scTHAHoT0KMM0VjU/43dSMUBUc71DuxC73/OlS8pF94G3VNTCO
# XkNz8kHp1Wrjsok6Vjk4bwY8iGlbKk3Fp1S4bInMm/k8yuX9ifUSPJJ4ltbcdG6T
# RGHRjcdGsnUOhugZitVtbNV4FpWi6cgKOOvyJBNPc1STE4U6G7weNLWLBYy5d4ux
# 2x8gkasJU26Qzns3dLlwR5EiUWMWea6xrkEmCMgZK9FGqkjWZCrXgzT/LCrBbBlD
# SgeF59N89iFo7+ryUp9/k5DPAgMBAAGjQjBAMA4GA1UdDwEB/wQEAwIBBjAPBgNV
# HRMBAf8EBTADAQH/MB0GA1UdDgQWBBRge2YaRQ2XyolQL30EzTSo//z9SzANBgkq
# hkiG9w0BAQUFAAOCAQEA1nPnfE920I2/7LqivjTFKDK1fPxsnCwrvQmeU79rXqoR
# SLblCKOzyj1hTdNGCbM+w6DjY1Ub8rrvrTnhQ7k4o+YviiY776BQVvnGCv04zcQL
# cFGUl5gE38NflNUVyRRBnMRddWQVDf9VMOyGj/8N7yy5Y0b2qvzfvGn9LhJIZJrg
# lfCm7ymPAbEVtQwdpf5pLGkkeB6zpxxxYu7KyJesF12KwvhHhm4qxFYxldBniYUr
# +WymXUadDKqC5JlR3XC321Y9YeRq4VzW9v493kHMB65jUr9TU/Qr6cf9tveCX4XS
# QRjbgbMEHMUfpIBvFSDJ3gyICh3WZlXi/EjJKSZp4DCCBBQwggL8oAMCAQICCwQA
# AAAAAS9O4VLXMA0GCSqGSIb3DQEBBQUAMFcxCzAJBgNVBAYTAkJFMRkwFwYDVQQK
# ExBHbG9iYWxTaWduIG52LXNhMRAwDgYDVQQLEwdSb290IENBMRswGQYDVQQDExJH
# bG9iYWxTaWduIFJvb3QgQ0EwHhcNMTEwNDEzMTAwMDAwWhcNMjgwMTI4MTIwMDAw
# WjBSMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTEoMCYG
# A1UEAxMfR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0EgLSBHMjCCASIwDQYJKoZI
# hvcNAQEBBQADggEPADCCAQoCggEBAJTvZfi1V5+gUw00BusJH7dHGGrL8Fvk/yel
# NNH3iRq/nrHNEkFuZtSBoIWLZFpGL5mgjXex4rxc3SLXamfQu+jKdN6LTw2wUuWQ
# W+tHDvHnn5wLkGU+F5YwRXJtOaEXNsq5oIwbTwgZ9oExrWEWpGLmtECew/z7lfb7
# tS6VgZjg78Xr2AJZeHf3quNSa1CRKcX8982TZdJgYSLyBvsy3RZR+g79ijDwFwmn
# u/MErquQ52zfeqn078RiJ19vmW04dKoRi9rfxxRM6YWy7MJ9SiaP51a6puDPklOA
# dPQD7GiyYLyEIACDG6HutHQFwSmOYtBHsfrwU8wY+S47+XB+tCUCAwEAAaOB5TCB
# 4jAOBgNVHQ8BAf8EBAMCAQYwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQU
# Rtg+/9zjvv+D5vSFm7DdatYUqcEwRwYDVR0gBEAwPjA8BgRVHSAAMDQwMgYIKwYB
# BQUHAgEWJmh0dHBzOi8vd3d3Lmdsb2JhbHNpZ24uY29tL3JlcG9zaXRvcnkvMDMG
# A1UdHwQsMCowKKAmoCSGImh0dHA6Ly9jcmwuZ2xvYmFsc2lnbi5uZXQvcm9vdC5j
# cmwwHwYDVR0jBBgwFoAUYHtmGkUNl8qJUC99BM00qP/8/UswDQYJKoZIhvcNAQEF
# BQADggEBAE5eVpAeRrTZSTHzuxc5KBvCFt39QdwJBQSbb7KimtaZLkCZAFW16j+l
# IHbThjTUF8xVOseC7u+ourzYBp8VUN/NFntSOgLXGRr9r/B4XOBLxRjfOiQe2qy4
# qVgEAgcw27ASXv4xvvAESPTwcPg6XlaDzz37Dbz0xe2XnbnU26UnhOM4m4unNYZE
# IKQ7baRqC6GD/Sjr2u8o9syIXfsKOwCr4CHr4i81bA+ONEWX66L3mTM1fsuairtF
# Tec/n8LZivplsm7HfmX/6JLhLDGi97AnNkiPJm877k12H3nD5X+WNbwtDswBsI5/
# /1GAgKeS1LNERmSMh08WYwcxS2Ow3/MwggQoMIIDEKADAgECAgsEAAAAAAEvTuE1
# XDANBgkqhkiG9w0BAQUFADBXMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFs
# U2lnbiBudi1zYTEQMA4GA1UECxMHUm9vdCBDQTEbMBkGA1UEAxMSR2xvYmFsU2ln
# biBSb290IENBMB4XDTExMDQxMzEwMDAwMFoXDTE5MDQxMzEwMDAwMFowUTELMAkG
# A1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExJzAlBgNVBAMTHkds
# b2JhbFNpZ24gQ29kZVNpZ25pbmcgQ0EgLSBHMjCCASIwDQYJKoZIhvcNAQEBBQAD
# ggEPADCCAQoCggEBALJPFOcQvtcmcqs2l+9Tv0KEXljRiij8Q0ZvfihEUAt1XQDX
# PApEniBqpPdFSjdgo24/Evpt+rZGw2qjuAwnKAJXKNFQ92E5VbjD4SWGUjy/BR3X
# s5r4miQxSdWiqeLTkas+PHPv9inxyDXQMHt/TpKlBo+H4s71wWNmrBhpKsFeu1ro
# bpX/O4BinZnHxy9m1f1iGoJVWsb6QHeOyTA8G/DyNbhsWZz96dbKtEAe9wTK0Wep
# dOOlCFTZgzU7jowjDHW23oZKnho+ClBJOJzSqJC/mPrIjCsnEX4q+87eqa44kyL6
# puz7XGF2w0TWzAx+L20GgKJ0QLu3H/Q713NUH/MCAwEAAaOB+jCB9zAOBgNVHQ8B
# Af8EBAMCAQYwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQUCG7YtpyKv+0+
# 18N0XcyAH6gvUHowRwYDVR0gBEAwPjA8BgRVHSAAMDQwMgYIKwYBBQUHAgEWJmh0
# dHBzOi8vd3d3Lmdsb2JhbHNpZ24uY29tL3JlcG9zaXRvcnkvMDMGA1UdHwQsMCow
# KKAmoCSGImh0dHA6Ly9jcmwuZ2xvYmFsc2lnbi5uZXQvcm9vdC5jcmwwEwYDVR0l
# BAwwCgYIKwYBBQUHAwMwHwYDVR0jBBgwFoAUYHtmGkUNl8qJUC99BM00qP/8/Usw
# DQYJKoZIhvcNAQEFBQADggEBACJcxd099Atw2OP158WOCQG7sZY2XFoHrceoRElR
# JXquDaQZO5Kcz7lCJrs7bJfnx84RbWiR2o1t8VNNVDiMYfPIgnZpvoEyCzHDbMme
# IApYL/BI/n5IB6rXQ1iUc1QEMal4DTuMsHDBPX7XvS8qw+L1jwyQ3GulyL5oXl1t
# +HjSvkmVHhV4CJH7NMi+hK284MbdGNvzyvB7whQ8GLgDupU+IR4/YGl6f2oDno1K
# +fAoLDCEXuwmckKxbctkwxKM1oRLZ0F8sQMXeAnjrai2li2kfoADT4j3wWtaRhXN
# LBmL2HCc5S1JiGByqKQZUnBDXtrWRgOwaA4k70r2CyUk7yQwggSfMIIDh6ADAgEC
# AhIRIQaggdM/2HrlgkzBa1IJTgMwDQYJKoZIhvcNAQEFBQAwUjELMAkGA1UEBhMC
# QkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExKDAmBgNVBAMTH0dsb2JhbFNp
# Z24gVGltZXN0YW1waW5nIENBIC0gRzIwHhcNMTUwMjAzMDAwMDAwWhcNMjYwMzAz
# MDAwMDAwWjBgMQswCQYDVQQGEwJTRzEfMB0GA1UEChMWR01PIEdsb2JhbFNpZ24g
# UHRlIEx0ZDEwMC4GA1UEAxMnR2xvYmFsU2lnbiBUU0EgZm9yIE1TIEF1dGhlbnRp
# Y29kZSAtIEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsBeuotO2
# BDBWHlgPse1VpNZUy9j2czrsXV6rJf02pfqEw2FAxUa1WVI7QqIuXxNiEKlb5nPW
# kiWxfSPjBrOHOg5D8NcAiVOiETFSKG5dQHI88gl3p0mSl9RskKB2p/243LOd8gdg
# LE9YmABr0xVU4Prd/4AsXximmP/Uq+yhRVmyLm9iXeDZGayLV5yoJivZF6UQ0kcI
# GnAsM4t/aIAqtaFda92NAgIpA6p8N7u7KU49U5OzpvqP0liTFUy5LauAo6Ml+6/3
# CGSwekQPXBDXX2E3qk5r09JTJZ2Cc/os+XKwqRk5KlD6qdA8OsroW+/1X1H0+QrZ
# lzXeaoXmIwRCrwIDAQABo4IBXzCCAVswDgYDVR0PAQH/BAQDAgeAMEwGA1UdIARF
# MEMwQQYJKwYBBAGgMgEeMDQwMgYIKwYBBQUHAgEWJmh0dHBzOi8vd3d3Lmdsb2Jh
# bHNpZ24uY29tL3JlcG9zaXRvcnkvMAkGA1UdEwQCMAAwFgYDVR0lAQH/BAwwCgYI
# KwYBBQUHAwgwQgYDVR0fBDswOTA3oDWgM4YxaHR0cDovL2NybC5nbG9iYWxzaWdu
# LmNvbS9ncy9nc3RpbWVzdGFtcGluZ2cyLmNybDBUBggrBgEFBQcBAQRIMEYwRAYI
# KwYBBQUHMAKGOGh0dHA6Ly9zZWN1cmUuZ2xvYmFsc2lnbi5jb20vY2FjZXJ0L2dz
# dGltZXN0YW1waW5nZzIuY3J0MB0GA1UdDgQWBBTUooRKOFoYf7pPMFC9ndV6h9YJ
# 9zAfBgNVHSMEGDAWgBRG2D7/3OO+/4Pm9IWbsN1q1hSpwTANBgkqhkiG9w0BAQUF
# AAOCAQEAgDLcB40coJydPCroPSGLWaFNfsxEzgO+fqq8xOZ7c7tL8YjakE51Nyg4
# Y7nXKw9UqVbOdzmXMHPNm9nZBUUcjaS4A11P2RwumODpiObs1wV+Vip79xZbo62P
# lyUShBuyXGNKCtLvEFRHgoQ1aSicDOQfFBYk+nXcdHJuTsrjakOvz302SNG96QaR
# LC+myHH9z73YnSGY/K/b3iKMr6fzd++d3KNwS0Qa8HiFHvKljDm13IgcN+2tFPUH
# Cya9vm0CXrG4sFhshToN9v9aJwzF3lPnVDxWTMlOTDD28lz7GozCgr6tWZH2G01V
# e89bAdz9etNvI1wyR5sB88FRFEaKmzCCBK0wggOVoAMCAQICEhEhYHff2l3ILeBb
# QgbbK6elMjANBgkqhkiG9w0BAQUFADBRMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQ
# R2xvYmFsU2lnbiBudi1zYTEnMCUGA1UEAxMeR2xvYmFsU2lnbiBDb2RlU2lnbmlu
# ZyBDQSAtIEcyMB4XDTEyMDYwODA3MjQxMVoXDTE1MDcxMjEwMzQwNFowejELMAkG
# A1UEBhMCREUxGzAZBgNVBAgTElNjaGxlc3dpZy1Ib2xzdGVpbjEQMA4GA1UEBxMH
# SXR6ZWhvZTEdMBsGA1UECgwUZC1mZW5zIEdtYkggJiBDby4gS0cxHTAbBgNVBAMM
# FGQtZmVucyBHbWJIICYgQ28uIEtHMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
# CgKCAQEA0xuKJFsjlEbmGME2xhqJI/pbwYKNHcDWCXux2fcKw1FAfjLD002S/Njt
# iDTB6UPP0BDLPO2mpcx89sLWDdXVCAVGnnVe02VZnuMnIwn4ua5S/qeOP74TVZ3d
# SGxf6cbu8jsJAMJ/4kfhVm3wMhaAk4SWJPWoD1dAs8xRQS3BLRKzySL6x6veLW0S
# U6h/bMqUH6xE6HuZAVpA2H4ne1NK1JB/5m33/07/O33dJiZAnzi+h+/6gomBdtEd
# tyssOw9n9ocvc03HYMylUj8ONVk7ELQd4tOasBGd0AoLpynw0grZXS+x03VvnH10
# NiByLTesx6VAGMVsKMliznFnEuvSJwIDAQABo4IBVDCCAVAwDgYDVR0PAQH/BAQD
# AgeAMEwGA1UdIARFMEMwQQYJKwYBBAGgMgEyMDQwMgYIKwYBBQUHAgEWJmh0dHBz
# Oi8vd3d3Lmdsb2JhbHNpZ24uY29tL3JlcG9zaXRvcnkvMAkGA1UdEwQCMAAwEwYD
# VR0lBAwwCgYIKwYBBQUHAwMwPgYDVR0fBDcwNTAzoDGgL4YtaHR0cDovL2NybC5n
# bG9iYWxzaWduLmNvbS9ncy9nc2NvZGVzaWduZzIuY3JsMFAGCCsGAQUFBwEBBEQw
# QjBABggrBgEFBQcwAoY0aHR0cDovL3NlY3VyZS5nbG9iYWxzaWduLmNvbS9jYWNl
# cnQvZ3Njb2Rlc2lnbmcyLmNydDAdBgNVHQ4EFgQU8CeCuljXweXmtZyEAx+frc3x
# QLowHwYDVR0jBBgwFoAUCG7YtpyKv+0+18N0XcyAH6gvUHowDQYJKoZIhvcNAQEF
# BQADggEBAAd2aLYyofO6O8cc5l44ImMR5fi/bZhfZ7o/0kl3wxF5p4Rs5JdXx0RK
# cl0lYAR2QF6jyp5ZgDAFo9Pk5ucgEyr1evNh5QkIvp2Yxt7SIbk1Gy3bt+W7LOdF
# OOMzQ6q/uMBD8M7hTFJ2BdoRW2M8WTBAF1ZZ2o/gqrTBej/0mTcRb2gIJxGNULyF
# yNqWFc90YQ+FXQz5jBb9D/YkPp6QtaZjS5gmhu86X31Bb2Q7l+sVJc7zotJ606PT
# ORdsOy21ks2V3nWpugzBtJ0dV3MdKsvcGJ6uDbMrcD21MvmqZmVUmpUr5XYjQwH5
# nSj9Ego8lcJPdsYDcWBcCEybjUCLaOMxggSuMIIEqgIBATBnMFExCzAJBgNVBAYT
# AkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMScwJQYDVQQDEx5HbG9iYWxT
# aWduIENvZGVTaWduaW5nIENBIC0gRzICEhEhYHff2l3ILeBbQgbbK6elMjAJBgUr
# DgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMx
# DAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkq
# hkiG9w0BCQQxFgQUScE+8swBTHz92KRG1C4U1ccFPdgwDQYJKoZIhvcNAQEBBQAE
# ggEAvmwBTU2Y3Da+pSBFT8ZIO407OmMlZbmb14d/Y1ZyrKAdM8WVaFUWMD3cOqrm
# dYyP508zzLqWuj/YzV9mflIQUEJ9cX2oDBo69WlSY2j/ig1EMIuySPZju5jJgTYB
# i5C51N9lZm2e9KzSevQbYmzEn4S8kEMW+gVbTzxQOzEKJFwBX7W9hrWLqge8z6SA
# cYoEhxrcMKa2SGC5+2TM74LLT7SzT2oBag+g4IPyTbFKZOpsPKnIzI5J+NHs+4D3
# 7yMKVEBvkkWWj7OKM+1kGOCE2b8o/2L/Ztjg2+bPjvDlQTsg9/JaIcNSxK1k9qQt
# xObanwuRAEsd//Te7ofisd1sUKGCAqIwggKeBgkqhkiG9w0BCQYxggKPMIICiwIB
# ATBoMFIxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMSgw
# JgYDVQQDEx9HbG9iYWxTaWduIFRpbWVzdGFtcGluZyBDQSAtIEcyAhIRIQaggdM/
# 2HrlgkzBa1IJTgMwCQYFKw4DAhoFAKCB/TAYBgkqhkiG9w0BCQMxCwYJKoZIhvcN
# AQcBMBwGCSqGSIb3DQEJBTEPFw0xNTAzMTYwNTQ0NDZaMCMGCSqGSIb3DQEJBDEW
# BBR8LM/daTs8UKFC8C9LUuEnuB5kizCBnQYLKoZIhvcNAQkQAgwxgY0wgYowgYcw
# gYQEFLNjCLTUze1Pz71muVX647+xLCnmMGwwVqRUMFIxCzAJBgNVBAYTAkJFMRkw
# FwYDVQQKExBHbG9iYWxTaWduIG52LXNhMSgwJgYDVQQDEx9HbG9iYWxTaWduIFRp
# bWVzdGFtcGluZyBDQSAtIEcyAhIRIQaggdM/2HrlgkzBa1IJTgMwDQYJKoZIhvcN
# AQEBBQAEggEAixX6vKlAwWL9U8KFJZkb9OXDf8W5eKs5Nx7T4pjXo8MMtzC2hCt6
# G4zT1SjRL24VlcgSFKog7SOnY7CTaWMhgNKFX4GSkzrLT9bsZwfHKvG0nv9JMzkF
# dRZJloImlRwYwkAojmHlihB+v0y2IC2vm43d9jo62OW7TB1FdHZNKC3YN6Jqt1NO
# uQVulymFTO0v5oJPOOo2xcTFj6KYUXlsCb7KAxXwJ0LWx1RvNWAHtY9oCGjhs03q
# hhR1OOUis9QF3PfM4niUKwI90EYBhGbq7W5NnIjNafgTtp9rZNw12AMZohyO2wQd
# 53wEDK/emNSypZZya06AEFBp8Vu5C1vsew==
# SIG # End signature block
