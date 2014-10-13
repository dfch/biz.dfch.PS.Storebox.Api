function Get-Portal {
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

Get-Portal -UriPortal 'https://promo.ds01.swisscom.com' -Username 'PeterLustig' -Password 'S0nnensch3!n'



.EXAMPLE

Perform a login to a StoreBox server with username and encrypted password.

Get-Portal -UriPortal 'https://promo.ds01.swisscom.com' -Username 'PeterLustig' -Credentials [PSCredentials]



.LINK

Online Version: http://dfch.biz/PS/Storebox/Api/Get-Portal/
Enter-Ctera



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

#>
	[CmdletBinding(
		HelpURI='http://dfch.biz/PS/Storebox/Api/Get-Portal/'
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
				$null = Select-Portal -AdminPortal;

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
					$null = Select-Portal -PortalName $PortalName;
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
Export-ModuleMember -Function Get-Portal;

