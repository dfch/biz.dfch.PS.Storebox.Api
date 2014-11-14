function New-LocalGroup {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium",
	HelpURI='http://dfch.biz/biz/dfch/PSStorebox/Api/New-LocalGroup/'
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
	$Body = Format-ExtendedMethod -Name add -Parameters $Defaults.OuterXml;
	# Create group
	$UriLocalGroups = 'localGroups'
	if($PSCmdlet.ShouldProcess($Name)) {
	    $r = Invoke-Command -Method 'POST' -Api $UriLocalGroups -Body $Body;
        if(!$r) {
		    $e = New-CustomErrorRecord -m ("Creating localGroup '{0}' FAILED." -f $Name) -cat NotSpecified -o $Body;
		    throw($gotoError);
        } # if
        $tmpLocalGroup = ConvertFrom-Obj -XmlString ("<obj class='#uri'><att id='#uri'>{0}</att></obj>" -f $r);
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
Export-ModuleMember -Function New-LocalGroup;

