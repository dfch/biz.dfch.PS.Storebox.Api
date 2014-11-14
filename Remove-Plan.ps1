function Remove-Plan {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="High",
	HelpURI='http://dfch.biz/biz/dfch/PS/Storebox/Api/Remove-Plan/'
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
 		$r = Invoke-Command -Method 'DELETE' -Api ("plans/{0}" -f $Name);
        if(!$r) {
		    $e = New-CustomErrorRecord -m ("Deleting plan '{0}' FAILED." -f $Name) -cat NotSpecified -o $Name;
		    throw($gotoError);
        } # if
        $tmpPlan = $r | ConvertFrom-Obj;
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
Export-ModuleMember -Function Remove-Plan;

