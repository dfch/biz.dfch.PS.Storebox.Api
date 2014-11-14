function Get-Entity {
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

Get-Entity -UriPortal 'https://promo.ds01.swisscom.com' -Username 'PeterLustig' -Password 'S0nnensch3!n'



.EXAMPLE

Perform a login to a StoreBox server with username and encrypted password.

Get-Entity -UriPortal 'https://promo.ds01.swisscom.com' -Username 'PeterLustig' -Credentials [PSCredentials]



.LINK

Online Version: http://dfch.biz/biz/dfch/PS/Storebox/Api/Get-Entity/
Enter-Ctera



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

#>
	[CmdletBinding(
		HelpURI='http://dfch.biz/biz/dfch/PS/Storebox/Api/Get-Entity/'
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
Export-ModuleMember -Function Get-Entity;

