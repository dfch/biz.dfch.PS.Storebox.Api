function New-ListVal {
[CmdletBinding(
	HelpURI='http://dfch.biz/biz/dfch/PS/Storebox/Api/New-ListVal/'
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
Export-ModuleMember -Function New-ListVal;

