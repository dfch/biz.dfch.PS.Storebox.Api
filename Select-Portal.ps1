function Select-Portal {
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

Select-Portal -UriPortal 'https://promo.ds01.swisscom.com' -Username 'PeterLustig' -Password 'S0nnensch3!n'



.EXAMPLE

Perform a login to a StoreBox server with username and encrypted password.

Select-Portal -UriPortal 'https://promo.ds01.swisscom.com' -Username 'PeterLustig' -Credentials [PSCredentials]



.LINK

Online Version: http://dfch.biz/biz/dfch/PSStorebox/Api/Select-Portal/
Enter-Ctera



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

#>
	[CmdletBinding(
		HelpURI='http://dfch.biz/biz/dfch/PSStorebox/Api/Select-Portal/'
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
            $response = Invoke-Command -Method PUT -Api currentPortal -Body $Body;

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
Set-Alias -Name Select-Storebox -Value Select-Portal;
Export-ModuleMember -Function Select-Portal -Alias Select-Storebox;

