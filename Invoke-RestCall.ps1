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
  Param (
		[Parameter(Mandatory = $false, Position = 2)]
		[alias("s")]
		$Session = $biz_dfch_PS_Storebox_Api.Session
		,
		[ValidateSet('GET', 'POST', 'PUT', 'DELETE', 'PROPFIND')]
		[Parameter(Mandatory = $false, Position = 1)]
		[alias("m")]
		[string] $Method = 'GET'
		, 
		[Parameter(Mandatory = $false, Position = 0)]
		[alias("a")]
		[string] $Api = '/'
		,
		[Parameter(Mandatory = $false, Position = 3)]
		[alias("q")]
		[string] $QueryParameters = $null
		, 
		[Parameter(Mandatory = $false, Position = 4)]
		[alias("b")]
		[string] $Body = $null 
	) # Param
	BEGIN {
		$datBegin = [datetime]::Now;
		[string] $fn = $MyInvocation.MyCommand.Name;
		Log-Debug -fn $fn -msg ("CALL. Method '{0}'; Api: '{1}'." -f $Method, $Api) -fac 1;
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
			$UriPortal = $Session.UriPortal;
			$UriAdmin = '{0}{1}' -f $UriPortal, $biz_dfch_PS_Storebox_Api.UriBase;
			if([string]::IsNullOrEmpty($Api) -or [string]::IsNullOrWhiteSpace($Api)) {
				Log-Error $fn "Invalid or empty input parameter specified: Api. Aborting ...";
				throw($gotoFailure);
			} # if
			if([string]::Compare($Api, '/') -eq 0) {
				$Api = '';
			} # if
			
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

			Log-Debug $fn ("Invoking '{0}' '{1}' ..." -f $Method, $Uri);
			[string] $response = '';
			if('GET'.Equals($Method.ToUpper()) ) {
				$response = $wc.DownloadString($Uri);
			} else {
				$response = $wc.UploadString($Uri, $Method.ToUpper(), $Body);
			} # if
			#$(Format-ExtendedMethod -name add -p $RequestBody));
			if(!$response) {
				Log-Error $fn ("Invoking '{0}' '{1}' FAILED. '{2}'" -f $Method, $Uri, $error[0]);
				throw($gotoFailure);
			} # if
			Log-Debug $fn ("Invoking '{0}' '{1}' SUCCEEDED." -f $Method, $Uri);
			try {
				# try to convert the response to XML
				# on failure we are probably not authenticated or something else went wrong
				$xmlResult = [xml] $response;
				$OutputParameter = $response;
				$fReturn = $true;
			} # try
			catch {
				$e = New-CustomErrorRecord -m ("Executing '{0}' '{1}' FAILED as response is no XML. Maybe authentication expired?" -f $Method, $Uri) -cat InvalidData -o $response;
				throw($gotoError);
			} # catch
			
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
					$HttpWebResponse = $_.Exception.InnerException.Response;
					if($HttpWebResponse -is [System.Net.HttpWebResponse]) {
						$sr = New-Object System.IO.StreamReader($HttpWebResponse.GetResponseStream(), $true);
						$Content = $sr.ReadToEnd();
						Log-Error $fn ("{0}`n{1}" -f $_.Exception.InnerException.Message, $Content) -v;
					} # if
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
Set-Alias -Name Invoke-Command -Value Invoke-RestCall;
Export-ModuleMember -Function Invoke-RestCall -Alias Invoke-Command;

