function Get-DefaultsObj {
[CmdletBinding(
	HelpURI='http://dfch.biz/biz/dfch/PS/Storebox/Api/Get-DefaultsObj/'
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
			$Response = Invoke-Command -Api '/';
		} else {
			$Response = Invoke-Command -Api ("defaults/{0}" -f $Name);
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
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;
} # END

} # Get-DefaultsObj
Set-Alias -Name Get-ObjTemplate -Value Get-DefaultsObj;
Export-ModuleMember -Function Get-DefaultsObj -Alias Get-ObjTemplate;

