function Exit-Server {
<#

.SYNOPSIS

Performs a logout from a StoreBox server.



.DESCRIPTION

Performs a logout from a StoreBox server.

For more information about Cmdlets see 'about_Functions_CmdletBindingAttribute'.



.OUTPUTS

This Cmdlet returns a Boolean parameter on success. On failure the Boolean contains $null.

For more information about output parameters see 'help about_Functions_OutputTypeAttribute'.



.INPUTS

See PARAMETER section for a description of input parameters.

For more information about input parameters see 'help about_Functions_Advanced_Parameters'.



.PARAMETER UriPortal

URI of the StoreBox server.



.PARAMETER Session

A session object of a logged in Storebox server.



.EXAMPLE

Perform a logout from a StoreBox server with a session object.

Exit-Server -UriPortal 'https://promo.ds01.swisscom.com' -Session $Session.



.EXAMPLE

Perform a logout from a StoreBox server with an implicit session object (the last session saved within the module).

Exit-Server -UriPortal 'https://promo.ds01.swisscom.com'.



.LINK

Online Version: http://dfch.biz/PS/Storebox/Api/Exit-Server

Enter-Ctera



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

#>
	[CmdletBinding(
		HelpURI='http://dfch.biz/PS/Storebox/Api/Exit-Server'
    )]
	[OutputType([Boolean])]
  Param (
		[Parameter(Mandatory = $false, Position = 0)]
		[alias("s")]
		[hashtable] $Session = (Get-Variable -Name $MyInvocation.MyCommand.Module.PrivateData.MODULEVAR -ValueOnly).Session
	) # Param
	BEGIN {
		$datBegin = [datetime]::Now;
		[string] $fn = $MyInvocation.MyCommand.Name;
		Log-Debug -fn $fn -msg "CALL. Session: '$Session'" -fac 1;
	}
  PROCESS {
		[boolean] $fReturn = $false;

		try {
			# Parameter validation
			if(!$Session) {
				Log-Warn $fn "Logout FAILED because the Session is empty." -v;
				throw($gotoFailure);
			} # if

			[string] $Uri = [string]::Format("{0}{1}logout", $Session.UriPortal, $biz_dfch_PS_Storebox_Api.UriBase);
			[string] $Body = '';
			$response = Invoke-WebRequest -UseBasicParsing -Method 'POST' -Uri $Uri -UserAgent $biz_dfch_PS_Storebox_Api.UserAgent -Body $Body -WebSession $Session.WebSession;
			if( (200 -ne $response.StatusCode) -or (0 -lt ($response.RawContentLength)) ) {
				Log-Critical $fn "Logout from UriPortal '$Session.UriPortal' FAILED with StatusCode '$($response.StatusCode)' and ContentLength '$($response.RawContentLength)'.";
				throw($gotoFailure);
			} # if
			Log-Info $fn "Logout from UriPortal '$Session.UriPortal' SUCCEEDED." -v;
			if( $Session.Equals($Session) ) {
				$Session = $null;
			} # if
			$fReturn = $true;
			$OutputParameter = $fReturn;

		} # try
		catch {
			if($gotoSuccess -eq $_.Exception.Message) {
					$fReturn = $true;
			} else {
				[string] $ErrorText = "catch [$($_.FullyQualifiedErrorId)]";
				$ErrorText += (($_ | fl * -Force) | Out-String);
				$ErrorText += (($_.Exception | fl * -Force) | Out-String);
				$ErrorText += (Get-PSCallStack | Out-String);
				
				if($_.Exception -is [System.Net.WebException]) {
					Log-Critical $fn "Logout from UriPortal '$UriPortal' FAILED [$_].";
					Log-Debug $fn $ErrorText -fac 3;
				} # [System.Net.WebException]
				else {
					Log-Error $fn $ErrorText -fac 3;
					if($gotoFailure -ne $_.Exception.Message) { Write-Verbose ("$fn`n$ErrorText"); }
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
		Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;
	} # END
} # function
Set-Alias -Name Exit-Storebox -Value 'Exit-Server';
Set-Alias -Name Exit- -Value 'Exit-Server';
Export-ModuleMember -Function Exit-Server -Alias Exit-;
