function Get-Logs {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Low",
	HelpURI='http://dfch.biz/biz/dfch/PSStorebox/Api/Get-Logs/'
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
$oParameters = $sParameters | ConvertFrom-Obj;

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

	$sParameters = $oParameters | ConvertTo-Xml;
	$Body = Format-ExtendedMethod -Name 'queryLogs' -Parameters $sParameters;
	$r = Invoke-Command -Method 'POST' -Api '/' -Body $Body;
	$msg = "Retrieving '{0}' log entries (from '{1}') with minSeverity '{2}' ..." -f $countLimit, $startFrom, $minSeverity;
	if(!$PSCmdlet.ShouldProcess($msg)) {
		$fReturn = $false;
		throw($gotoFailure);
	} # if
	Log-Debug $fn $msg;
	$OutputParameter = $r | ConvertFrom-Obj;
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

} # Get-Logs
Export-ModuleMember -Function Get-Logs;

