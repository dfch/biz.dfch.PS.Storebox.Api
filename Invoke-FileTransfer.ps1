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

[DFCHECK] Give proper example. Gets all possible 'query' operations of the CTERA REST query service.

$xmlResponse = Invoke-FileTransfer;
$xmlResponse.QueryList.Link;


.EXAMPLE

[DFCHECK] Give proper example. Gets all CTERA Cells.

$xmlResponse = Invoke-FileTransfer -Api "query" -QueryParameters "type=cell";
$xmlResponse.QueryResultRecords.CellRecord;

.EXAMPLE

Upload file to Project folder

Invoke-FileTransfer -Upload MyProjectFolder -Path C:\myFile.txt -AutomaticFileName

.LINK

Online Version: http://dfch.biz/PS/Storebox/Api/Invoke-FileTransfer



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.
Requires a session to a CTERA host.

#>
[CmdletBinding(
	SupportsShouldProcess=$true,
	ConfirmImpact="High",
	HelpURI='http://dfch.biz/PS/Storebox/Api/Invoke-FileTransfer'
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
Export-ModuleMember -Function Invoke-FileTransfer;

