Set-Variable MODULE_NAME -Option 'Constant' -Value 'biz.dfch.PS.Storebox.Api';
Set-Variable MODULE_URI_BASE -Option 'Constant' -Value 'http://dfch.biz/PS/Storebox/Api/';

Set-Variable gotoSuccess -Option 'Constant' -Value 'biz.dfch.System.Exception.gotoSuccess' -Confirm:$false -WhatIf:$false;
Set-Variable gotoFailure -Option 'Constant' -Value 'biz.dfch.System.Exception.gotoFailure' -Confirm:$false -WhatIf:$false;
Set-Variable gotoNotFound -Option 'Constant' -Value 'biz.dfch.System.Exception.gotoNotFound' -Confirm:$false -WhatIf:$false;
Set-Variable gotoError -Option 'Constant' -Value 'biz.dfch.System.Exception.gotoError' -Confirm:$false -WhatIf:$false;

# Load module configuration file
[string] $ModuleConfigFile = $MyInvocation.MyCommand.Name.Replace('.psm1', '.xml');
[string] $ModuleConfigurationPathAndFile = $PSCommandPath.Replace('.psm1', '.xml');
if($true -eq (Test-Path -Path $ModuleConfigurationPathAndFile)) {
	if($true -ne (Test-Path variable:$($MODULE_NAME.Replace('.', '_')))) {
		Set-Variable -Name $MODULE_NAME.Replace('.', '_') -Value (Import-Clixml -Path $ModuleConfigurationPathAndFile) -Description "The array contains the public configuration properties of the module '$MODULE_NAME'.`n$MODULE_URI_BASE" ;
	} # if()
} # if()
if($true -ne (Test-Path variable:$($MODULE_NAME.Replace('.', '_')))) {
	Write-Error "Could not find module configuration file '$ModuleConfigFile' in 'ENV:PSModulePath'.`nAborting module import...";
	break; # Aborts loading module.
} # if()
Export-ModuleMember -Variable $MODULE_NAME.Replace('.', '_');

$null = Add-Type -AssemblyName System.Net;
$null = Add-Type -AssemblyName System.Web;

function Enter-Ctera {
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

Enter-CteraDeprecated -Uri 'https://promo.ds01.swisscom.com' -Username 'PeterLustig' -Password 'S0nnensch3!n'



.EXAMPLE

Perform a login to a StoreBox server with username and encrypted password.

Enter-CteraDeprecated -Uri 'https://promo.ds01.swisscom.com' -Credentials [PSCredentials]



.LINK

Online Version: http://dfch.biz/PS/Storebox/Api/Enter-CteraDeprecated/

Exit-Ctera



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

#>
	[CmdletBinding(
		HelpURI='http://dfch.biz/PS/Storebox/Api/Enter-Ctera/'
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
				[xml] $PortalName = Invoke-CteraCommand "name"
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
Set-Alias -Name Enter-Storebox -Value Enter-Ctera;
Export-ModuleMember -Function Enter-Ctera -Alias Enter-Storebox;

function Enter-CteraDeprecated {
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



.PARAMETER UriPortal

URI of the StoreBox server.



.PARAMETER Username

Username with which to perform login.



.PARAMETER Password

Plaintext password with which to perform login.



.PARAMETER Credentials

Encrypted credentials as [System.Management.Automation.PSCredential] with which to perform login.



.EXAMPLE

Perform a login to a StoreBox server with username and plaintext password.

Enter-CteraDeprecated -UriPortal 'https://promo.ds01.swisscom.com' -Username 'PeterLustig' -Password 'S0nnensch3!n'



.EXAMPLE

Perform a login to a StoreBox server with username and encrypted password.

Enter-CteraDeprecated -UriPortal 'https://promo.ds01.swisscom.com' -Username 'PeterLustig' -Credentials [PSCredentials]



.LINK

Online Version: http://dfch.biz/PS/Storebox/Api/Enter-CteraDeprecated/

Exit-Ctera



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

#>
	[CmdletBinding(
		HelpURI='http://dfch.biz/PS/Storebox/Api/Enter-CteraDeprecated/'
    )]
	[OutputType([hashtable])]
  Param (
		[Parameter(Mandatory = $true, Position = 0)]
		[alias("d")]
		[alias("DataStore")]
		[string] $UriPortal = $biz_dfch_PS_Storebox_Api.UriPortal
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
		[alias("s")]
		[alias("cred")]
		[alias("Credentials")]
		[PSCredential] $Credential
		,
		[Parameter(Mandatory = $false)]
		[switch] $NonAdminLogin = $false
	) # Param
	BEGIN {
		$datBegin = [datetime]::Now;
		[string] $fn = $MyInvocation.MyCommand.Name;
		Log-Debug -fn $fn -msg "CALL. UriPortal: '$UriPortal'; Username: '$Username'. ParameterSetName '$($PsCmdlet.ParameterSetName)'" -fac 1;
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
			if($NonAdminLogin) {
				$biz_dfch_PS_Storebox_Api.UriBase = $biz_dfch_PS_Storebox_Api.UriBaseLocal;
				[string] $Uri = [string]::Format("{0}{1}j_security_check", $UriPortal, '/ServicesPortal/');
			} else {
				$biz_dfch_PS_Storebox_Api.UriBase = $biz_dfch_PS_Storebox_Api.UriBaseGlobal;
				[string] $Uri = [string]::Format("{0}{1}login", $UriPortal, $biz_dfch_PS_Storebox_Api.UriBase);
			} # if
			[string] $Body = [string]::Format("j_username={0}&j_password={1}", $Username, $PlaintextPassword);
			[string] $UrlContentType = 'application/x-www-form-urlencoded';
			$WebSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession;
			
			$null = Add-Type -AssemblyName System.Net;

			$response = Invoke-WebRequest -UseBasicParsing -Method 'POST' -Uri $Uri -ContentType $UrlContentType -UserAgent $biz_dfch_PS_Storebox_Api.UserAgent -Body $Body -WebSession $WebSession;
			if(200 -ne $response.StatusCode) {
				Log-Critical $fn "Login to UriPortal '$UriPortal' with Username '$Username' FAILED with StatusCode '$response.StatusCode'.";
				throw($gotoFailure);
			} # if
			Log-Info $fn "Login to UriPortal '$UriPortal' with Username '$Username' SUCCEEDED." -v;
			[hashtable] $Session = @{};
			$Session.UriPortal = $UriPortal;
			$Session.WebSession = $WebSession;
			$biz_dfch_PS_Storebox_Api.Session = $Session;
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
					Log-Critical $fn "Login to UriPortal '$UriPortal' with Username '$Username' FAILED [$_].";
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
#Export-ModuleMember -Function Enter-CteraDeprecated;

function Exit-Ctera {
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

Exit-Ctera -UriPortal 'https://promo.ds01.swisscom.com' -Session $Session.



.EXAMPLE

Perform a logout from a StoreBox server with an implicit session object (the last session saved within the module).

Exit-Ctera -UriPortal 'https://promo.ds01.swisscom.com'.



.LINK

Online Version: http://dfch.biz/PS/Storebox/Api/Exit-Ctera

Enter-Ctera



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

#>
	[CmdletBinding(
		HelpURI='http://dfch.biz/PS/Storebox/Api/Exit-Ctera'
    )]
	[OutputType([Boolean])]
  Param (
		[Parameter(Mandatory = $false, Position = 0)]
		[alias("s")]
		[hashtable] $Session =  $biz_dfch_PS_Storebox_Api.Session
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
			if( $Session.Equals($biz_dfch_PS_Storebox_Api.Session) ) {
				$biz_dfch_PS_Storebox_Api.Session = $null;
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
Set-Alias -Name Exit-Storebox -Value Exit-Ctera;
Export-ModuleMember -Function Exit-Ctera -Alias Exit-Storebox;

function Select-CteraPortal {
<#

.SYNOPSIS

Selects a Storebox Portal on a  given UriPortal.



.DESCRIPTION

Selects a Storebox Portal on a  given UriPortal.

For more information about Cmdlets see 'about_Functions_CmdletBindingAttribute'.



.OUTPUTS

This Cmdlet returns an XML document parameter. On failure the string contains $null.

For more information about output parameters see 'help about_Functions_OutputTypeAttribute'.



.INPUTS

See PARAMETER section for a description of input parameters.

For more information about input parameters see 'help about_Functions_Advanced_Parameters'.



.PARAMETER UriPortal

URI of the StoreBox server.



.PARAMETER PortalName

The name of a Storebox Portal to select.



.EXAMPLE

Perform a login to a StoreBox server with username and plaintext password.

Select-CteraPortal -UriPortal 'https://promo.ds01.swisscom.com' -Username 'PeterLustig' -Password 'S0nnensch3!n'



.EXAMPLE

Perform a login to a StoreBox server with username and encrypted password.

Select-CteraPortal -UriPortal 'https://promo.ds01.swisscom.com' -Username 'PeterLustig' -Credentials [PSCredentials]



.LINK

Online Version: http://dfch.biz/PS/Storebox/Api/Select-CteraPortal/
Enter-Ctera



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

#>
	[CmdletBinding(
		HelpURI='http://dfch.biz/PS/Storebox/Api/Select-CteraPortal/'
    )]
	[OutputType([Microsoft.PowerShell.Commands.WebResponseObject])]
  Param (
		[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'portal')]
		[alias("p")]
		[alias("portal")]
		[alias("PortalName")]
		[string] $Name, 
		[Parameter(Mandatory = $false, Position = 1)]
		[alias("s")]
		[hashtable] $Session = $biz_dfch_PS_Storebox_Api.Session, 
		[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'admin')]
		[alias("a")]
		[alias("AdminPortal")]
		[switch] $Global
	) # Param
	BEGIN {
		$datBegin = [datetime]::Now;
		[string] $fn = $MyInvocation.MyCommand.Name;
		Log-Debug -fn $fn -msg "CALL. UriPortal: '$UriPortal'; Name: '$Name'. ParameterSetName '$($PsCmdlet.ParameterSetName)'" -fac 1;
    switch ($PsCmdlet.ParameterSetName) {
    "admin"  {
			$Name = '';
		}
		} # switch
	}
  PROCESS {
		[boolean] $fReturn = $false;
		# TODO: set data type

		try {
			# Parameter validation
			if(!$Session) {
				Log-Critical $fn "Unable to perform operation because the Session is empty.";
				throw($gotoFailure);
			} # if

			$Body = "<val>{0}</val>" -f $Name;
            $response = Invoke-CteraCommand -Method PUT -Api currentPortal -Body $Body;

			if($response) {
                $e = New-CustomErrorRecord -m ("Selecting '{0}' on '{1}' FAILED. [{2}]" -f $Name, $Session.UriPortal, $response) -cat InvalidData -o $response;
				throw($gotoError);
			} # if
			if($Global) {
				$biz_dfch_PS_Storebox_Api.PortalName = '';
				Log-Info $fn ("Selecting Global AdminPortal on '{0}' SUCCEEDED." -f $Session.UriPortal);
			} else {
				$biz_dfch_PS_Storebox_Api.PortalName = $Name;
				Log-Info $fn ("Selecting Name '{0}' on '{1}' SUCCEEDED." -f $Name, $Session.UriPortal);
			} # if/else
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
					Log-Critical $fn "Operation on '$Uri' FAILED [$_].";
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
		Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;
	} # END
} # function
Set-Alias -Name Select-Storebox -Value Select-CteraPortal;
Export-ModuleMember -Function Select-CteraPortal -Alias Select-Storebox;

function Select-CteraPortalDeprecated {
<#

.SYNOPSIS

Selects a Storebox Portal on a  given UriPortal.



.DESCRIPTION

Selects a Storebox Portal on a  given UriPortal.

For more information about Cmdlets see 'about_Functions_CmdletBindingAttribute'.



.OUTPUTS

This Cmdlet returns an XML document parameter. On failure the string contains $null.

For more information about output parameters see 'help about_Functions_OutputTypeAttribute'.



.INPUTS

See PARAMETER section for a description of input parameters.

For more information about input parameters see 'help about_Functions_Advanced_Parameters'.



.PARAMETER UriPortal

URI of the StoreBox server.



.PARAMETER PortalName

The name of a Storebox Portal to select.



.EXAMPLE

Perform a login to a StoreBox server with username and plaintext password.

Select-CteraPortalDeprecated -UriPortal 'https://promo.ds01.swisscom.com' -Username 'PeterLustig' -Password 'S0nnensch3!n'



.EXAMPLE

Perform a login to a StoreBox server with username and encrypted password.

Select-CteraPortalDeprecated -UriPortal 'https://promo.ds01.swisscom.com' -Username 'PeterLustig' -Credentials [PSCredentials]



.LINK

Online Version: http://dfch.biz/PS/Storebox/Api/Select-CteraPortalDeprecated/
Enter-Ctera



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

#>
	[CmdletBinding(
		HelpURI='http://dfch.biz/PS/Storebox/Api/Select-CteraPortalDeprecated/'
    )]
	[OutputType([Microsoft.PowerShell.Commands.WebResponseObject])]
  Param (
		[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'portal')]
		[alias("p")]
		[alias("portal")]
		[alias("PortalName")]
		[string] $Name, 
		[Parameter(Mandatory = $false, Position = 1)]
		[alias("s")]
		[hashtable] $Session = $biz_dfch_PS_Storebox_Api.Session, 
		[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'admin')]
		[alias("a")]
		[switch] $Global
	) # Param
	BEGIN {
		$datBegin = [datetime]::Now;
		[string] $fn = $MyInvocation.MyCommand.Name;
		Log-Debug -fn $fn -msg "CALL. UriPortal: '$UriPortal'; Name: '$Name'. ParameterSetName '$($PsCmdlet.ParameterSetName)'" -fac 1;
    switch ($PsCmdlet.ParameterSetName) {
    "admin"  {
			$Name = '';
		}
		} # switch
	}
  PROCESS {
		[boolean] $fReturn = $false;
		# TODO: set data type

		try {
			# Parameter validation
			if(!$Session) {
				Log-Critical $fn "Unable to perform operation because the Session is empty.";
				throw($gotoFailure);
			} # if

			[string] $Uri = [string]::Format("{0}{1}currentPortal", $Session.UriPortal, $biz_dfch_PS_Storebox_Api.UriBase);
			[string] $Body = [string]::Format("<val>{0}</val>", $Name);
			[string] $UrlContentType = 'application/x-www-form-urlencoded';

			$response = Invoke-WebRequest -UseBasicParsing -Method 'PUT' -Uri $Uri -ContentType $UrlContentType -UserAgent $biz_dfch_PS_Storebox_Api.UserAgent -Body $Body -WebSession $Session.WebSession;
			if(200 -ne $response.StatusCode) {
				Log-Critical $fn "Selecting Name '$Name' on UriPortal '$Session.UriPortal' FAILED with StatusCode '$response.StatusCode'.";
				throw($gotoFailure);
			} # if
			if($Global) {
				$biz_dfch_PS_Storebox_Api.PortalName = '';
				Log-Info $fn "Selecting Global AdminPortal on UriPortal '$Session.UriPortal' SUCCEEDED.";
			} else {
				$biz_dfch_PS_Storebox_Api.PortalName = $Name;
				Log-Info $fn "Selecting Name '$Name' on UriPortal '$Session.UriPortal' SUCCEEDED.";
			} # if/else
			$OutputParameter = $response;
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
					Log-Critical $fn "Operation on '$Uri' FAILED [$_].";
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
#Set-Alias -Name Select-SBPortal -Value Select-CteraPortalDeprecated;
#Set-Alias -Name Select-Storebox -Value Select-CteraPortalDeprecated;
#Export-ModuleMember -Function Select-CteraPortalDeprecated -Alias Select-SBPortal, Select-Storebox;

function Get-StoreboxUser {
<#

.SYNOPSIS

Gets Storebox Users from currently selected Portal on a given UriPortal.



.DESCRIPTION

Gets Storebox Users from currently selected Portal on a given UriPortal.

For more information about Cmdlets see 'about_Functions_CmdletBindingAttribute'.



.OUTPUTS

This Cmdlet returns a HtmlWebResponseObject parameter. On failure the string contains $null.

For more information about output parameters see 'help about_Functions_OutputTypeAttribute'.



.INPUTS

See PARAMETER section for a description of input parameters.

For more information about input parameters see 'help about_Functions_Advanced_Parameters'.



.PARAMETER UriPortal

URI of the StoreBox server.



.PARAMETER PortalName

The name of a Storebox Portal to select.



.EXAMPLE

Perform a login to a StoreBox server with username and plaintext password.

Get-StoreboxUser -UriPortal 'https://promo.ds01.swisscom.com' -Username 'PeterLustig' -Password 'S0nnensch3!n'



.EXAMPLE

Perform a login to a StoreBox server with username and encrypted password.

Get-StoreboxUser -UriPortal 'https://promo.ds01.swisscom.com' -Username 'PeterLustig' -Credentials [PSCredentials]



.LINK

Online Version: http://dfch.biz/PS/Storebox/Api/Get-StoreboxUser/
Enter-Ctera



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

#>
	[CmdletBinding(
		HelpURI='http://dfch.biz/PS/Storebox/Api/Get-StoreboxUser/'
    )]
	[OutputType([xml], ParameterSetName = 'list')]
	[OutputType([System.Collections.Hashtable], ParameterSetName = 'user')]
  Param (
		[Parameter(Mandatory = $false, Position = 1, ParameterSetName = 'user')]
		[alias("p")]
		[alias("portal")]
		[string] $PortalName = $biz_dfch_PS_Storebox_Api.PortalName, 
		[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'user')]
		[alias("u")]
		[alias("user")]
		[string] $Username, 
		[Parameter(Mandatory = $false, Position = 1, ParameterSetName = 'list')]
		[alias("f")]
		[string] $Filter, 
		[Parameter(Mandatory = $false)]
		[alias("s")]
		[hashtable] $Session = $biz_dfch_PS_Storebox_Api.Session, 
		[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'list')]
		[alias("l")]
		[switch] $ListAvailable 
		) # Param
	BEGIN {
		$datBegin = [datetime]::Now;
		[string] $fn = $MyInvocation.MyCommand.Name;
		Log-Debug -fn $fn -msg "CALL. UriPortal: '$Session.UriPortal'; PortalName: '$PortalName'. Filter: '$Filter'. ParameterSetName '$($PsCmdlet.ParameterSetName)'" -fac 1;
	}
  PROCESS {
		[boolean] $fReturn = $false;

		try {
			# Parameter validation
			if(!$Session) {
				Log-Critical $fn "Unable to perform operation because the Session is empty.";
				throw($gotoFailure);
			} # if
			
			# Check if portal is already selected. If not select it.
			if($PortalName -ne ($biz_dfch_PS_Storebox_Api.PortalName)) {
				if(!$PortalName) {
					Log-Critical $fn "Unable to perform operation on UriPortal '$Session.UriPortal' because the PortalName is empty and no portal has been selected yet. Try Select-Portal first.";
					throw($gotoFailure);
				} # if
				$null = Select-CteraPortal -PortalName $PortalName;
			} # if

			if($ListAvailable) {
				[string] $Uri = [string]::Format("{0}{1}users", $Session.UriPortal, $biz_dfch_PS_Storebox_Api.UriBase);
				[string] $Body = '';

				$response = Invoke-WebRequest -UseBasicParsing -Method 'GET' -Uri $Uri -UserAgent $biz_dfch_PS_Storebox_Api.UserAgent -WebSession $Session.WebSession;
				if(200 -ne $response.StatusCode) {
					Log-Critical $fn "Getting users on PortalName '$PortalName' on UriPortal '$Session.UriPortal' FAILED with StatusCode '$response.StatusCode'.";
					throw($gotoFailure);
				} # if
				$xmlResponse = [xml] $response.Content;
				$nObj = $xmlResponse.list.obj.Length;
				if(0 -ge $nObj) {
					Log-Warn $fn "Getting available users on PortalName '$PortalName' on UriPortal '$Session.UriPortal' retrieved 0 portals." -v;
					throw($gotoFailure);
				} # if
				if($Filter) {
					for ($i = $xmlResponse.List.obj.Length-1; $i -gt 0; $i--) { 
						$obj = $xmlResponse.List.obj[$i]; 
						$obj.SelectNodes("att[@id = 'name']") | ForEach-Object { 
							if(!($_.val -match $Filter) ) { 
								$xmlResponse.List.RemoveChild($obj);
								return; 
							} # if
						} #forEach-Object
					} # for
				} # if
				if(0 -ge $xmlResponse.list.obj.Length) {
					Log-Warn $fn "Filtering after getting '$nObj' users on PortalName '$PortalName' on UriPortal '$Session.UriPortal' left 0 portals." -v;
					throw($gotoFailure);
				} # if
				[xml] $OutputParameter = $xmlResponse;
				$fReturn = $true;

			} else {
				[string] $Uri = [string]::Format("{0}{1}users/{2}", $Session.UriPortal, $biz_dfch_PS_Storebox_Api.UriBase, $Username);
				[string] $Body = '';

				$response = Invoke-WebRequest -UseBasicParsing -Method 'GET' -Uri $Uri -UserAgent $biz_dfch_PS_Storebox_Api.UserAgent -WebSession $Session.WebSession;
				if(200 -ne $response.StatusCode) {
					Log-Critical $fn "Getting Username '$Username' on PortalName '$PortalName' on UriPortal '$Session.UriPortal' FAILED with StatusCode '$response.StatusCode'.";
					throw($gotoFailure);
				} # if

				$xmlResponse = [xml] $response.Content;
				[hashtable] $PortalAttributes = @{};
				$null = $xmlResponse.obj.att | % { 
					[string] $id = $_.id;
					[string] $val = $_.val;
					$null = $PortalAttributes.Add($id, $val); 
				}
				$OutputParameter = $PortalAttributes;

#				[xml] $OutputParameter = [xml] $response.Content;
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
				
				if($_.Exception -is [System.Net.WebException]) {
					Log-Critical $fn "Operation on '$Uri' FAILED [$_].";
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
Export-ModuleMember -Function Get-StoreboxUser;

function Get-StoreboxPortal {
<#

.SYNOPSIS

Gets Storebox Portals from currently selected Portal on a given UriPortal.



.DESCRIPTION

Gets Storebox Portals from currently selected Portal on a given UriPortal.

For more information about Cmdlets see 'about_Functions_CmdletBindingAttribute'.



.OUTPUTS

This Cmdlet returns an XML document parameter. On failure the string contains $null.

For more information about output parameters see 'help about_Functions_OutputTypeAttribute'.



.INPUTS

See PARAMETER section for a description of input parameters.

For more information about input parameters see 'help about_Functions_Advanced_Parameters'.



.PARAMETER UriPortal

URI of the StoreBox server.



.PARAMETER PortalName

The name of a Storebox Portal to select.



.EXAMPLE

Perform a login to a StoreBox server with username and plaintext password.

Get-StoreboxPortal -UriPortal 'https://promo.ds01.swisscom.com' -Username 'PeterLustig' -Password 'S0nnensch3!n'



.EXAMPLE

Perform a login to a StoreBox server with username and encrypted password.

Get-StoreboxPortal -UriPortal 'https://promo.ds01.swisscom.com' -Username 'PeterLustig' -Credentials [PSCredentials]



.LINK

Online Version: http://dfch.biz/PS/Storebox/Api/Get-StoreboxPortal/
Enter-Ctera



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

#>
	[CmdletBinding(
		HelpURI='http://dfch.biz/PS/Storebox/Api/Get-StoreboxPortal/'
    )]
	[OutputType([xml], ParameterSetName = 'list')]
	[OutputType([System.Collections.Hashtable], ParameterSetName = 'portal')]
    Param (
		[Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'portal')]
		[alias("p")]
		[alias("portal")]
		[string] $PortalName = $biz_dfch_PS_Storebox_Api.PortalName, 
		[Parameter(Mandatory = $false, Position = 1, ParameterSetName = 'list')]
		[alias("f")]
		[string] $Filter, 
		[Parameter(Mandatory = $false, Position = 3)]
		[alias("s")]
		[hashtable] $Session = $biz_dfch_PS_Storebox_Api.Session, 
		[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'list')]
		[alias("l")]
		[switch] $ListAvailable, 
		[Parameter(Mandatory = $false)]
		[alias("x")]
		[switch] $ReturnAsXml
		) # Param
    BEGIN {
		$datBegin = [datetime]::Now;
		[string] $fn = $MyInvocation.MyCommand.Name;
		Log-Debug -fn $fn -msg "CALL. UriPortal: '$Session.UriPortal'; PortalName: '$PortalName'. Filter: '$Filter'. ReturnAsXml: '$ReturnAsXml'. ParameterSetName '$($PsCmdlet.ParameterSetName)'" -fac 1;
	}
    PROCESS {
		[boolean] $fReturn = $false;

		try {
			# Parameter validation
			if(!$Session) {
				Log-Critical $fn "Unable to perform operation because the Session is empty.";
				throw($gotoFailure);
			} # if
			
			if($ListAvailable) {
				$null = Select-CteraPortal -AdminPortal;

				[string] $Uri = [string]::Format("{0}{1}portals", $Session.UriPortal, $biz_dfch_PS_Storebox_Api.UriBase);
				[string] $Body = '';
				$response = Invoke-WebRequest -UseBasicParsing -Method 'GET' -Uri $Uri -UserAgent $biz_dfch_PS_Storebox_Api.UserAgent -WebSession $Session.WebSession;
				if(200 -ne $response.StatusCode) {
					Log-Critical $fn "Getting available portals on UriPortal '$Session.UriPortal' FAILED with StatusCode '$response.StatusCode'.";
					throw($gotoFailure);
				} # if
				$xmlResponse = [xml] $response.Content;
				$nObj = $xmlResponse.list.obj.Length;
				if(0 -ge $nObj) {
					Log-Warn $fn "Getting available portals on UriPortal '$Session.UriPortal' retrieved 0 portals." -v;
					throw($gotoFailure);
				} # if
				if($Filter) {
					for ($i = $xmlResponse.List.obj.Length-1; $i -gt 0; $i--) { 
						$obj = $xmlResponse.List.obj[$i]; 
						$obj.SelectNodes("att[@id = 'name']") | ForEach-Object { 
							if(!($_.val -match $Filter) ) { 
								$xmlResponse.List.RemoveChild($obj);
								return; 
							} # if
						} #forEach-Object
					} # for
#					$xmlResponse.list.obj | % { 
#						$sb = $_.att | Where { 
#						$_.id -eq 'Name'}; 
#						$sbName = $sb.val; 
#						if(!($sbName -match $Filter)) { 
#							$null = $xmlResponse.list.RemoveChild($_); 
#						} # if
#					} # foreach where
				} # if
				if(0 -ge $xmlResponse.list.obj.Length) {
					Log-Warn $fn "Filtering after getting '$nObj' portals on UriPortal '$Session.UriPortal' left 0 portals." -v;
					throw($gotoFailure);
				} # if
				$OutputParameter = $xmlResponse;
				$fReturn = $true;
			} else {
				
				# Check if portal is already selected. If not select it.
				if($PortalName -ne ($biz_dfch_PS_Storebox_Api.PortalName)) {
					if(!$PortalName) {
						Log-Critical $fn "Unable to perform operation on UriPortal '$Session.UriPortal' because the PortalName is empty and no portal has been selected yet. Try Select-Portal first.";
						throw($gotoFailure);
					} # if
					$null = Select-CteraPortal -PortalName $PortalName;
					if(!$null) {
						throw($gotoFailure);
					} # if
				} # if
				# Get currently selected portal
				[string] $Uri = [string]::Format("{0}{1}", $Session.UriPortal, $biz_dfch_PS_Storebox_Api.UriBase);
				[string] $Body = '';
				$response = Invoke-WebRequest -Method 'GET' -Uri $Uri -UserAgent $biz_dfch_PS_Storebox_Api.UserAgent -WebSession $Session.WebSession;
				if(200 -ne $response.StatusCode) {
					Log-Critical $fn "Getting PortalName '$PortalName' on UriPortal '$Session.UriPortal' FAILED with StatusCode '$response.StatusCode'.";
					throw($gotoFailure);
				} # if
				$xmlResponse = [xml] $response.Content;
				if($ReturnAsXml) {
					$OutputParameter = $xmlResponse;
				} else {
					[hashtable] $PortalAttributes = @{};
					#$xmlResponse.obj.att | % { $PortalAttributes.Add($_.id -as [string], $_.val -as [string]); }
					$null = $xmlResponse.obj.att | % { 
						[string] $id = $_.id;
						[string] $val = $_.val;
						$null = $PortalAttributes.Add($id, $val); 
					}
					$OutputParameter = $PortalAttributes;
				} # if
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
				
				if($_.Exception -is [System.Net.WebException]) {
					Log-Critical $fn "Operation on '$Uri' FAILED [$_].";
					Log-Debug $fn $ErrorText -fac 3;
					if($gotoFailure -ne $_.Exception.Message) { Write-Verbose ("$fn`n$ErrorText"); }
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
Export-ModuleMember -Function Get-StoreboxPortal;

function Get-StoreboxEntity {
<#

.SYNOPSIS

Gets Storebox Portals from currently selected Portal on a given UriPortal.



.DESCRIPTION

Gets Storebox Portals from currently selected Portal on a given UriPortal.

For more information about Cmdlets see 'about_Functions_CmdletBindingAttribute'.



.OUTPUTS

This Cmdlet returns an XML document parameter. On failure the string contains $null.

For more information about output parameters see 'help about_Functions_OutputTypeAttribute'.



.INPUTS

See PARAMETER section for a description of input parameters.

For more information about input parameters see 'help about_Functions_Advanced_Parameters'.



.PARAMETER UriPortal

URI of the StoreBox server.



.PARAMETER PortalName

The name of a Storebox Portal to select.



.EXAMPLE

Perform a login to a StoreBox server with username and plaintext password.

Get-StoreboxEntity -UriPortal 'https://promo.ds01.swisscom.com' -Username 'PeterLustig' -Password 'S0nnensch3!n'



.EXAMPLE

Perform a login to a StoreBox server with username and encrypted password.

Get-StoreboxEntity -UriPortal 'https://promo.ds01.swisscom.com' -Username 'PeterLustig' -Credentials [PSCredentials]



.LINK

Online Version: http://dfch.biz/PS/Storebox/Api/Get-StoreboxEntity/
Enter-Ctera



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

#>
	[CmdletBinding(
		HelpURI='http://dfch.biz/PS/Storebox/Api/Get-StoreboxEntity/'
    )]
	[OutputType([xml], ParameterSetName = 'list')]
	[OutputType([System.Collections.Hashtable], ParameterSetName = 'portal')]
  Param (
		[Parameter(Mandatory = $false, Position = 1)]
		[alias("p")]
		[alias("portal")]
		[string] $PortalName = $biz_dfch_PS_Storebox_Api.PortalName, 
		[Parameter(Mandatory = $false, Position = 0)]
		[alias("e")]
		[string] $Entity = '', 
		[Parameter(Mandatory = $false, Position = 2)]
		[alias("s")]
		[hashtable] $Session = $biz_dfch_PS_Storebox_Api.Session, 
		[Parameter(Mandatory = $false, Position = 3)]
		[alias("x")]
		[switch] $ReturnAsXml
		) # Param
	BEGIN {
		$datBegin = [datetime]::Now;
		[string] $fn = $MyInvocation.MyCommand.Name;
		Log-Debug -fn $fn -msg "CALL. Entity: '$Entity'. UriPortal: '$Session.UriPortal'; PortalName: '$PortalName'. ReturnAsXml: '$ReturnAsXml'. ParameterSetName '$($PsCmdlet.ParameterSetName)'" -fac 1;
	}
  PROCESS {
		[boolean] $fReturn = $false;

		try {
			# Parameter validation
			if(!$Session) {
				Log-Critical $fn "Unable to perform operation because the Session is empty.";
				throw($gotoFailure);
			} # if
			
			[string] $Uri = [string]::Format("{0}{1}/{2}", $Session.UriPortal, $biz_dfch_PS_Storebox_Api.UriBase, $Entity);
			[string] $Body = '';
			$response = Invoke-WebRequest -UseBasicParsing -Method 'GET' -Uri $Uri -UserAgent $biz_dfch_PS_Storebox_Api.UserAgent -WebSession $Session.WebSession;
			if(200 -ne $response.StatusCode) {
				Log-Critical $fn "Getting Uri '$Uri' FAILED with StatusCode '$response.StatusCode'.";
				throw($gotoFailure);
			} # if
			Write-Host $respone;
			if(0 -ge $response.ContentLength) {
				Log-Warn $fn "Getting Uri '$Uri' returned no data.";
			} # if
			$xmlResponse = [xml] $response.Content;
			$OutputParameter = $xmlResponse;
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
					Log-Critical $fn "Operation on '$Uri' FAILED [$_].";
					Log-Debug $fn $ErrorText -fac 3;
					if($gotoFailure -ne $_.Exception.Message) { Write-Verbose ("$fn`n$ErrorText"); }
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
Export-ModuleMember -Function Get-StoreboxEntity;

function Format-CteraExtendedMethod {
	[CmdletBinding(
		HelpURI='http://dfch.biz/PS/Storebox/Api/Format-CteraExtendedMethod/'
    )]
	[OutputType([string])]
	Param (
		[ValidateSet("add", "delete", "validate", "addProject", "searchMembers", 'generateReport', 'queryLogs', 'getStatistics', 'getDefaultPlan', 'getInvitations', 'invite', 'listSnapshots', 'consolidateSnapshots', 'getTemplates', 'getTemplate', 'customizeTemplate', 'unCustomizeTemplate')]
		[Parameter(Mandatory = $true, Position = 0)]
		[alias("n")]
		[alias("MethodName")]
		[string] $Name
		,
		[Parameter(Mandatory = $false, Position = 1)]
		[alias("p")]
		[alias("params")]
		[string] $Parameters = '<!-- -->'
		,
		[Parameter(Mandatory = $false)]
		[switch] $Verify = $false
	)
	BEGIN {
	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
	Log-Debug -fn $fn -msg ("CALL. Name: '{0}'; Parameters.Length: '{1}'; Verify: '{2}'; " -f $Name, $Parameters.Length, $Verify) -fac 1;
	}
	PROCESS {
	[boolean] $fReturn = $false;

	$fReturn = $false;
	$OutputParameter = $null;

	try {
	# Parameter validation
	# N/A

	$Type = "db";
	if($Name -eq "consolidateSnapshots") { $Type = "user-defined"; }
	if($Name -eq "listSnapshots") { $Type = "user-defined"; }
	if($Name -eq "searchMembers") { $Type = "user-defined"; }
	if($Name -eq "delete") { $Type = "user-defined"; }
	if($Name -eq "addProject") { $Type = "user-defined"; }
	if($Name -eq "queryLogs") { $Type = "user-defined"; }
	if($Name -eq "generateReport") { $Type = "user-defined"; }
	if($Name -eq "getTemplates") { $Type = "user-defined"; }
	if($Name -eq "getTemplate") { $Type = "user-defined"; }
	if($Name -eq "customizeTemplate") { $Type = "user-defined"; }
	if($Name -eq "unCustomizeTemplate") { $Type = "user-defined"; }

	$CteraMethodTemplate = '<obj><att id="type"><val>{0}</val></att><att id="name"><val>{1}</val></att><att id="param">{2}</att></obj>';
	[xml] $xmlBody = ($CteraMethodTemplate -f $Type, $Name, $Parameters);
	$OutputParameter = $xmlBody.OuterXml;
			
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
} # Format-CteraExtendedMethod
Set-Alias -Name Format-SBExtendedMethod -Value Format-CteraExtendedMethod;
Export-ModuleMember -Function Format-CteraExtendedMethod;

function Invoke-CteraRestCall {
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

$xmlResponse = Invoke-CteraRestCall;
$xmlResponse.QueryList.Link;


.EXAMPLE

[DFCHECK] Give proper example. Gets all CTERA Cells.

$xmlResponse = Invoke-CteraRestCall -Api "query" -QueryParameters "type=cell";
$xmlResponse.QueryResultRecords.CellRecord;


.LINK

Online Version: http://dfch.biz/PS/Storebox/Api/Invoke-CteraRestCall



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.
Requires a session to a CTERA host.

#>
	[CmdletBinding(
		HelpURI='http://dfch.biz/PS/Storebox/Api/Invoke-CteraRestCall'
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
			#$(Format-CteraExtendedMethod -name add -p $RequestBody));
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
Set-Alias -Name Invoke-CteraCommand -Value Invoke-CteraRestCall;
Export-ModuleMember -Function Invoke-CteraRestCall -Alias Invoke-CteraCommand;

function New-CteraAclEntry {
[CmdletBinding(
	HelpURI='http://dfch.biz/PS/Storebox/Utilities/New-CteraAclEntry'
)]
[OutputType([hashtable])]
Param (
    [Parameter(Mandatory = $true, Position = 0)]
    [alias("n")]
    [string] $Name
    ,
    [ValidateSet('localUser', 'localGroup')]
    [Parameter(Mandatory = $false, Position = 1)]
    [alias("t")]
    [string] $Type = 'localUser'
    ,
    [ValidateSet('ReadWrite', 'ReadOnly')]
    [Parameter(Mandatory = $false, Position = 2)]
    [alias("p")]
    [string] $Permission = 'ReadOnly'
)
BEGIN {
	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
} # BEGIN
PROCESS {
	if([string]::IsNullOrEmpty($Name) -or [string]::IsNullOrWhiteSpace($Name)) {
        $e = New-CustomErrorRecord -m "Invalid argument 'Name' specified. Object is empty." -cat InvalidArgument -o $Name;
		Log-Debug $fn $e.Exception.Message;
		$OutputParameter = $null;
        $PSCmdlet.ThrowTerminatingError($e);
	} else {
		$OutputParameter = @{ ('{0}\{1}' -f $Type, $Name) = $Permission };
	} # if
	return $OutputParameter;
} # PROCESS
END {
} # END

} # New-CteraAclEntry
Export-ModuleMember -Function New-CteraAclEntry;

function ConvertFrom-CteraObjAtt {
[CmdletBinding(
	HelpURI='http://dfch.biz/PS/Storebox/Utilities/ConvertFrom-CteraObjAtt'
)]
[OutputType([string])]
Param (
    [Parameter(ValueFromPipeline = $true, Mandatory = $true, Position = 0)]
    [alias("o")]
    $InputObject
    ,
    [Parameter(Mandatory = $true, Position = 1)]
    [alias("id")]
    [string] $idAttribute
    ,
    [ValidateSet('Value', 'List')]
    [Parameter(Mandatory = $false, Position = 2)]
    [alias("t")]
    [string] $Type = 'Value'
)
BEGIN {
	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
} # BEGIN
PROCESS {
	if([string]::IsNullOrEmpty($idAttribute) -or [string]::IsNullOrWhiteSpace($idAttribute)) {
        $e = New-CustomErrorRecord -m "Invalid argument 'idAttribute' specified. Object is empty." -cat InvalidArgument -o $idAttribute;
		Log-Debug $fn $e.Exception.Message;
		$OutputParameter = $null;
        $PSCmdlet.ThrowTerminatingError($e);
	} # if
	if($InputObject -is [string]) {
		[xml] $xml = $InputObject;
	} elseif($InputObject -is [System.Xml.XmlElement]) {
		$xml = $InputObject;
	} else {
        $e = New-CustomErrorRecord -m ("Invalid argument 'InputObject' specified. Object has invalid type: '{0}'." -f $InputObject.GetType()) -cat InvalidType -o $InputObject;
		Log-Debug $fn $e.Exception.Message;
		$OutputParameter = $null;
        $PSCmdlet.ThrowTerminatingError($e);
	} # if
	$fReturn = $false;
	$OutputParameter = $null;
	foreach($a in $xml.att) { 
		if($a.id -eq $idAttribute) { 
			if($Type -eq 'List') {
				$OutputParameter = $a.list.OuterXml;
			} else {
				$OutputParameter = '{0}' -f $a.val;
			} # if
			$fReturn = $true;
			break;
		} # if
	} # foreach
	if(!$fReturn) { $OutputParameter = $null; }
	return $OutputParameter;
} # PROCESS
END {
} # END

} # ConvertFrom-CteraObjAtt
Export-ModuleMember -Function ConvertFrom-CteraObjAtt;

function New-CteraProjectAclRule {
[CmdletBinding(
	HelpURI='http://dfch.biz/PS/Storebox/Utilities/New-CteraProjectAclRule'
)]
[OutputType([string])]
Param (
    [Parameter(Mandatory = $true, Position = 0)]
    [alias("acl")]
    [hashtable[]] $AclEntries
)
BEGIN {
	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
} # BEGIN
PROCESS {
    if($AclEntries -isnot [Array]) {
        $e = New-CustomErrorRecord -m "Invalid argument 'AclEntries' specified. Object has invalid type." -cat InvalidArgument -o $AclEntries;
		Log-Debug $fn $e.Exception.Message;
		$OutputParameter = $null;
        $PSCmdlet.ThrowTerminatingError($e);
	} # if

    [xml] $l = "<list id='bogusAttribute' />";
	foreach($AclEntry in $AclEntries) {
        if($AclEntry.Count -gt 1) {
            $e = New-CustomErrorRecord -m "Invalid entry 'AclEntry' found. Object has 'Count' of more than '1'." -cat InvalidType -o $AclEntry;
		    Log-Debug $fn $e.Exception.Message;
		    $OutputParameter = $null;
            $PSCmdlet.ThrowTerminatingError($e);
        } #
        # Extract user/group, name
        $AclEntry.GetEnumerator() | % { 

            $x = $l.CreateElement('obj');
            $x.SetAttribute('class', 'ProjectACLRule');

            $UserObject = $_.Name; 
            # Split '\'
            $fReturn = $UserObject -match '^([^\\]+)\\([^$]+)$';
            if(!$fReturn) {
                $e = New-CustomErrorRecord (-m "Invalid data in 'AclEntry' found. Property 'Name' [Group/User] contains no '\': '{0}'." -f $UserObject) -cat InvalidData -o $UserObject;
		        Log-Debug $fn $e.Exception.Message;
		        $OutputParameter = $null;
                $PSCmdlet.ThrowTerminatingError($e);
            } # if
            $Scope = $Matches[1];
            $User = $Matches[2];
            # Check permission
            $Permission = $_.Value;
            if([string]::IsNullOrEmpty($Permission) -or [string]::IsNullOrWhiteSpace($Permission)) {
                $e = New-CustomErrorRecord -m "Invalid data in 'AclEntry' found. Property 'Value' [Permission] contains no data." -cat InvalidData -o $Permission;
		        Log-Debug $fn $e.Exception.Message;
		        $OutputParameter = $null;
                $PSCmdlet.ThrowTerminatingError($e);
            } # if

            # Get uid for user or group
            if($Scope -eq 'localUser') {
                [xml] $r = Invoke-CteraCommand ('users/{0}' -f $User);
            } elseif($Scope -eq 'localGroup') {
                [xml] $r = Invoke-CteraCommand ('localGroups/{0}' -f $User);
            } else {
                $e = New-CustomErrorRecord -m ("Invalid data in 'AclEntry' found. Property 'Name' [Scope] contains invalid data: '{0}'." -f $Scope) -cat InvalidData -o $Scope;
		        Log-Debug $fn $e.Exception.Message;
		        $OutputParameter = $null;
                $PSCmdlet.ThrowTerminatingError($e);
            } # if
			if(!$r) {
                $e = New-CustomErrorRecord -m ("Invalid data in 'AclEntry' found. Property 'Name' [Scope: '{0}'] contains invalid data: '{1}'." -f $Scope, $User) -cat InvalidData -o $User;
		        Log-Debug $fn $e.Exception.Message;
		        $OutputParameter = $null;
                $PSCmdlet.ThrowTerminatingError($e);
			} # if
            # Create 
            $uid = ConvertFrom-CteraObjAtt $r.obj uid;
            $new = $l.CreateElement('att');
            $new.SetAttribute('id', 'name');
            $new.set_InnerXML('<val>{0}</val>' -f $User);
            $null = $x.AppendChild($new);
            $new = $l.CreateElement('att');
            $new.SetAttribute('id', 'uid');
            $new.set_InnerXML('<val>{0}</val>' -f $uid);
            $null = $x.AppendChild($new);
            $new = $l.CreateElement('att');
            $new.SetAttribute('id', 'type');
            $new.set_InnerXML('<val>{0}</val>' -f $Scope);
            $null = $x.AppendChild($new);
            $new = $l.CreateElement('att');
            $new.SetAttribute('id', 'permissions');
            $new.set_InnerXML('<val>{0}</val>' -f $Permission);
            $null = $x.AppendChild($new);
        } # GetEnum
        $null = $l.list.AppendChild($x);
    } # foreach
    $null = $l.list.RemoveAttribute('id');
    $OutputParameter = $l.OuterXml;

	return $OutputParameter;
} # PROCESS
END {
    # N/A
} # END

} # New-CteraProjectAclRule
Export-ModuleMember -Function New-CteraProjectAclRule;

function New-CteraListVal {
[CmdletBinding(
	HelpURI='http://dfch.biz/PS/Storebox/Api/New-CteraListVal/'
)]
[OutputType([string])]
PARAM (
	[Parameter(ValueFromPipeline = $true, Mandatory = $true, Position = 0)]
	[string[]] $Values
)
BEGIN {
	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
	#Log-Debug -fn $fn -msg ("CALL. ExceptionString: '{0}'; idError: '{1}'; ErrorCategory: '{2}'; " -f $ExceptionString, $idError, $ErrorCategory) -fac 1;

	$fReturn = $false;
	$OutputParameter = $null;
	$OutputParameter = '<list>'
} # BEGIN
PROCESS {
try {
	# Parameter validation
	# N/A

	if($_) {
		$OutputParameter += ('<val>{0}</val>' -f $Values);
	} else {
		foreach($Value in $Values) {
			$OutputParameter += ('<val>{0}</val>' -f $Value);
		} # foreach
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
			if($gotoFailure -ne $_.Exception.Message) { Write-Verbose ("$fn`n$ErrorText"); }
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
} # finally
} # PROCESS
END {
	$OutputParameter += '</list>'
	return $OutputParameter;

	$datEnd = [datetime]::Now;
	#Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;
} # END

} # function
Export-ModuleMember -Function New-CteraListVal;

function New-CteraLocalGroup {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium",
	HelpURI='http://dfch.biz/PS/Storebox/Api/New-CteraLocalGroup/'
)]
[OutputType([string])]
PARAM (
	[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Mandatory = $true, Position = 0)]
	[string] $Name
	,
	[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Mandatory = $false, Position = 1)]
	[alias("Value")]
	[string] $Description = ''
)
BEGIN {
	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
	Log-Debug -fn $fn -msg ("CALL. ExceptionString: '{0}'; idError: '{1}'; ErrorCategory: '{2}'; " -f $ExceptionString, $idError, $ErrorCategory) -fac 1;
	
	$fReturn = $false;
	$OutputParameter = $null;

	$UriPortalGroupDefaults = 'PortalGroup';
	[xml] $Defaults = Get-CteraDefaultsObj -Name 'PortalGroup';
	if(!$Defaults) {
		$e = New-CustomErrorRecord -m ("Cannot create group as retreiving of default parameters '{0}' FAILED." -f $UriPortalGroupDefaults) -cat ConnectionError -o $UriPortalGroupDefaults;
		Log-Error $fn $e.Exception.Message;
		$PSCmdlet.ThrowTerminatingError($e);
	} # if

} # BEGIN
PROCESS {
try {
	# Parameter validation
	# N/A

	if($_) {
		if($Name -eq 'System.Collections.Hashtable') {
			$e = New-CustomErrorRecord -m ("Parameter 'Name' is of type [hashtable]. When using a hashtable as pipeline input use [hashtable].GetEnumerator() as pipeline input.") -cat InvalidArgument -o $Name;
			Log-Error $fn $e.Exception.Message;
			$PSCmdlet.ThrowTerminatingError($e);
		} # if
	} # if

	# set parameters for new group
	$n = $Defaults.obj.SelectSingleNode("//att[@id = 'name']");
	$n.set_InnerXML( "<val>{0}</val>" -f [System.Web.HttpUtility]::HtmlEncode($Name));
	$n = $Defaults.obj.SelectSingleNode("//att[@id = 'description']");
	$n.set_InnerXML( "<val>{0}</val>" -f [System.Web.HttpUtility]::HtmlEncode($Description));
	
	# Format API call
	$Body = Format-CteraExtendedMethod -Name add -Parameters $Defaults.OuterXml;
	# Create group
	$UriLocalGroups = 'localGroups'
	if($PSCmdlet.ShouldProcess($Name)) {
	    $r = Invoke-CteraCommand -Method 'POST' -Api $UriLocalGroups -Body $Body;
        if(!$r) {
		    $e = New-CustomErrorRecord -m ("Creating localGroup '{0}' FAILED." -f $Name) -cat NotSpecified -o $Body;
		    throw($gotoError);
        } # if
        $tmpLocalGroup = ConvertFrom-CteraObj -XmlString ("<obj class='#uri'><att id='#uri'>{0}</att></obj>" -f $r);
        Log-Info $fn ("Creating localGroup '{0}' [{1}] SUCCEEDED." -f $Name, $tmpLocalGroup.'#uri') -Verbose:$Verbose;
	    $OutputParameter += $tmpLocalGroup.Clone();
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
} # PROCESS
END {
	return $OutputParameter;

	$datEnd = [datetime]::Now;
	Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;
} # END

} # function
Export-ModuleMember -Function New-CteraLocalGroup;

function Remove-CteraLocalGroup2 {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="High",
	HelpURI='http://dfch.biz/PS/Storebox/Api/Remove-CteraLocalGroup2/'
)]
[OutputType([string])]
PARAM (
	[Parameter(ValueFromPipeline = $true, Mandatory = $true, Position = 0, ParameterSetName = 'name')]
	[string] $Name
	,
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'id')]
	[alias('uid')]
	[int] $id
)
BEGIN {
	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
	Log-Debug -fn $fn -msg ("CALL. ExceptionString: '{0}'; idError: '{1}'; ErrorCategory: '{2}'; " -f $ExceptionString, $idError, $ErrorCategory) -fac 1;
	
	$fReturn = $false;
	$OutputParameter = $null;
	$UriLocalGroups = 'localGroups'
	
	[xml] $localGroups = Invoke-CteraCommand "localGroups";
	if(!$localGroups) {
		$e = New-CustomErrorRecord -m ("Resolving group names to ids FAILED." -f $UriPortalGroupDefaults) -cat ConnectionError -o $UriPortalGroupDefaults;
		Log-Error $fn $e.Exception.Message;
		$PSCmdlet.ThrowTerminatingError($e);
	} # if
	$UserIdRelation = @{};
	$RelName = '';
	$RelId = '';
	foreach($obj in $localGroups.list.obj) {
		$RelName = ConvertFrom-CteraObjAtt -InputObject $obj -idAttribute 'name';
		$RelId = ConvertFrom-CteraObjAtt -InputObject $obj -idAttribute 'uid';
		$UserIdRelation.Add($RelName, $RelId);
	} # foreach
	$RelName = '';
	$RelId = '';

} # BEGIN
PROCESS {
try {
	# Parameter validation
	# N/A

	if($PSCmdlet.ParameterSetName -eq 'name') {
		if(!$UserIdRelation.ContainsKey($Name)) {
			$e = New-CustomErrorRecord -m ("Deleting group FAILED. Group '{0}' not found." -f $Name) -cat ObjectNotFound -o $UriPortalGroupDefaults;
			Log-Error $fn $e.Exception.Message;
			$PSCmdlet.ThrowTerminatingError($e);
		} # if
		$id = $UserIdRelation.Item($Name);

	    # Delete group
	    $Uri = "objs/{0}" -f $id;
	    Log-Info $fn ("Deleting localGroup '{0}' [{1}] ..." -f $Name, $id) -Verbose:$true;
	    if($PSCmdlet.ShouldProcess($Name)) {
		    [xml] $r = Invoke-CteraCommand -Method 'DELETE' -Api $Uri;
            $OutputParameter += $r.OuterXml;
	    } # if
	} elseif($PSCmdlet.ParameterSetName -eq 'id') {
		$fReturn = $UserIdRelation.Values | ? { $_ -eq $id }
		if(!$fReturn) {
			$e = New-CustomErrorRecord -m ("Deleting group FAILED. Group id '{0}' not found." -f $id) -cat ObjectNotFound -o $UriPortalGroupDefaults;
			Log-Error $fn $e.Exception.Message;
			$PSCmdlet.ThrowTerminatingError($e);
		} # if

	    # Delete group
	    $Uri = "objs/{0}" -f $id;
	    Log-Info $fn ("Deleting localGroup '{0}' [{1}] ..." -f $Name, $id) -Verbose:$true;
	    if($PSCmdlet.ShouldProcess($id)) {
		    [xml] $r = Invoke-CteraCommand -Method 'DELETE' -Api $Uri;
            $OutputParameter += $r.OuterXml;
		    Log-Debug $fn ("OutputParameter: '{0}'" -f ($OutputParameter.OuterXml | Format-Xml));
	    } # if
    } else {
        $e = New-CustomErrorRecord -m ("Invalid ParameterSetName encountered: '{0}'." -f $PSCmdlet.ParameterSetName) -cat InvalidArgument -o $PSCmdlet.ParameterSetName;
		Log-Error $fn $e.Exception.Message;
		$PSCmdlet.ThrowTerminatingError($e);
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
			if($gotoFailure -ne $_.Exception.Message) { Write-Verbose ("$fn`n$ErrorText"); }
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
} # finally
} # PROCESS
END {
	return $OutputParameter;

	$datEnd = [datetime]::Now;
	Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;
} # END

} # function
Export-ModuleMember -Function Remove-CteraLocalGroup2;

function Remove-CteraLocalGroup {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="High",
	HelpURI='http://dfch.biz/PS/Storebox/Api/Remove-CteraLocalGroup/'
)]
PARAM (
	[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Mandatory = $true, Position = 0, ParameterSetName = 'name')]
	$Name
	,
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'id')]
	[alias('uid')]
	[int] $id
)
BEGIN {
try {
	# Parameter validation
	# N/A
	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
	Log-Debug -fn $fn -msg ("CALL. ParameterSetName: '{0}'" -f $PSCmdlet.ParameterSetName) -fac 1;
	
	$fReturn = $false;
	$OutputParameter = $null;
	$UriLocalGroups = 'localGroups'
	
	$slocalGroups = Invoke-CteraCommand $UriLocalGroups;
	$olocalGroups = ConvertFrom-CteraObjList -XmlString $slocalGroups;
	if(!$olocalGroups) {
		$e = New-CustomErrorRecord -m ("Retrieving and converting group names FAILED.") -cat ConnectionError -o $olocalGroups;
		throw($gotoError);
	} # if
	if($ListAvailable) {
		$OutputParameter = $olocalGroups.Clone();
		throw($gotoSuccess);
	} # if
    $OutputParameter = @();
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

} # BEGIN
PROCESS {
try {
	# Parameter validation
	# N/A

	if($PSCmdlet.ParameterSetName -eq 'name') {
        $fReturn = $false;
        $olocalGroup = $null;
        foreach($olocalGroup in $olocalGroups) { 
            if($olocalGroup.name -eq $Name -or $olocalGroup.name -eq $Name.name) { $fReturn = $true; break; } # if
        } # foreach
		if(!$fReturn) {
            if($Name -is [string]) {
			    $e = New-CustomErrorRecord -m ("Deleting group FAILED. Group '{0}' not found." -f $Name) -cat ObjectNotFound -o $olocalGroups;
            } else {
			    $e = New-CustomErrorRecord -m ("Deleting group FAILED. Group '{0}' not found." -f $Name.name) -cat ObjectNotFound -o $olocalGroups;
            } # if
            throw($gotoError);
		} # if
	    # Delete group
	    $Uri = "objs/{0}" -f $olocalGroup.uid;
	    Log-Info $fn ("Deleting localGroup '{0}' [{1}] ..." -f $olocalGroup.Name, $olocalGroup.uid) -Verbose:$true;
	    if($PSCmdlet.ShouldProcess($olocalGroup.Name)) {
		    $r = Invoke-CteraCommand -Method 'DELETE' -Api $Uri;
            $oLocalGroupDelete = ConvertFrom-CteraObj -XmlString $r;
            $OutputParameter += $oLocalGroupDelete.Clone();
		    #Log-Debug $fn ("OutputParameter: '{0}'" -f ($OutputParameter.OuterXml | Format-Xml));
	    } # if
        #$OutputParameter += $olocalGroup.Clone();
	} elseif($PSCmdlet.ParameterSetName -eq 'id') {
        $fReturn = $false;
        $olocalGroup = $null;
        foreach($olocalGroup in $olocalGroups) { 
            if($olocalGroup.uid -eq $id) { $fReturn = $true; break; } # if
        } # foreach
		if(!$fReturn) {
			$e = New-CustomErrorRecord -m ("Getting localGroup FAILED. Group id '{0}' not found." -f $id) -cat ObjectNotFound -o $olocalGroups;
            throw($gotoError);
		} # if
	    # Delete group
	    $Uri = "objs/{0}" -f $olocalGroup.uid;
	    Log-Info $fn ("Deleting localGroup '{0}' [{1}] ..." -f $olocalGroup.Name, $olocalGroup.uid) -Verbose:$true;
	    if($PSCmdlet.ShouldProcess($olocalGroup.uid)) {
		    $r = Invoke-CteraCommand -Method 'DELETE' -Api $Uri;
            $oLocalGroupDelete = ConvertFrom-CteraObj -XmlString $r;
            $OutputParameter += $oLocalGroupDelete.Clone();
	    } # if
        #$OutputParameter += $olocalGroup.Clone();
    } else {
        $e = New-CustomErrorRecord -m ("Invalid ParameterSetName encountered: '{0}'." -f $PSCmdlet.ParameterSetName) -cat InvalidArgument -o $PSCmdlet.ParameterSetName;
		Log-Error $fn $e.Exception.Message;
		throw($gotoError);
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
} # PROCESS
END {
    if($OutputParameter -and $OutputParameter -is [Array] -and $OutputParameter.Count -eq 1) {
        $OutputParameter = $OutputParameter[0];
    } # if

	$datEnd = [datetime]::Now;
	Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;

	return $OutputParameter;
} # END

} # function
Export-ModuleMember -Function Remove-CteraLocalGroup;

function Get-CteraLocalGroup {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium",
	HelpURI='http://dfch.biz/PS/Storebox/Api/Get-CteraLocalGroup/'
)]
PARAM (
	[Parameter(ValueFromPipeline = $true, Mandatory = $true, Position = 0, ParameterSetName = 'name')]
	[string] $Name
	,
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'id')]
	[alias('uid')]
	[int] $id
	,
	[Parameter(Mandatory = $false, ParameterSetName = 'list')]
	[alias('all')]
	[switch] $ListAvailable = $true
)
BEGIN {
try {
	# Parameter validation
	# N/A
	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
	Log-Debug -fn $fn -msg ("CALL. ParameterSetName: '{0}'" -f $PSCmdlet.ParameterSetName) -fac 1;
	
	$fReturn = $false;
	$OutputParameter = $null;
	$UriLocalGroups = 'localGroups'
	
	$slocalGroups = Invoke-CteraCommand $UriLocalGroups;
	$olocalGroups = ConvertFrom-CteraObjList -XmlString $slocalGroups;
	if(!$olocalGroups) {
		$e = New-CustomErrorRecord -m ("Retrieving and converting group names FAILED.") -cat ConnectionError -o $olocalGroups;
		throw($gotoError);
	} # if
	if(($PSCmdlet.ParameterSetName -eq 'list') -and $ListAvailable) {
		$OutputParameter = $olocalGroups.Clone();
		throw($gotoSuccess);
	} # if
    $OutputParameter = @();
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

} # BEGIN
PROCESS {
try {
	# Parameter validation
	# N/A

	if($PSCmdlet.ParameterSetName -eq 'name') {
        $fReturn = $false;
        $olocalGroup = $null;
        foreach($olocalGroup in $olocalGroups) { 
            if($olocalGroup.name -eq $Name) { $fReturn = $true; break; } # if
        } # foreach
		if(!$fReturn) {
			$e = New-CustomErrorRecord -m ("Getting localGroup FAILED. Group '{0}' not found." -f $Name) -cat ObjectNotFound -o $olocalGroups;
            throw($gotoError);
		} # if
        $OutputParameter += $olocalGroup.Clone();
	} elseif($PSCmdlet.ParameterSetName -eq 'id') {
        $fReturn = $false;
        $olocalGroup = $null;
        foreach($olocalGroup in $olocalGroups) { 
            if($olocalGroup.uid -eq $id) { $fReturn = $true; break; } # if
        } # foreach
		if(!$fReturn) {
			$e = New-CustomErrorRecord -m ("Getting localGroup FAILED. Group id '{0}' not found." -f $id) -cat ObjectNotFound -o $olocalGroups;
            throw($gotoError);
		} # if
        $OutputParameter += $olocalGroup.Clone();
	} elseif($PSCmdlet.ParameterSetName -eq 'list') {
		# N/A
        # already handled in BEGIN block
    } else {
        $e = New-CustomErrorRecord -m ("Invalid ParameterSetName encountered: '{0}'." -f $PSCmdlet.ParameterSetName) -cat InvalidArgument -o $PSCmdlet.ParameterSetName;
		Log-Error $fn $e.Exception.Message;
		throw($gotoError);
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
} # PROCESS
END {

    if($OutputParameter -and $OutputParameter -is [Array] -and $OutputParameter.Count -eq 1) {
        $OutputParameter = $OutputParameter[0];
    } # if
	$datEnd = [datetime]::Now;
	Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;

	return $OutputParameter;
} # END

} # function
Export-ModuleMember -Function Get-CteraLocalGroup;

function ConvertFrom-CteraObj {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Low",
	HelpURI='http://dfch.biz/PS/Storebox/Api/ConvertFrom-CteraObj/'
)]
[OutputType([hashtable[]])]
PARAM (
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'xml')]
	[alias('obj')]
	[alias('e')]
	[alias('Element')]
	[System.Xml.XmlElement] $XmlElement
	,
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'doc')]
	[alias('d')]
	[alias('Document')]
	[System.Xml.XmlDocument] $XmlDocument
	,
	#ValueFromPipelineByPropertyName = $true, 
	[Parameter(ValueFromPipeline = $true, Mandatory = $true, Position = 0, ParameterSetName = 'string')]
	[alias('string')]
	[alias('s')]
	[string] $XmlString
)
BEGIN {
	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
	#Log-Debug -fn $fn -msg ("CALL. ParameterSetName: '{0}'" -f $PSCmdlet.ParameterSetName) -fac 1;
	
	$fReturn = $false;
	$OutputParameter = @();
	$ParameterSetName = $PSCmdlet.ParameterSetName;
} # BEGIN

PROCESS {
try {
	# Parameter validation
	# N/A

	if($ParameterSetName -eq 'string') {
		[xml] $XmlDocument = $XmlString;
		$ParameterSetName = 'doc';
	} # if
	if($ParameterSetName -eq 'doc') {
		$XmlElement = $XmlDocument.SelectSingleNode('/obj');
		$fReturn = $XmlElement -is [System.Xml.XmlElement];
		if(!$fReturn) {
			$e = New-CustomErrorRecord -m ("InputObject contains no ChildNode 'obj': '{0}'" -f $XmlDocument.OuterXml) -cat InvalidData -o $XmlDocument;
			throw($gotoError);
		} # if
		$ParameterSetName = 'xml';
	} # if

	$aatt = $XmlElement.SelectNodes('att');
	$htAtts = @{};
	if($XmlElement.HasAttribute('class')) {
		$htAtts.Add('#class', $XmlElement.class);
	} # if
	if(!$aatt -or ($aatt.Count -le 0)) {
		$e = New-CustomErrorRecord -m ("InputObject contains no ChildNodes 'att': '{0}'" -f $XmlElement.OuterXml) -cat InvalidData -o $XmlElement;
		throw($gotoError);
	} # if
	foreach($att in $aatt) { 
		$id = $att.id;
		if(!$id) {
			Log-Warn $fn ("Unsupported 'att' node: '{0}'. Empty id." -f $att.OuterXml);
			continue;
		} # if
		$nVal = $att.selectSingleNode('val');
		$nList = $att.selectSingleNode('list');
		$nObj = $att.selectSingleNode('obj');
		$Value = '';
		if(!$att.HasChildNodes) {
			if($htAtts.Contains($id)) {
				Log-Warn $fn ("htAtts already contains an attribute with name '{0}'." -f $id);
			} else {
				if([System.Object]::Equals($n.'#text', $null)) {
					$Value = $null; 
				} else {
					$Value = $att.'#text'; 
				} # if
				$htAtts.Add($id, $Value);
			} # if
		} elseif($nVal) { 
			$Value = $nVal.'#text'; 
			$htAtts.Add($id, $Value);
		} elseif($nObj) {
			$htObjChild = ConvertFrom-CteraObj -XmlElement $nObj;
			$htAtts.Add($id, $htObjChild);
		} elseif($nList) {
			$aListItem = @();
            $anListObj = $nList.SelectNodes('obj');
			foreach($nListObj in $anListObj) {
				$htObjChild = ConvertFrom-CteraObj -XmlElement $nListObj;
                $aListItem += $htObjChild;
			} # foreach
            $anListVal = $nList.SelectNodes('val');
			foreach($nListVal in $anListVal) {
				$aListItem += $nListVal.'#text';
			} # foreach
			$htAtts.Add($id, $aListItem.Clone());
		} else {
			Log-Warn $fn ("Unsupported 'att' node: '{0}'." -f $att.id);
			continue;
		} # if
	} # foreach
	$htAtts.Add('#xml', $XmlElement.OuterXml);
	$OutputParameter += $htAtts.Clone();

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
	#Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;
} # END
} # function
Export-ModuleMember -Function ConvertFrom-CteraObj;

function ConvertFrom-CteraObjList {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Low",
	HelpURI='http://dfch.biz/PS/Storebox/Api/ConvertFrom-CteraObjList/'
)]
[OutputType([hashtable[]])]
PARAM (
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'xml')]
	[alias('list')]
	[alias('e')]
	[alias('Element')]
	[System.Xml.XmlElement] $XmlElement
	,
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'doc')]
	[alias('d')]
	[alias('Document')]
	[System.Xml.XmlDocument] $XmlDocument
	,
	[Parameter(ValueFromPipeline = $true, Mandatory = $true, Position = 0, ParameterSetName = 'string')]
	[alias('string')]
	[alias('s')]
	[string] $XmlString
)
BEGIN {
	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
	#Log-Debug -fn $fn -msg ("CALL. ParameterSetName: '{0}'" -f $PSCmdlet.ParameterSetName) -fac 1;
	
	$fReturn = $false;
	$OutputParameter = @();
	$ParameterSetName = $PSCmdlet.ParameterSetName;
} # BEGIN

PROCESS {
try {
	# Parameter validation
	# N/A

	if($ParameterSetName -eq 'string') {
		[xml] $XmlDocument = $XmlString;
		$ParameterSetName = 'doc';
	} # if
	if($ParameterSetName -eq 'doc') {
		$XmlElement = $XmlDocument.SelectSingleNode('/list');
		$fReturn = $XmlElement -is [System.Xml.XmlElement];
		if(!$fReturn) {
			$e = New-CustomErrorRecord -m ("InputObject contains no ChildNode 'list': '{0}'" -f $XmlDocument.OuterXml) -cat InvalidData -o $XmlDocument;
			throw($gotoError);
		} # if
		$ParameterSetName = 'xml';
	} # if

	$aobj = $XmlElement.SelectNodes('obj');
	if(!$aobj -or ($aobj.Count -le 0)) {
		$e = New-CustomErrorRecord -m ("InputObject contains no ChildNodes 'obj': '{0}'" -f $XmlElement.OuterXml) -cat InvalidData -o $XmlElement;
		throw($gotoError);
	} # if
	foreach($obj in $aobj) { 
		$OutputParameter += ConvertFrom-CteraObj -XmlElement $obj;
	} # foreach

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
return $OutputParameter.Clone();
} # PROCESS

END {
	$datEnd = [datetime]::Now;
	#Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;
} # END
} # function
Export-ModuleMember -Function ConvertFrom-CteraObjList;

function New-CteraLocalUser {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium",
	HelpURI='http://dfch.biz/PS/Storebox/Api/New-CteraLocalUser/'
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
		$UserTemplate = Get-CteraDefaultsObj -Name 'PortalAdmin' | ConvertFrom-CteraObj;
		
		$UserTemplate.name = [System.Web.HttpUtility]::HtmlEncode($UserName);
		$UserTemplate.email = [System.Web.HttpUtility]::HtmlEncode($EmailAddress);
		$UserTemplate.firstName = [System.Web.HttpUtility]::HtmlEncode($FirstName);
		$UserTemplate.lastName = [System.Web.HttpUtility]::HtmlEncode($LastName);
		$UserTemplate.password = [System.Web.HttpUtility]::HtmlEncode($Password);
		$UserTemplate.role = [System.Web.HttpUtility]::HtmlEncode($Role);
		$UserTemplate.comment = [System.Web.HttpUtility]::HtmlEncode($Comment);
		$UserTemplate.requirePasswordChangeOn = [System.Web.HttpUtility]::HtmlEncode($PasswordExpires.ToString('yyyy-MM-dd'));
		
		$Body = Format-CteraExtendedMethod -name add -p ($UserTemplate | ConvertTo-CteraXml);
	} else {
		$sUserDefaults = Get-CteraDefaultsObj -Name 'PortalUser';
		$oUserDefaults = ConvertFrom-CteraObj -XmlString $sUserDefaults;
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

		$oUserDefaults = $xUserDefaults.OuterXml | ConvertFrom-CteraObj;
		$Body = Format-CteraExtendedMethod -name add -p $xUserDefaults.OuterXml;
	} # if

    if($PSCmdlet.ShouldProcess($UserName)) {
		if($Global) {
			$r = Invoke-CteraCommand -Method "POST" -Api 'administrators' -Body $Body;
		} else {
			$r = Invoke-CteraCommand -Method "POST" -Api 'users' -Body $Body;
		} # if
        if(!$r) {
		    $e = New-CustomErrorRecord -m ("Creating localUser '{0}' FAILED." -f $UserName) -cat NotSpecified -o $Body;
		    throw($gotoError);
        } # if
        $tmpLocalUser = ConvertFrom-CteraObj -XmlString ("<obj class='#uri'><att id='#uri'>{0}</att></obj>" -f $r);
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
	Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;
} # END
} # function
Export-ModuleMember -Function New-CteraLocalUser;

function Remove-CteraLocalUser {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="High",
	HelpURI='http://dfch.biz/PS/Storebox/Api/Remove-CteraLocalUser/'
)]
[OutputType([Boolean])]
PARAM (
	[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Mandatory = $true, Position = 0, ParameterSetName = 'name')]
	[alias('n')]
	[alias('cn')]
	[alias('Identity')]
	[alias('name')]
	$UserName
	,
	[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Mandatory = $true, Position = 0, ParameterSetName = 'id')]
	[alias('uid')]
	[int] $id
)
BEGIN {
	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
	Log-Debug -fn $fn -msg ("CALL. ParameterSetName: '{0}'" -f $PSCmdlet.ParameterSetName) -fac 1;
	
	$fReturn = $false;
	$ParameterSetName = $PSCmdlet.ParameterSetName;
} # BEGIN

PROCESS {
try {
	# Parameter validation
	# N/A

    if($ParameterSetName -eq '__AllParameterSets') {
        if($UserName -is [System.Collections.Hashtable]) {
		    $e = New-CustomErrorRecord -m ("Input parameter from pipeline has wrong data type '{0}'." -f $UserName.GetType().FullName) -cat InvalidArgument -o $UserName;
		    throw($gotoError);
        } # if
        $id = $UserName.uid;
        $UserName = $UserName.name;
    } elseif($ParameterSetName -eq 'name') {
        if($UserName -is [System.Collections.Hashtable]) {
            $UserName = $UserName.name;
        } # if
        $sUser = Invoke-CteraCommand -Api ("users/{0}" -f $UserName);
        if(!$sUser) {
		    $e = New-CustomErrorRecord -m ("Cannot delete localUser '{0}' as user retrieving uid of user FAILED." -f $UserName) -cat ObjectNotFound -o $UserName;
		    throw($gotoError);
        } # if
        $oUser = ConvertFrom-CteraObj -XmlString $sUser;
        $id = $oUser.uid;
    } else {
        $UserName = '';
    } # if
    $Body = Format-CteraExtendedMethod  -name delete -Parameters '<val>true</val>'
    if($PSCmdlet.ShouldProcess(("{0} [{1}]" -f $UserName, $id))) {
        $r = Invoke-CteraCommand -Method "POST" -Api ('objs/{0}' -f $id) -Body $Body;
        if($r) {
		    $e = New-CustomErrorRecord -m ("Deleting localUser '{0}' [{1}] FAILED." -f $UserName, $id) -cat NotSpecified -o $oUser;
		    throw($gotoError);
        } # if
        $tmpLocalUser = ConvertFrom-CteraObj -XmlString ("<obj class='#uri'><att id='#uri'>{0}</att></obj>" -f $r);
        Log-Notice $fn ("Deleted localUser '{0}' [{1}]." -f $UserName, $id) -Verbose:$Verbose;
	    $OutputParameter = $true
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
	Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;
} # END
} # function
Export-ModuleMember -Function Remove-CteraLocalUser;

function Add-CteraLocalGroupMember {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium",
	HelpURI='http://dfch.biz/PS/Storebox/Api/Add-CteraLocalGroupMember/'
)]
PARAM (
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'name')]
	[string] $Name
	,
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'id')]
	[alias('idPortal')]
	[alias('uid')]
	[int] $id
	,
	[Parameter(ValueFromPipeline = $true, Mandatory = $true, Position = 1)]
	[alias('add')]
	[alias('Member')]
	[string[]] $NewMember
	,
	[Parameter(Mandatory = $false)]
	[switch] $MemberAsUid = $false
	,
	[ValidateRange(0,1)]
	[Parameter(Mandatory = $false)]
	[double] $Threshold = 0.1
)
BEGIN {
try {
	# Parameter validation
	# N/A
	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
	Log-Debug -fn $fn -msg ("CALL. NewMember: '{0}'. ParameterSetName: '{0}'" -f $NewMember.Count, $PSCmdlet.ParameterSetName) -fac 1;
	
	[boolean] $fBulk = $false;
	$r = Invoke-CteraCommand 'status/totalUsers';
	$dbStatusSlim = ("<obj class='user-defined' ><att id='totalUsers' >{0}</att></obj>" -f $r) | ConvertFrom-CteraObj;
	$UriUsers = 'users';
	if( ($NewMember.Count -gt 10) -and ($NewMember.Count -gt $dbStatusSlim.totalUsers * $Threshold) ) {
		Log-Debug $fn ("Specified number of users '{0}' exceeds threshold '{1}' of total number of users '{2}'. Processing users in bulk operation." -f $NewMember.Count, $Threshold, $dbStatusSlim.totalUsers);
		$oUsers = Invoke-CteraCommand $UriUsers | ConvertFrom-CteraObjList;
		$fBulk = $true;
	} # if

	$fReturn = $false;
	$OutputParameter = $null;
    $PSParameterNameSet = $PSCmdlet.ParameterSetName;

	$UriLocalGroups = 'localGroups';
    $UriObjs = 'objs';

    if($PSParameterNameSet -eq 'name') {
    	$slocalGroup = Invoke-CteraCommand ( "{0}/{1}" -f $UriLocalGroups, $Name);
    } elseif($PSParameterNameSet -eq 'id') {
    	$slocalGroup = Invoke-CteraCommand ( "{0}/{1}" -f $UriObjs, $id);
    } else {
        $e = New-CustomErrorRecord -m "" -cat InvalidArgument -o $PSCmdlet.ParameterSetName;
        throw($gotoError);
        # N/A
    } # if
	$olocalGroup = ConvertFrom-CteraObj -XmlString $slocalGroup;
	if(!$olocalGroup) {
		$e = New-CustomErrorRecord -m ("Retrieving and converting group names FAILED.") -cat ConnectionError -o $olocalGroup;
		throw($gotoError);
	} # if
    [xml] $xlocalGroup = $slocalGroup;

    $aMembers = @();
    foreach($User in $olocalGroup.Users) {
        $aMembers += $User;
    } # foreach

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

} # BEGIN
PROCESS {
try {
	# Parameter validation
	# N/A

    foreach($Member in $NewMember) {
		if(!$MemberAsUid) {
			if($fBulk) {
				$sUser = ($ousers |? name -eq $Member).'#xml';
			} else {
				$sUser = Invoke-CteraCommand ("{0}/{1}" -f $UriUsers, $Member);
			} # if
			$oUser = ConvertFrom-CteraObj -XmlString $sUser;
			if(!$oUser) {
				$e = New-CustomErrorRecord -m ("Retrieving localUser name '{0}' FAILED." -f $Member) -cat ConnectionError -o $Member;
				throw($gotoError);
			} # if
		} else {
			if(![int]::Parse($Member)) {
				$e = New-CustomErrorRecord -m ("Converting uid '{0}' for localUser name FAILED." -f $Member) -cat InvalidArg -o $Member;
				throw($gotoError);
			} # if
			$id = [int]::Parse($Member);
			$oUser = @{};
			$oUser.uid = $id;
		} # if
        $aMembers += ("objs/{0}" -f $oUser.uid);
    } # foreach

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
} # PROCESS
END {
	# Adding members to group
    $ListVal = New-CteraListVal -Values $aMembers;
    $attUsers = $xlocalGroup.obj.SelectSingleNode("att[@id = 'users']")
    $attUsers.set_InnerXML($ListVal);
    $Body = $xlocalGroup.OuterXml;

	$Uri = "objs/{0}" -f $olocalGroup.uid;
	Log-Info $fn ("Adding members to localGroup '{0}' [{1}] ..." -f $olocalGroup.Name, $olocalGroup.uid) -Verbose:$true;
	if($PSCmdlet.ShouldProcess($aMembers)) {
		$r = Invoke-CteraCommand -Method 'PUT' -Api $Uri -Body $Body;
        if(!$r) {
		    $e = New-CustomErrorRecord -m ("Adding members to localGroup '{0}' [{1}] FAILED." -f $olocalGroup.Name, $olocalGroup.uid) -cat NotSpecified -o $Body;
		    throw($gotoError);
        } # if
        $tmpLocalGroup = ConvertFrom-CteraObj -XmlString $r;
        Log-Info $fn ("Adding members to localGroup '{0}' [{1}] SUCCEEDED." -f $Name, $oLocalGroup.'#uri') -Verbose:$Verbose;
        $OutputParameter = $tmpLocalGroup.Clone();
	} # if

	$datEnd = [datetime]::Now;
	Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;

	return $OutputParameter;
} # END

} # function
Export-ModuleMember -Function Add-CteraLocalGroupMember;

function Remove-CteraLocalGroupMember {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="High",
	HelpURI='http://dfch.biz/PS/Storebox/Api/Remove-CteraLocalGroupMember/'
)]
PARAM (
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'name')]
	[string] $Name
	,
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'id')]
	[alias('uid')]
	[int] $id
	,
	[Parameter(ValueFromPipeline = $true, Mandatory = $true)]
	[alias('del')]
	[alias('Member')]
	[string[]] $RemoveMember
)
BEGIN {
try {
	# Parameter validation
	# N/A
	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
	Log-Debug -fn $fn -msg ("CALL. ParameterSetName: '{0}'" -f $PSCmdlet.ParameterSetName) -fac 1;
	
	$fReturn = $false;
	$OutputParameter = $null;
    $PSParameterNameSet = $PSCmdlet.ParameterSetName;

	$UriLocalGroups = 'localGroups';
    $UriObjs = 'objs';

    if($PSParameterNameSet -eq 'name') {
    	$slocalGroup = Invoke-CteraCommand ( "{0}/{1}" -f $UriLocalGroups, $Name);
    } elseif($PSParameterNameSet -eq 'id') {
    	$slocalGroup = Invoke-CteraCommand ( "{0}/{1}" -f $UriObjs, $id);
    } else {
        $e = New-CustomErrorRecord -m "" -cat InvalidArgument -o $PSCmdlet.ParameterSetName;
        throw($gotoError);
        # N/A
    } # if
	$olocalGroup = ConvertFrom-CteraObj -XmlString $slocalGroup;
	if(!$olocalGroup) {
		$e = New-CustomErrorRecord -m ("Retrieving and converting group names FAILED.") -cat ConnectionError -o $olocalGroup;
		throw($gotoError);
	} # if
    [xml] $xlocalGroup = $slocalGroup;

    $aMembers = New-Object System.Collections.ArrayList;
    foreach($User in $olocalGroup.Users) {
        if(!$aMembers.Contains($User)) { $aMembers.Add($User); }
    } # foreach

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
				$PSCmdlet.ThrowTerminatingError($_);
			} else {
				$PSCmdlet.ThrowTerminatingError($_);
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
} # finally

} # BEGIN
PROCESS {
try {
	# Parameter validation
	# N/A
    foreach($Member in $RemoveMember) {
        $sUser = Invoke-CteraCommand ("{0}/{1}" -f 'users', $Member);
        $oUser = ConvertFrom-CteraObj -XmlString $sUser;
	    if(!$oUser) {
		    $e = New-CustomErrorRecord -m ("Retrieving localUser name '{0}' FAILED." -f $Member) -cat ConnectionError -o $Member;
		    throw($gotoError);
	    } # if
        foreach($ExistingMember in $aMembers) {
            if($ExistingMember -match ("^objs/{0}" -f $oUser.uid)) {
                $aMembers.Remove($ExistingMember);
                break;
            } # if
        } # foreach
    } # foreach

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
				$PSCmdlet.ThrowTerminatingError($_);
			} else {
				$PSCmdlet.ThrowTerminatingError($_);
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
} # finally
} # PROCESS
END {
	# Removing members from group
    if($aMembers.Count -le 0) {
        $ListVal = '<list />';
    } else {
        $ListVal = New-CteraListVal -Values $aMembers;
    } # if
    $attUsers = $xlocalGroup.obj.SelectSingleNode("att[@id = 'users']")
    $attUsers.set_InnerXML($ListVal);
    $Body = $xlocalGroup.OuterXml;

	$Uri = "objs/{0}" -f $olocalGroup.uid;
	Log-Info $fn ("Removing '{2}' members ['{3}'] from localGroup '{0}' [{1}] ..." -f $olocalGroup.Name, $olocalGroup.uid, $RemoveMember.Count, ($RemoveMember -join ' ')) -Verbose:$true;
	if($PSCmdlet.ShouldProcess($RemoveMember -join ' ')) {
		$r = Invoke-CteraCommand -Method 'PUT' -Api $Uri -Body $Body;
        if(!$r) {
		    $e = New-CustomErrorRecord -m ("Removing members from localGroup '{0}' [{1}] FAILED." -f $olocalGroup.Name, $olocalGroup.uid) -cat NotSpecified -o $Body;
		    throw($gotoError);
        } # if
        $tmpLocalGroup = ConvertFrom-CteraObj -XmlString $r;
        Log-Info $fn ("Removing members from localGroup '{0}' [{1}] SUCCEEDED." -f $Name, $oLocalGroup.'#uri') -Verbose:$Verbose;
        $OutputParameter = $tmpLocalGroup.Clone();
	} # if

	$datEnd = [datetime]::Now;
	Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;

	return $OutputParameter;
} # END

} # function
Export-ModuleMember -Function Remove-CteraLocalGroupMember;

function ConvertTo-CteraXml {
	[CmdletBinding(
		HelpURI='http://dfch.biz/PS/Storebox/Api/ConvertTo-CteraXml/'
    )]
	[OutputType([string])]
Param (
    [Parameter(ValueFromPipeline = $true, Mandatory = $true, Position = 0)]
    [alias("o")]
    $obj
    ,
	[Parameter(Mandatory = $false, Position = 1)]
	[alias("x")]
	$XmlWriter = $null
) # Param
BEGIN {
$datBegin = Get-Date;
[string] $fn = $MyInvocation.MyCommand.Name;
#Log-Debug -fn $fn -msg ("CALL. obj.GetType() '{0}'" -f $obj.GetType())-fac 1;

} # BEGIN

PROCESS {
[boolean] $fReturn = $false;
$OutputParameter = $null;
$XmlStringTemp = '';
$fCalledByRecursion = $false;

try {

    if(!$XmlWriter) {
	    $settings = New-Object System.Xml.XmlWriterSettings;
	    $settings.OmitXmlDeclaration = $true;
	    $ms = New-Object System.IO.MemoryStream;
	    $XmlWriter = [System.Xml.XmlWriter]::Create($ms, $settings);
    } else {
        $fCalledByRecursion = $true;
    } # if

	if($obj -is [System.Collections.Hashtable]) {
		$XmlWriter.WriteStartElement('obj');
        if($obj.'#class') { $XmlWriter.WriteAttributeString('class', $obj.'#class'); }
		#Write-Host ("<obj> @class {0}" -f $obj.'class');
		foreach($item in $obj.GetEnumerator()) {
            if($item.name -match '^#') { continue; }
		    $XmlWriter.WriteStartElement('att');
            $XmlWriter.WriteAttributeString('id', $item.name);
			#Write-Host ("<att> @id {0}" -f $item.name);
			$XmlString = ConvertTo-CteraXml -obj $item -XmlWriter $XmlWriter;
			$XmlWriter.WriteEndElement();
		} # foreach
        $XmlWriter.WriteEndElement();
	} elseif($obj -is [Array] -or $obj -is [System.Collections.ArrayList]) {
		$XmlWriter.WriteStartElement('list');
		#Write-Host ("<list>")
		foreach($item in $obj) {
			$XmlString = ConvertTo-CteraXml -obj $item -XmlWriter $XmlWriter;
			$XmlWriter.WriteString($XmlString);
		} # foreach
        $XmlWriter.WriteEndElement();
	} elseif($obj -is [System.Collections.DictionaryEntry]) {
        if($obj.Value -is [Array] -or $obj -is [System.Collections.ArrayList]) {
		    $XmlWriter.WriteStartElement('list');
		    #Write-Host ("<list>")
		    foreach($item in $obj.Value) {
                if([System.Object]::Equals($null, $item)) { continue; }
			    $XmlString = ConvertTo-CteraXml -obj $item -XmlWriter $XmlWriter;
			    $XmlWriter.WriteString($XmlString);
		    } # foreach
            $XmlWriter.WriteEndElement();
        } elseif($obj.Value -is [System.Collections.Hashtable]) {
            $XmlString = ConvertTo-CteraXml -obj $obj.Value -XmlWriter $XmlWriter;
        } else {
            if($obj.Value -is [string]) {
		        $XMLWriter.WriteElementString('val', $obj.Value);
            } elseif($obj.Value -is [int]) {
		        $XMLWriter.WriteElementString('val', $obj.Value);
            } else {
				if($obj.Value) {
					Log-Warn $fn ("Unexpected type for obj.Name '{0}' found: '{1}'" -f $obj.Name, $obj.Value);
					$XMLWriter.WriteElementString('val', $obj.Value);
				} else {
					# N/A 
				} # if
            } # if
        } # if
	} else {
        if($obj -is [string]) {
		    $XMLWriter.WriteElementString('val', $obj);
        } elseif($obj -is [int]) {
		    $XMLWriter.WriteElementString('val', $obj);
        } else {
			Log-Warn $fn ("Unexpected type for obj '{0}' found: '{1}'" -f $obj, $obj.GetType());
		} # if
    } # if

    if(!$fCalledByRecursion) {
	    $XmlWriter.Flush();
	    $XmlWriter.Close();
	    [xml] $y = New-Object System.Xml.XmlDocument;
	    $ms.Flush();
	    $ms.Position = 0;
	    $y.Load($ms);
	    $ms.Close();
	    #$y.OuterXml;
        $OutputParameter = $y.OuterXml;
        $fReturn = $true;
    } else {
        $fReturn = $false;
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
		
		if( [System.Net.WebException] -eq (($_.Exception).GetType()) ) {
			Log-Critical $fn "Operation on '$Uri' FAILED [$_].";
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
} # finally
return $OutputParameter;
} # PROCESS

END {
$datEnd = [datetime]::Now;
#Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;
} # END

} # function
Export-ModuleMember -Function ConvertTo-CteraXml;

function Get-CteraDefaultsObj {
[CmdletBinding(
	HelpURI='http://dfch.biz/PS/Storebox/Api/Get-CteraDefaultsObj/'
)]
[OutputType([string])]
Param (
	[ValidateSet("PortalUser", 'PortalGroup', "LocalGroup", "LocalUser", "ProjectCreateParams", "TeamPortal", "ResellerPortal", "SearchMemberParam", 'ProjectACLRule', 'HomeFolder', 'Portal', 'TeamPortal', 'ResellerPortal', 'AddOn', 'AddOnParam', 'UserAddOn', "db", 'EmailMessage', 'Invitation', 'InvitationSettings', 'PortalsStatisticsReport', 'PortalStats', 'Plan', 'PortalAdmin')]
	[Parameter(Mandatory = $true, Position = 0)]
	[alias("n")]
	[string] $Name = 'db'
)
BEGIN {
$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. Name: '{0}'" -f $Name) -fac 1;
} # BEGIN

PROCESS {
[boolean] $fReturn = $false;
$OutputParameter = $null;

try {
	# Parameter validation
	# N/A

	$Response = $null;
	# Check if cache is already initialised
	if($biz_dfch_PS_Storebox_Api.Contains($fn)) {
		$Cache = $biz_dfch_PS_Storebox_Api.$fn;
		if($Cache.Contains($Name)) {
			$Response = $Cache.$Name;
		} # if
	} else {
		Log-Debug $fn "Initialising defaults cache.";
		$biz_dfch_PS_Storebox_Api.$fn = @{};
	} # if
	# Invoke only on cache miss
	if(!$Response) {
		if($Name -eq 'db') {
			$Response = Invoke-CteraCommand -Api '/';
		} else {
			$Response = Invoke-CteraCommand -Api ("defaults/{0}" -f $Name);
		} # if
        if(!$Response) {
            $e = New-CustomErrorRecord ("Retrieving 'defaults/{0}' FAILED." -f $Name) -cat ObjectNotFound -o $Name;
            throw($gotoError);
        } # if
		# Update cache
		Log-Debug $fn ("Updating '{0}' cache." -f $Name);
		$biz_dfch_PS_Storebox_Api.$fn.Add($Name, $Response);
	} # if
	$OutputParameter = $Response;
			
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

} # Get-CteraDefaultsObj
Set-Alias -Name Get-CteraObjTemplate -Value Get-CteraDefaultsObj;
Export-ModuleMember -Function Get-CteraDefaultsObj -Alias Get-CteraObjTemplate;

function Get-CteraTime {
[CmdletBinding(
	HelpURI='http://dfch.biz/PS/Storebox/Api/Get-CteraTime/'
)]
[OutputType([hashtable])]
Param (
)
BEGIN {
$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. Name: '{0}'" -f $Name) -fac 1;
} # BEGIN

PROCESS {
[boolean] $fReturn = $false;
$OutputParameter = $null;

try {
	# Parameter validation
	# N/A

	$Response = Invoke-CteraCommand -Api 'currentTime';
	$OutputParameter = $Response | ConvertFrom-CteraObj;
			
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

} # Get-CteraTime
Export-ModuleMember -Function Get-CteraTime;

<#
$acl = @(); 
$acl += New-CteraAclEntry -Name tgdriro5 -Type localUser -Permission ReadWrite;
$acl += New-CteraAclEntry -Name adm-tgdkada2 -Type localUser -Permission ReadOnly;
$acl += New-CteraAclEntry -Name ProjectsReadWrite -Type localGroup -Permission ReadWrite;
$acl += New-CteraAclEntry -Name ProjectsReadOnly -Type localGroup -Permission ReadOnly;
New-CteraProjectFolder -Name testFolder9 -Owner tgdriro5 -Description "tralala ist eine Description" -Permissions $acl
#>
function New-CteraProjectFolder {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium",
	HelpURI='http://dfch.biz/PS/Storebox/Api/New-CteraProjectFolder/'
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

$oProjectTemplate = Get-CteraObjTemplate ProjectCreateParams|ConvertFrom-CteraObj;
$r = Invoke-CteraCommand defaultGroup;
$dbSlim = ("<obj class='user-defined' ><att id='defaultGroup' >{0}</att></obj>" -f $r) | ConvertFrom-CteraObj;
$oAclRuleTemplate = Get-CteraDefaultsObj ProjectACLRule | ConvertFrom-CteraObj;

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
    $oUser = Invoke-CteraCommand ('users/{0}' -f $r.Owner) | ConvertFrom-CteraObj;
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
                    $oUser = Invoke-CteraCommand ('users/{0}' -f $Matches.name) | ConvertFrom-CteraObj;
                    $uid = $oUser.uid;
                }
                'localGroup' {
                    $oGroup = Invoke-CteraCommand ('localGroups/{0}' -f $Matches.name) | ConvertFrom-CteraObj;
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
        $Parameters = $oProjectFolderValidate | ConvertTo-CteraXml;
        $Uri = 'projects';
        $Body = Format-CteraExtendedMethod -Name 'validate' -Parameters $Parameters;
        $r = Invoke-CteraCommand -Method 'POST' -Api $Uri -Body $Body;
        if(![System.Object]::Equals($r, $null)) {
            $e = New-CustomErrorRecord -m ("Validation of adding projectFolder '{0}' FAILED." -f $oProjectFolder.Name) -cat InvalidData -o $Body;
            throw($gotoError);
        } # 
    } # if
    $Parameters = $oProjectFolder | ConvertTo-CteraXml;
    $Body = Format-CteraExtendedMethod -Name 'addProject' -Parameters $Parameters;
	if(!$PSCmdlet.ShouldProcess($Name)) {
        $fReturn = $true;
        $OutputParameter = $null;
        throw($gotoSuccess);
    } # if
    $Uri = '/'
    $r = Invoke-CteraCommand -Method 'POST' -Api $Uri -Body $Body;
    if([System.Object]::Equals($r, $null)) {
        $e = New-CustomErrorRecord -m ("Adding projectFolder '{0}' FAILED." -f $oProjectFolder.Name) -cat InvalidData -o $Body;
        throw($gotoError);
    } # 
    $OutputParameter = ("<obj class='#uri'><att id='#uri'>{0}</att></obj>" -f $r) | ConvertFrom-CteraObj;
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
Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;
} # END

} # New-CteraProjectFolder
Set-Alias -Name New-CteraProject -Value New-CteraProjectFolder;
Set-Alias -Name New-CteraFolder -Value New-CteraProjectFolder;
Export-ModuleMember -Function New-CteraProjectFolder -Alias New-CteraProject, New-CteraFolder;

function Remove-CteraObject {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="High",
	HelpURI='http://dfch.biz/PS/Storebox/Api/Remove-CteraObject/'
)]
[OutputType([Boolean])]
Param (
	[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Mandatory = $true, Position = 0, ParameterSetName = 'o')]
	$InputObject
    ,
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'id')]
	[int] $id
    ,
	[Parameter(Mandatory = $false)]
	[switch] $Validate = $false
)
BEGIN {
$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. ParameterSetName '{0}'" -f $PSCmdlet.ParameterSetName) -fac 1;

$Body = Format-CteraExtendedMethod -Name delete -Parameters '<val>true</val>'
} # BEGIN

PROCESS {
[boolean] $fReturn = $false;
$OutputParameter = $null;

try {
	# Parameter validation
	# N/A
    if($PSCmdlet.ParameterSetName -eq 'id') {
        $InputObject = $id;
    } # if

    foreach($oObj in $InputObject) {
        if(!$oObj) {
            $e = New-CustomErrorRecord -m ("InputObject contains null value.") -cat InvalidData -o $InputObject;
            throw($gotoError);
        } # if
        if($oObj -is [hashtable] -or $oObj -is [System.Collections.Specialized.OrderedDictionary]) {
            if(!$oObj.Contains('#class') -or !$oObj.Contains('name') -or !$oObj.Contains('uid')) {
                $e = New-CustomErrorRecord -m ("InputObject item is hashtable but does not class, name or uid.") -cat InvalidData -o $oObj;
                throw($gotoError);
            } # if
            if($Validate) {
                $oObjV = Invoke-CteraCommand ("objs/{0}" -f $oObj.uid) | ConvertFrom-CteraObj;
                if(!$oObjV -or !$oObjV.Contains('uid') -or $oObjV.uid -ne $oObj.uid) {
                    $e = New-CustomErrorRecord -m ("Object with id '{0}' not found." -f $oObj.uid) -cat ObjectNotFound -o $oObj.uid;
                    throw($gotoError);
                } # if
                $oObj = $oObjV.Clone();
            } # if
            Log-Info $fn ("Deleting '{0}' '{1}' [{2}] ..." -f $oObj.'#class', $oObj.name, $oObj.uid) -v;
	        if(!$PSCmdlet.ShouldProcess($oObj.uid)) {
                throw($gotoSuccess);
            } # if
            $r = Invoke-CteraCommand -Method POST -Api ("objs/{0}" -f $oObj.uid) -Body $Body;
            if(![System.Object]::Equals($r, $null)) {
                Log-Error $fn ("Deleting object id [{0}] FAILED." -f $oObj.uid) -v;
            } else {
                Log-Debug $fn ("Deleting object id [{0}] SUCCEEDED." -f $oObj.uid);
            } # if
        } elseif([int]::Parse($oObj)) {
            $id = [int]::Parse($oObj);
            if($Validate) {
                $oObjV = Invoke-CteraCommand ("objs/{0}" -f $id) | ConvertFrom-CteraObj;
                if(!$oObjV -or !$oObjV.Contains('uid') -or $oObjV.uid -ne $id) {
                    $e = New-CustomErrorRecord -m ("Object with id '{0}' not found." -f $id) -cat ObjectNotFound -o $id;
                    throw($gotoError);
                } # if
                $oObj = $oObjV.Clone();
            } else {
                $oObj = @{};
                $oObj.uid = $id -as [string];
                $oObj.'#class' = '#unknown';
                $oObj.name = '#unknown';
            } # if
            Log-Info $fn ("Deleting '{0}' '{1}' [{2}] ..." -f $oObj.'#class', $oObj.name, $oObj.uid) -v;
	        if(!$PSCmdlet.ShouldProcess($oObj.uid)) {
                throw($gotoSuccess);
            } # if
            $r = Invoke-CteraCommand -Method POST -Api ("objs/{0}" -f $oObj.uid) -Body $Body;
            if(![System.Object]::Equals($r, $null)) {
                Log-Error $fn ("Deleting object id [{0}] FAILED." -f $oObj.uid) -v;
            } else {
                Log-Debug $fn ("Deleting object id [{0}] SUCCEEDED." -f $oObj.uid);
            } # if
        } else {
            $e = New-CustomErrorRecord -m ("Object '{0}' is not a valid uid." -f $oObj) -cat InvalidData -o $oObj;
            throw($gotoError);
        } # if
    } # foreach
    $fReturn = $true;
    $OutputParameter = $fReturn;
    throw($gotoSuccess);

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
			    Log-Error $fn $e.Exception.Message -v;
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
} # PROCESS

END {
$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;
return $OutputParameter;
} # END

} # Remove-CteraObject
Set-Alias -Name Remove-CteraObj -Value Remove-CteraObject;
Export-ModuleMember -Function Remove-CteraObject -Alias Remove-CteraObj;


function Get-CteraLogs {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Low",
	HelpURI='http://dfch.biz/PS/Storebox/Api/Get-CteraLogs/'
)]
[OutputType([Boolean])]
Param (
	[Parameter(Mandatory = $false, Position = 0)]
	[Alias('c')]
	[int] $countLimit  = 150
	,
	[ValidateSet('system', 'sync', 'backup', 'cloudsync', 'access', 'audit', 'agent')]
	[Parameter(Mandatory = $false, Position = 1)]
	[Alias('t')]
	[string] $Topic = 'system'
    ,
	[ValidateSet('debug', 'info', 'warning', 'error')]
	[Parameter(Mandatory = $false, Position = 2)]
	[Alias('m')]
	[Alias('min')]
	[string] $minSeverity = 'info'
    ,
	[Parameter(Mandatory = $false, Position = 3)]
	[Alias('s')]
	[int] $startFrom  = 0
)
BEGIN {
$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. countLimit '{0}'" -f $countLimit) -fac 1;

$sParameters = @"
<obj><att id="topic"><val>system</val></att><att id="minSeverity"><val>debug</val></att><att id="include"><list><val>severity</val><val>time</val><val>username</val><val>msg</val><val>originType</val><val>origin</val><val>deviceGenerationId</val><val>id</val><val>topic</val><val>portal</val><val>id</val><val>portalUser</val></list></att><att id="more"><val>true</val></att><att id="startFrom"><val>0</val></att><att id="countLimit"><val>150</val></att><att id="filters"><list/></att></obj>
"@
$oParameters = $sParameters | ConvertFrom-CteraObj;

} # BEGIN

PROCESS {
[boolean] $fReturn = $false;
$OutputParameter = $null;

try {
	# Parameter validation
	# N/A

	$oParameters.minSeverity = $minSeverity;
	$oParameters.topic = $Topic;
	$oParameters.startFrom = ($startFrom -as [string])
	$oParameters.countLimit = ($countLimit -as [string]);

	$sParameters = $oParameters | ConvertTo-CteraXml;
	$Body = Format-CteraExtendedMethod -Name 'queryLogs' -Parameters $sParameters;
	$r = Invoke-CteraCommand -Method 'POST' -Api '/' -Body $Body;
	$msg = "Retrieving '{0}' log entries (from '{1}') with minSeverity '{2}' ..." -f $countLimit, $startFrom, $minSeverity;
	if(!$PSCmdlet.ShouldProcess($msg)) {
		$fReturn = $false;
		throw($gotoFailure);
	} # if
	Log-Debug $fn $msg;
	$OutputParameter = $r | ConvertFrom-CteraObj;
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
			    Log-Error $fn $e.Exception.Message -v;
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
} # PROCESS

END {
return $OutputParameter;

$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;
} # END

} # Get-CteraLogs
Export-ModuleMember -Function Get-CteraLogs;

function Set-CteraObject {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="High",
	HelpURI='http://dfch.biz/PS/Storebox/Api/Set-CteraObject/'
)]
[OutputType([Boolean])]
Param (
	[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Mandatory = $true, Position = 0, ParameterSetName = 'o')]
	$InputObject
    ,
	[Parameter(Mandatory = $false)]
	[switch] $Validate = $false
)
BEGIN {
$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. ParameterSetName '{0}'" -f $PSCmdlet.ParameterSetName) -fac 1;

} # BEGIN

PROCESS {
[boolean] $fReturn = $false;
$OutputParameter = $null;

try {
	# Parameter validation
	# N/A
    if($PSCmdlet.ParameterSetName -eq 'id') {
        $InputObject = $id;
    } # if

    foreach($oObj in $InputObject) {
        if(!$oObj) {
            $e = New-CustomErrorRecord -m ("InputObject contains null value.") -cat InvalidData -o $InputObject;
            throw($gotoError);
        } # if
        if($oObj -is [hashtable] -or $oObj -is [System.Collections.Specialized.OrderedDictionary]) {
            if(!$oObj.Contains('#class') -or !$oObj.Contains('name') -or !$oObj.Contains('uid')) {
                $e = New-CustomErrorRecord -m ("InputObject item is hashtable but does not class, name or uid.") -cat InvalidData -o $oObj;
                throw($gotoError);
            } # if
            if($Validate) {
                $oObjV = Invoke-CteraCommand ("objs/{0}" -f $oObj.uid) | ConvertFrom-CteraObj;
                if(!$oObjV -or !$oObjV.Contains('uid') -or $oObjV.uid -ne $oObj.uid) {
                    $e = New-CustomErrorRecord -m ("Object with id '{0}' not found." -f $oObj.uid) -cat ObjectNotFound -o $oObj.uid;
                    throw($gotoError);
                } # if
                if(!$oObjV -or !$oObjV.Contains('#class') -or $oObjV.'#class' -ne $oObj.'#class') {
                    $e = New-CustomErrorRecord -m ("Object with id '{0}' and class '{1}' does not match class of live object '{2}'." -f $oObj.uid, $oObj.'#class', $oObjV.'#class') -cat InvalidData -o $oObjV;
                    throw($gotoError);
                } # if
            } # if
            Log-Info $fn ("Updating '{0}' '{1}' [{2}] ..." -f $oObj.'#class', $oObj.name, $oObj.uid) -v;
	        if(!$PSCmdlet.ShouldProcess($oObj.uid)) {
                throw($gotoSuccess);
            } # if
			$Body = $oObj | ConvertTo-CteraXml;
            $r = Invoke-CteraCommand -Method PUT -Api ("objs/{0}" -f $oObj.uid) -Body $Body;
            if([System.Object]::Equals($r, $null)) {
                Log-Error $fn ("Updating object id [{0}] FAILED." -f $oObj.uid) -v;
            } else {
                Log-Debug $fn ("Updating object id [{0}] SUCCEEDED." -f $oObj.uid);
            } # if
			$oObjR = $r | ConvertFrom-CteraObj;
			$OutputParameter = $oObjR.Clone();
        } else {
            $e = New-CustomErrorRecord -m ("Object '{0}' is not a valid uid." -f $oObj) -cat InvalidData -o $oObj;
            throw($gotoError);
        } # if
    } # foreach
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
			    Log-Error $fn $e.Exception.Message -v;
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
} # PROCESS

END {
$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;
return $OutputParameter;
} # END

} # Set-CteraObject
Set-Alias -Name Set-CteraObj -Value Set-CteraObject;
Set-Alias -Name Update-CteraObj -Value Set-CteraObject;
Export-ModuleMember -Function Set-CteraObject -Alias Set-CteraObj, Update-CteraObj;

function New-CteraPortal {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="High",
	HelpURI='http://dfch.biz/PS/Storebox/Api/New-CteraPortal/'
)]
[OutputType([String])]
Param (
	[Parameter(Mandatory = $true, Position = 0)]
	[Alias('n')]
	[string] $Name
    ,
	[Parameter(Mandatory = $true, Position = 1, ParameterSetName = 't')]
	[Alias('t')]
	[switch] $TeamPortal
    ,
	[Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'r')]
	[Alias('r')]
	[switch] $ResellerPortal
    ,
	[Parameter(Mandatory = $false, Position = 1)]
	[Alias('p')]
	[Alias('Subscription')]
	[string] $Plan = $biz_dfch_PS_Storebox_Api.DefaultPlan
    ,
	[Parameter(Mandatory = $false, Position = 1)]
	[Alias('e')]
	[datetime] $Expiration
    ,
	[Parameter(Mandatory = $false, Position = 3)]
	[Alias('a')]
	$AddOn
    ,
	[Parameter(Mandatory = $false, Position = 2)]
	[Alias('c')]
	[string] $Comment
    ,
	[Parameter(Mandatory = $false, Position = 4)]
	[Alias('billing')]
	[Alias('BillingID')]
	[int] $externalPortalId = $null
    ,
	[Parameter(Mandatory = $false, ParameterSetName = 'r')]
	[Alias('q')]
	[switch] $enableResellerProvisioning = $true
)
BEGIN {
$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. countLimit '{0}'" -f $countLimit) -fac 1;

#$oPortalSlim = ("<obj class='#uri'><att id='name'>{0}</att></obj>" -f (Invoke-CteraCommand name)) | ConvertFrom-CteraObj;
$oPortalSelected = Invoke-CteraCommand / | ConvertFrom-CteraObj;
$null = Select-CteraPortal -AdminPortal;

} # BEGIN

PROCESS {
[boolean] $fReturn = $false;
$OutputParameter = $null;

try {
	# Parameter validation
	# N/A

    if($PSCmdlet.ParameterSetName -eq 'r') {
        $Uri = 'resellerPortals';
        $oResellerPortalDefault = Get-CteraDefaultsObj -Name ResellerPortal | ConvertFrom-CteraObj;
        $oResellerPortalDefault.enableResellerProvisioning = $enableResellerProvisioning -as [string];
        if(!$enableResellerProvisioning -and $Plan) { 
            $e = New-CustomErrorRecord -m ("Conflicting arguments. You must not specify a subscription plan ['{0}'] when 'enableResellerProvisioning' is disabled ['{1}']." -f $Plan, $enableResellerProvisioning) -cat InvalidArgument -o $PSCmdlet.MyInvocation;
            throw($gotoError);
        } # if
        $oPortalDefault = $oResellerPortalDefault;
    } elseif($PSCmdlet.ParameterSetName -eq 't') {
        $Uri = 'teamPortals';
        $oTeamPortalDefault = Get-CteraDefaultsObj -Name TeamPortal | ConvertFrom-CteraObj;
        $oTeamPortalDefault.portalType = 'team';
        $oPortalDefault = $oTeamPortalDefault;

    } else {
        $e = New-CustomErrorRecord -m ("Unsupported ParameterSetName '{0}'." -f $PSCmdlet.ParameterSetName) -cat InvalidArgument -o $PSCmdlet.ParameterSetName;
        throw($gotoError);
    } # if

    $oPortalDefault.name = [System.Web.HttpUtility]::HtmlEncode($Name);
    $oPortalDefault.comment = [System.Web.HttpUtility]::HtmlEncode($Comment);
    if($externalPortalId) { $oPortalDefault.externalPortalId = [System.Web.HttpUtility]::HtmlEncode($externalPortalId -as [string]); }

    if($Plan) {
        $oPlan = Invoke-CteraCommand ('plans/{0}' -f $Plan) | ConvertFrom-CteraObj
        if(!$oPlan) {
            $e = New-CustomErrorRecord -m ("Invalid plan name: '{0}'." -f $Plan) -cat ObjectNotFound -o $Plan;
            throw($gotoError);
        } # if
        $oPortalDefault.plan = 'objs/{0}' -f $oPlan.uid;
    } # if

    $oPortalDefault.portalAddOns = @();
    $oUserAddOnDefault = Get-CteraDefaultsObj -Name UserAddOn | ConvertFrom-CteraObj;
    $oUserAddOnDefault.startDate = [datetime]::Now.ToString('yyyy-MM-dd');
    $htAddOns = @{};
    foreach($a in $AddOn) {
        if(!$htAddOns.Contains($a)) {
            $oAddOn = Invoke-CteraCommand ('addOns/{0}' -f $a) | ConvertFrom-CteraObj;
            if($oAddOn) { $htAddOns.Add($a, $oAddOn); }
        } # if
        if(!$htAddOns.Contains($a)) {
            $e = New-CustomErrorRecord -m ("Invalid addOn name: '{0}'." -f $a) -cat ObjectNotFound -o $AddOn;
            throw($gotoError);
        } # if
        $oUserAddOn = $oUserAddOnDefault.Clone();
        $oUserAddOn.addOn = 'objs/{0}' -f $oAddOn.uid;
        $oPortalDefault.portalAddOns += $oUserAddOn.Clone();
        Log-Info $fn ("AddOn: '{0}' [{1}]" -f $htAddOns.$a.name, $htAddOns.$a.uid) -v;
    } # foreach

    $Body = Format-CteraExtendedMethod -Name add -Parameters ($oPortalDefault | ConvertTo-CteraXml);
    $msg = "Creating '{0}' '{1}' with plan '{2}' ..." -f $oPortalDefault.'#class', $oPortalDefault.name, $Plan;
	Log-Info $fn $msg -v;
	if(!$PSCmdlet.ShouldProcess($msg)) {
		$fReturn = $false;
		throw($gotoFailure);
	} # if
    $r = Invoke-CteraCommand -Method POST -Api $Uri -Body $Body;
    if(!$r) {
        $e = New-CustomErrorRecord -m ("Creating '{0}' '{1}' with plan '{2}' FAILED." -f $oPortalDefault.portalType, $oPortalDefault.name, $Plan) -cat InvalidData -o $Body;
        throw($gotoError);
    } # if
    Log-Notice $fn ("Creating '{0}' '{1}' with plan '{2}' SUCCEEDED [{3}]." -f $oPortalDefault.'#class', $oPortalDefault.name, $Plan, $r) -v;
	$OutputParameter = ("<obj class='#uri'><att id='#uri'>{0}</att></obj>" -f $r) | ConvertFrom-CteraObj;
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
			    Log-Error $fn $e.Exception.Message -v;
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
} # PROCESS

END {
#if($oPortalSelected.uid -ne 1) {
#    $null = Select-CteraPortal -Name $oPortalSlim.name;
#} # if
return $OutputParameter;

$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;
} # END

} # New-CteraPortal
Export-ModuleMember -Function New-CteraPortal;

function Invoke-CteraFileTransfer {
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

$xmlResponse = Invoke-CteraFileTransfer;
$xmlResponse.QueryList.Link;


.EXAMPLE

[DFCHECK] Give proper example. Gets all CTERA Cells.

$xmlResponse = Invoke-CteraFileTransfer -Api "query" -QueryParameters "type=cell";
$xmlResponse.QueryResultRecords.CellRecord;

.EXAMPLE

Upload file to Project folder

Invoke-CteraFileTransfer -Upload MyProjectFolder -Path C:\myFile.txt -AutomaticFileName

.LINK

Online Version: http://dfch.biz/PS/Storebox/Api/Invoke-CteraFileTransfer



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.
Requires a session to a CTERA host.

#>
[CmdletBinding(
	SupportsShouldProcess=$true,
	ConfirmImpact="High",
	HelpURI='http://dfch.biz/PS/Storebox/Api/Invoke-CteraFileTransfer'
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
Export-ModuleMember -Function Invoke-CteraFileTransfer;

function New-CteraPlan {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium",
	HelpURI='http://dfch.biz/PS/Storebox/Api/New-CteraPlan/'
)]
[OutputType([hashtable])]
PARAM (
	# $PlanTemplate.name
	[Parameter(Mandatory = $true, Position = 0)]
	[string] $Name
	,
	# $PlanTemplate.displayName
	[Parameter(Mandatory = $false, Position = 1)]
	[string] $DisplayName = ''
	,
	#  $PlanTemplate.displayDescription
	[Parameter(Mandatory = $false, Position = 2)]
	[string] $Description = ''
	,
	# $PlanTemplate.retentionPolicy.daily
	[Parameter(Mandatory = $false)]
	[int] $RetentionPolicyDaily = 7
	,
	# $PlanTemplate.retentionPolicy.monthly
	[Parameter(Mandatory = $false)]
	[int] $RetentionPolicyMonthly = 0
	,
	#$PlanTemplate.retentionPolicy.quarterly
	[Parameter(Mandatory = $false)]
	[int] $RetentionPolicyQuarterly = 0
	,
	#$PlanTemplate.retentionPolicy.weekly
	[Parameter(Mandatory = $false)]
	[int] $RetentionPolicyWeekly = 4
	,
	#$PlanTemplate.retentionPolicy.yearly
	[Parameter(Mandatory = $false)]
	[int] $RetentionPolicyYearly = 0
	,
	# $PlanTemplate.isTrial = 'true'
	# $PlanTemplate.subscriptionPeriod = $TrialDays
	[Parameter(Mandatory = $false)]
	[int] $TrialDays = 0
	,
	#  ($PlanTemplate.services|where serviceName -eq 'Cloud Backup').serviceState = "Disabled"
	[Parameter(Mandatory = $false)]
	[switch] $ServiceCloudBackup = $true
	,
	#  ($PlanTemplate.services|where serviceName -eq 'Seeding').serviceState = "Disabled"
	[Parameter(Mandatory = $false)]
	[switch] $ServiceCloudBackupSeeding = $true
	,
	#  ($PlanTemplate.services|where serviceName -eq 'Remote Access').serviceState = "Disabled"
	[Parameter(Mandatory = $false)]
	[switch] $ServiceRemoteAccess = $true
	,
	#  ($PlanTemplate.services|where serviceName -eq 'Cloud folders').serviceState = "Disabled"
	[Parameter(Mandatory = $false)]
	[switch] $ServiceCloudDrive = $true
	,
	#  ($PlanTemplate.services|where serviceName -eq 'Cloud file sharing').serviceState = "Disabled"
	[Parameter(Mandatory = $false)]
	[switch] $ServiceCloudDriveInvitations = $true
	,
	# $PlanTemplate.availableToEndUsers
	[Parameter(Mandatory = $false)]
	[switch] $AllowJoin = $false
	,
	# $PlanTemplate.sortIndex
	[Parameter(Mandatory = $false)]
	[int] $SortIndex = 0
	,
	# $PlanTemplate.storage.amount
	[Parameter(Mandatory = $false)]
	[int] $QuotaStorage = 10
	,
	# $PlanTemplate.serverAgents.amount
	[Parameter(Mandatory = $false)]
	[int] $QuotaServerAgents = 0
	,
	# $PlanTemplate.workstationAgents.amount
	[Parameter(Mandatory = $false)]
	[int] $QuotaWorkstationAgents = 0
	,
	# $PlanTemplate.appliances.amount
	[Parameter(Mandatory = $false)]
	[int] $QuotaAppliances = 1
)
BEGIN {
	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
	Log-Debug -fn $fn -msg ("CALL. Name: '{0}'" -f $Name) -fac 1;
	
	$fReturn = $false;
	$OutputParameter = @();
	$ParameterSetName = $PSCmdlet.ParameterSetName;
} # BEGIN

PROCESS {
try {
	# Parameter validation
	# N/A

    $PlanTemplate = Get-CteraDefaultsObj -Name 'Plan' | ConvertFrom-CteraObj;
	# set name
	$PlanTemplate.name = $Name;
	# set displayName
	if($DisplayName) { $PlanTemplate.displayName = $DisplayName; }
	#  displayDescription
	if($Description) { $PlanTemplate.displayDescription = $Description; }
	# set retention policy
	if($RetentionPolicyDaily) { $PlanTemplate.retentionPolicy.daily = $RetentionPolicyDaily; }
	if($RetentionPolicyMonthly) { $PlanTemplate.retentionPolicy.monthly = $RetentionPolicyMonthly; }
	if($RetentionPolicyQuarterly) { $PlanTemplate.retentionPolicy.quarterly = $RetentionPolicyQuarterly; }
	if($RetentionPolicyWeekly) { $PlanTemplate.retentionPolicy.weekly = $RetentionPolicyWeekly; }
	if($RetentionPolicyYearly) { $PlanTemplate.retentionPolicy.yearly = $RetentionPolicyYearly; }
	# set trial mode
	if($TrialDays) {
		$PlanTemplate.isTrial = 'true';
		$PlanTemplate.subscriptionPeriod = $TrialDays;
	} else {
		$PlanTemplate.isTrial = 'false';
	} # if
	# set services
	if($ServiceCloudBackupSeeding) {
		($PlanTemplate.services | where serviceName -eq 'Seeding').serviceState = "OK";
	} else {
		($PlanTemplate.services | where serviceName -eq 'Seeding').serviceState = "Disabled";
	} # if
	if($ServiceCloudBackup) {
		($PlanTemplate.services | where serviceName -eq 'Cloud Backup').serviceState = "OK";
	} else {
		($PlanTemplate.services | where serviceName -eq 'Cloud Backup').serviceState = "Disabled";
		($PlanTemplate.services | where serviceName -eq 'Seeding').serviceState = "Disabled";
	} # if
	if($ServiceRemoteAccess) {
		($PlanTemplate.services | where serviceName -eq 'Remote Access').serviceState = "OK";
	} else {
		($PlanTemplate.services | where serviceName -eq 'Remote Access').serviceState = "Disabled";
	} # if
	if($ServiceCloudDriveInvitations) {
		($PlanTemplate.services | where serviceName -eq 'Cloud file sharing').serviceState = "OK";
	} else {
		($PlanTemplate.services | where serviceName -eq 'Cloud file sharing').serviceState = "Disabled";
	} # if
	if($ServiceCloudDrive) {
		($PlanTemplate.services | where serviceName -eq 'Cloud folders').serviceState = "OK";
	} else {
		($PlanTemplate.services | where serviceName -eq 'Cloud folders').serviceState = "Disabled";
		($PlanTemplate.services | where serviceName -eq 'Cloud file sharing').serviceState = "Disabled";
	} # if
	# set availableToEndUsers
	if($AllowJoin) {
		$PlanTemplate.availableToEndUsers = 'true';
	} else {
		$PlanTemplate.availableToEndUsers = 'false';
	} # if
	# set sortIndex
	if($SortIndex) { $PlanTemplate.sortIndex = $SortIndex; }
    # set quota
    [int64] $nAmount = $QuotaStorage;
    $nAmount = $nAmount * (1024 * 1024 * 1024);
    $PlanTemplate.storage.amount = "{0}" -f $nAmount;
	$PlanTemplate.serverAgents.amount = $QuotaServerAgents;
	$PlanTemplate.workstationAgents.amount = $QuotaWorkstationAgents;
	$PlanTemplate.appliances.amount = $QuotaAppliances;

	# format payload
	$Body = Format-CteraExtendedMethod -Name add -Parameters ($PlanTemplate | ConvertTo-CteraXml);

    if($PSCmdlet.ShouldProcess($Name)) {
        $r = Invoke-CteraCommand -Method "POST" -Api 'plans' -Body $Body;
        if(!$r) {
		    $e = New-CustomErrorRecord -m ("Creating plan '{0}' FAILED." -f $Name) -cat NotSpecified -o $Body;
		    throw($gotoError);
        } # if
        $tmpPlan = ConvertFrom-CteraObj -XmlString ("<obj class='#uri'><att id='#uri'>{0}</att></obj>" -f $r);
        Log-Info $fn ("Created plan '{0}' [{1}]." -f $Name, $tmpPlan.'#uri') -Verbose:$Verbose;
	    $OutputParameter = $tmpPlan.Clone();
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
	Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;
} # END
} # function
Export-ModuleMember -Function New-CteraPlan;

function Remove-CteraPlan {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="High",
	HelpURI='http://dfch.biz/PS/Storebox/Api/Remove-CteraPlan/'
)]
[OutputType([hashtable])]
PARAM (
	# $PlanTemplate.name
	[Parameter(Mandatory = $true, Position = 0)]
	[string] $Name
)
BEGIN {
	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
	Log-Debug -fn $fn -msg ("CALL. Name: '{0}'" -f $Name) -fac 1;
	
	$fReturn = $false;
	$OutputParameter = @();
	$ParameterSetName = $PSCmdlet.ParameterSetName;
} # BEGIN

PROCESS {
try {
	# Parameter validation
	# N/A

    if($PSCmdlet.ShouldProcess($Name)) {
 		$r = Invoke-CteraCommand -Method 'DELETE' -Api ("plans/{0}" -f $Name);
        if(!$r) {
		    $e = New-CustomErrorRecord -m ("Deleting plan '{0}' FAILED." -f $Name) -cat NotSpecified -o $Name;
		    throw($gotoError);
        } # if
        $tmpPlan = $r | ConvertFrom-CteraObj;
        Log-Info $fn ("Deleting plan '{0}' SUCCEDED." -f $Name) -Verbose:$Verbose;
	    $OutputParameter = $tmpPlan.Clone();
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
	Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;
} # END
} # function
Export-ModuleMember -Function Remove-CteraPlan;

function Remove-CteraAddOn {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="High",
	HelpURI='http://dfch.biz/PS/Storebox/Api/Remove-CteraAddOn/'
)]
[OutputType([hashtable])]
PARAM (
	# $PlanTemplate.name
	[Parameter(Mandatory = $true, Position = 0)]
	[string] $Name
)
BEGIN {
	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
	Log-Debug -fn $fn -msg ("CALL. Name: '{0}'" -f $Name) -fac 1;
	
	$fReturn = $false;
	$OutputParameter = @();
	$ParameterSetName = $PSCmdlet.ParameterSetName;
} # BEGIN

PROCESS {
try {
	# Parameter validation
	# N/A

    if($PSCmdlet.ShouldProcess($Name)) {
 		$r = Invoke-CteraCommand -Method 'DELETE' -Api ("plans/{0}" -f $Name);
        if(!$r) {
		    $e = New-CustomErrorRecord -m ("Deleting addOn '{0}' FAILED." -f $Name) -cat NotSpecified -o $Name;
		    throw($gotoError);
        } # if
        $tmpPlan = $r | ConvertFrom-CteraObj;
        Log-Info $fn ("Deleting addOn '{0}' SUCCEDED." -f $Name) -Verbose:$Verbose;
	    $OutputParameter = $tmpPlan.Clone();
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
	Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;
} # END
} # function
Export-ModuleMember -Function Remove-CteraAddOn;

function Get-CteraEmailTemplate {
[CmdletBinding(
	HelpURI='http://dfch.biz/PS/Storebox/Api/Get-CteraEmailTemplate/'
)]
Param (
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'name')]
	[string] $Name
	,
	[Parameter(Mandatory = $false, ParameterSetName = 'list')]
	[switch] $ListAvailable = $false
)
BEGIN {
$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. ParameterSetName '{0}'" -f $PsCmdlet.ParameterSetName) -fac 1;
} # BEGIN

PROCESS {
[boolean] $fReturn = $false;
$OutputParameter = $null;

try {
	# Parameter validation
	# N/A

	if($PsCmdlet.ParameterSetName -eq 'list') {
		$Body = Format-CteraExtendedMethod -Name 'getTemplates';
		$Response = Invoke-CteraCommand -Method 'POST' -Api '/' -Body $Body;
		if(!$Response) {
			$e = New-CustomErrorRecord ("Retrieving 'getTemplates' FAILED.") -cat ObjectNotFound -o $Body;
			throw($gotoError);
		} # if
		$aTemplate = $Response | ConvertFrom-CteraObjList;
		$OutputParameter = $aTemplate.Clone();
	} else {
		$Body = Format-CteraExtendedMethod -Name 'getTemplate' -Parameters ('<val>{0}</val>' -f $Name);
		$Response = Invoke-CteraCommand -Method 'POST' -Api '/' -Body $Body;
		if(!$Response) {
			$e = New-CustomErrorRecord ("Retrieving 'getTemplate' '{0}' FAILED." -f $Name) -cat ObjectNotFound -o $Body;
			throw($gotoError);
		} # if
		$Template = $Response | ConvertFrom-CteraObj;
		$OutputParameter = $Template.Clone();
	} # if

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
Export-ModuleMember -Function Get-CteraEmailTemplate;


function Set-CteraEmailTemplate {
[CmdletBinding(
	HelpURI='http://dfch.biz/PS/Storebox/Api/Set-CteraEmailTemplate/'
)]
Param (
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'reset')]
	[string] $Name
	,
	[Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'name')]
	$Template
	,
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'reset')]
	[alias("r")]
	[alias("Revert")]
	[switch] $Reset
)
BEGIN {
$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. ParameterSetName '{0}'" -f $PsCmdlet.ParameterSetName) -fac 1;
} # BEGIN

PROCESS {
[boolean] $fReturn = $false;
$OutputParameter = $null;

try {
	# Parameter validation
	# N/A

	if($PsCmdlet.ParameterSetName -eq 'reset') {
		$Body = Format-CteraExtendedMethod -Name 'unCustomizeTemplate' -Parameters ('<val>{0}</val>' -f $Name);
		$Response = Invoke-CteraCommand -Method 'POST' -Api '/' -Body $Body;
		if($Response) {
			$e = New-CustomErrorRecord -m ("Resetting template '{0}' to default. FAILED." -f $Name) -cat InvalidData -o $Body;
			throw($gotoError);
		} # if
	} else {
		if($Template -is [hashtable]) {
			$Parameters = $Template | ConvertTo-CteraXml;
		} else {
			$Template = $Template | ConvertFrom-CteraObj;
			if(!$Temmplate) {
				$e = New-CustomErrorRecord -m ("Template contains no valid XML data. Conversion FAILED.") -cat InvalidData -o $Template;
				throw($gotoError);
			} # if
			$Parameters = $Template;
		} # if
		if(!$Template.Contains('name')) {
			$e = New-CustomErrorRecord -m ("Template contains no name.") -cat InvalidData -o $Template;
			throw($gotoError);
		} # if
		$Name = $Template.Name;
		$Body = Format-CteraExtendedMethod -Name 'customizeTemplate' -Parameters ($Template | ConvertTo-CteraXml);
		$Response = Invoke-CteraCommand -Method 'POST' -Api '/' -Body $Body;
		if($Response) {
			$e = New-CustomErrorRecord -m ("Setting template '{0}' FAILED." -f $Name) -cat InvalidData -o $Body;
			throw($gotoError);
		} # if
	} # if

	$Body = Format-CteraExtendedMethod -Name 'getTemplate' -Parameters ('<val>{0}</val>' -f $Name);
	$Response = Invoke-CteraCommand -Method 'POST' -Api '/' -Body $Body;
	if(!$Response) {
		$e = New-CustomErrorRecord ("Retrieving 'getTemplate' '{0}' FAILED." -f $Name) -cat ObjectNotFound -o $Body;
		throw($gotoError);
	} # if
	$Template = $Response | ConvertFrom-CteraObj;
	$OutputParameter = $Template.Clone();

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
Export-ModuleMember -Function Set-CteraEmailTemplate;

<#
 # ########################################
 # Version history
 # ########################################
 #
 # 2014-10-10; ckreissl; ADD: Invoke-CteraFileTransfer, add help example 
 # 2013-12-15; rrink; CHG: Invoke-CteraRestCall, moved $wc.Dispose() to finally
 # 2013-12-15; rrink; CHG: Invoke-CteraFileTransfer, moved $wc.Dispose() to finally
 # 2013-11-27; rrink; CHG: Invoke-CteraFileTransfer, Parameter validation for PortalName
 # 2013-11-27; rrink; CHG: Enter-Ctera, for non global logins the PortalName property on $biz_dfch_PS_Storebox_Api will be set after login
 # 2013-11-18; rrink; CHG: Global, HelpUri 'vCD/Utilities' to 'Storebox/Api'
 # 2013-08-14; rrink; ADD: Set-CteraEmailTemplate, new Cmdlet to set / update email templates
 # 2013-08-14; rrink; ADD: Get-CteraEmailTemplate, new Cmdlet to get email templates
 # 2013-08-14; rrink; ADD: Format-CteraExtendedMethod, Add 'getTemplates', 'getTemplate', 'unCustomizeTemplate' and 'customizeTemplate' value for Name parameter (for email templates)
 # 2013-08-14; rrink; ADD: New-CteraLocalUser, Add "Global" parameter to support creation of global administrators and portal staff users
 # 2013-08-14; rrink; ADD: Get-CteraDefaultsObj, Add "PortalAdmin" value for class parameter
 # 2013-08-14; rrink; CHG: Select-Storebox, Replace "AdminPortal" parameter with "Global"
 # 2013-08-14; rrink; CHG: Enter-Storebox, Replace "GlobalLogin" parameter with "Global"
 # 2013-08-14; rrink; ADD: Remove-CteraAddOn; new Cmdlet to delete addOns
 # 2013-08-14; rrink; ADD: New-CteraAddOn, new Cmdlet to create addOns
 # 2013-08-14; rrink; ADD: Remove-CteraPlan; new Cmdlet to delete plans
 # 2013-08-14; rrink; ADD: New-CteraPlan, new Cmdlet to create plans
 # 2013-08-13; rrink; CHG: ConvertTo-CteraXml, FIX handling of integers (now same as string); corrected error message for unexpected object type
 # 2013-08-01; rrink; CHG: Enter-Storebox, Uri can now end with an trailing "/" and is converted to [Uri] datatype before first use
 # 2013-08-01; rrink; CHG: Enter-Storebox, Replace "UriPortal" parameter with "Uri"
 # 2013-07-24; rrink; ADD: Invoke-CteraRestCommand, ErrorLogging on WebException. The actual response is now displayed as Log-Critical
 # 2013-07-24; rrink; CHG: Enter-Ctera, Corrected examples help
 # 2013-07-24; rrink; CHG: Enter-Ctera, Corrected UrlEncoding on user/pass parameters in HTML payload on login
 #
 # ########################################
 #>
