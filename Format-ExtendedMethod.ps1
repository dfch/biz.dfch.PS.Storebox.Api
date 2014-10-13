function Format-ExtendedMethod {
	[CmdletBinding(
		HelpURI='http://dfch.biz/PS/Storebox/Api/Format-ExtendedMethod/'
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
} # Format-ExtendedMethod
Set-Alias -Name Format-SBExtendedMethod -Value Format-ExtendedMethod;
Export-ModuleMember -Function Format-ExtendedMethod;

