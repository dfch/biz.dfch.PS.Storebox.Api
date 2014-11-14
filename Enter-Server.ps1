function Enter-Server {
<#

.SYNOPSIS

Performs a login to a StoreBox server.



.DESCRIPTION

Performs a login to a StoreBox server.

For more information about Cmdlets see 'about_Functions_CmdletBindingAttribute'.



.OUTPUTS

This Cmdlet returns a WebRequestSession parameter. On failure the string contains $null.

For more information about output parameters see 'help about_Functions_OutputTypeAttribute'.



.INPUTS

See PARAMETER section for a description of input parameters.

For more information about input parameters see 'help about_Functions_Advanced_Parameters'.



.PARAMETER Uri

URI of the StoreBox server.



.PARAMETER Username

Username with which to perform login.



.PARAMETER Password

Plaintext password with which to perform login.



.PARAMETER Credentials

Encrypted credentials as [System.Management.Automation.PSCredential] with which to perform login.



.EXAMPLE

Perform a login to a StoreBox server with username and plaintext password.

Enter-ServerDeprecated -Uri 'https://promo.ds01.swisscom.com' -Username 'PeterLustig' -Password 'S0nnensch3!n'



.EXAMPLE

Perform a login to a StoreBox server with username and encrypted password.

Enter-ServerDeprecated -Uri 'https://promo.ds01.swisscom.com' -Credentials [PSCredentials]



.LINK

Online Version: http://dfch.biz/biz/dfch/PSStorebox/Api/Enter-ServerDeprecated/

Exit-Ctera



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

#>
[CmdletBinding(
	HelpURI='http://dfch.biz/biz/dfch/PSStorebox/Api/Enter-Server/'
)]
[OutputType([hashtable])]
Param (
	[Parameter(Mandatory = $true, Position = 0)]
	[alias("d")]
	[alias("DataStore")]
	[alias("UriPortal")]
	[string] $Uri = $biz_dfch_PS_Storebox_Api.UriPortal
	, 
	[Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'plain')]
	[alias("u")]
	[alias("user")]
	[string] $Username
	, 
	[Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'plain')]
	[alias("p")]
	[alias("pass")]
	[string] $Password
	, 
	[Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'secure')]
	[alias("cred")]
	[alias("Credentials")]
	[PSCredential] $Credential
	,
	[Parameter(Mandatory = $false)]
	[alias("g")]
	[alias("GlobalLogin")]
	[switch] $Global = $false
) # Param
	BEGIN {
		$datBegin = [datetime]::Now;
		[string] $fn = $MyInvocation.MyCommand.Name;
		Log-Debug -fn $fn -msg "CALL. Uri: '$Uri'; Username: '$Username'. ParameterSetName '$($PsCmdlet.ParameterSetName)'" -fac 1;
    [string] $PlaintextPassword = '';
		switch ($PsCmdlet.ParameterSetName) {
		"secure"  { 
				Log-Debug -fn $fn -msg "Received PSCredentials" -fac 1; 
				$PlaintextPassword = $Credential.GetNetworkCredential().Password;
				$Username = $Credential.UserName;
			}
		"plain"  {
			Log-Debug -fn $fn -msg "Received plaintext password." -fac 1; 
			$PlaintextPassword = $Password;
		}
		} # switch
	}
  PROCESS {
		[boolean] $fReturn = $false;

		try {
			# Parameter validation
            # N/A

            $cc = New-Object System.Net.CookieContainer;
			$WebSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession;
			[string] $Body = [string]::Format("j_username={0}&j_password={1}", ($Username | ConvertTo-UrlEncoded), ($PlaintextPassword | ConvertTo-UrlEncoded));
			[string] $UrlContentType = 'application/x-www-form-urlencoded';
			[Uri] $uriUri = $Uri;
			$Uri = $uriUri.AbsoluteUri;
			if ($Uri.EndsWith('/')) { $Uri = $Uri.Substring(0, $Uri.Length-1); }
			$UriOriginal = $Uri;
			if(!$Global) {
				$biz_dfch_PS_Storebox_Api.UriBase = '{0}api/' -f $biz_dfch_PS_Storebox_Api.UriBaseLocal;
                [string] $Uri = "{0}{1}" -f $Uri, $biz_dfch_PS_Storebox_Api.UriBaseLocal;
                $response = Invoke-WebRequest -UseBasicParsing -Method 'GET' -Uri $Uri -UserAgent $biz_dfch_PS_Storebox_Api.UserAgent -MaximumRedirection 1 -SessionVariable WebSession -ErrorAction:SilentlyContinue;
                #$Uri = $response.Headers.Location;
                #[System.Uri] $UriSkin = $Uri;
                #for($c = 0; $c -lt ($UriSkin.Segments.Count -1); $c++) { $UriLoginRelative += $UriSkin.Segments[$c]; }
				#[string] $Uri = [string]::Format("{0}{1}j_security_check", $Uri, $UriLoginRelative);
                [string] $Uri = "{0}{1}j_security_check" -f $Uri, $biz_dfch_PS_Storebox_Api.UriBaseLocal;
			} else {
				$biz_dfch_PS_Storebox_Api.UriBase = '{0}api/' -f $biz_dfch_PS_Storebox_Api.UriBaseGlobal;
				[string] $Uri = [string]::Format("{0}{1}login", $Uri, $biz_dfch_PS_Storebox_Api.UriBase);
			} # if

			$response = Invoke-WebRequest -UseBasicParsing -Method 'POST' -Uri $Uri -UserAgent $biz_dfch_PS_Storebox_Api.UserAgent -Body $Body -MaximumRedirection 1 -WebSession $WebSession -ErrorAction:SilentlyContinue;
            if($response.Headers.ContainsKey('Location') -or !$response.Headers.ContainsKey('Set-Cookie')) {
			    $e = New-CustomErrorRecord -m ("Login to  '{0}' with user '{1}' FAILED." -f $UriOriginal, $Username) -cat AuthenticationError -o $response;
			    throw($gotoError);
            } # if
			$Cookies = $WebSession.Cookies.GetCookies($Uri);
			$cc.SetCookies($Uri,$Cookies);
			Log-Notice $fn ("Login to Uri '{0}' with Username '{1}' SUCCEEDED." -f $UriOriginal, $Username) -v;
			[hashtable] $Session = @{};
			$Session.UriPortal = $UriOriginal;
			$Session.WebSession = $WebSession;
			$biz_dfch_PS_Storebox_Api.Session = $Session;
            $biz_dfch_PS_Storebox_Api.SessionCookie = $Cookies;
			if(!$Global) {
				[xml] $PortalName = Invoke-Command "name"
				$biz_dfch_PS_Storebox_Api.PortalName = $PortalName.val;
			} # if
			$OutputParameter = $Session;
			$fReturn = $true;

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
					Log-Critical $fn "Login to Uri '$Uri' with Username '$Username' FAILED [$_].";
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
            # N/A
		} # finally
		return $OutputParameter;
  } # PROCESS
	END {
		$datEnd = [datetime]::Now;
		Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;
	} # END
} # function
Set-Alias -Name Enter-Storebox -Value 'Enter-Server';
Set-Alias -Name Connect- -Value 'Enter-Server';
Set-Alias -Name Enter- -Value 'Enter-Server';
Export-ModuleMember -Function Enter-Server -Alias Connect-, Enter-, Enter-Storebox;
