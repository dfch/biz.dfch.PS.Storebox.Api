function Get-Time {
[CmdletBinding(
	HelpURI='http://dfch.biz/biz/dfch/PS/Storebox/Api/Get-Time/'
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

	$Response = Invoke-Command -Api 'currentTime';
	$OutputParameter = $Response | ConvertFrom-Obj;
			
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

} # Get-Time
Export-ModuleMember -Function Get-Time;

