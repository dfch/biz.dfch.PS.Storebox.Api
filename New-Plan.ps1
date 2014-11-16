function New-Plan {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium",
	HelpURI='http://dfch.biz/biz/dfch/PS/Storebox/Api/New-Plan/'
)]
[OutputType([hashtable])]
PARAM (
	# $PlanTemplate.name
	[Parameter(Mandatory = $true, Position = 0)]
	[string] $Name
	,
	# $PlanTemplate.displayName
	[Parameter(Mandatory = $false, Position = 1)]
	[string] $DisplayName = ''
	,
	#  $PlanTemplate.displayDescription
	[Parameter(Mandatory = $false, Position = 2)]
	[string] $Description = ''
	,
	# $PlanTemplate.retentionPolicy.daily
	[Parameter(Mandatory = $false)]
	[int] $RetentionPolicyDaily = 7
	,
	# $PlanTemplate.retentionPolicy.monthly
	[Parameter(Mandatory = $false)]
	[int] $RetentionPolicyMonthly = 0
	,
	#$PlanTemplate.retentionPolicy.quarterly
	[Parameter(Mandatory = $false)]
	[int] $RetentionPolicyQuarterly = 0
	,
	#$PlanTemplate.retentionPolicy.weekly
	[Parameter(Mandatory = $false)]
	[int] $RetentionPolicyWeekly = 4
	,
	#$PlanTemplate.retentionPolicy.yearly
	[Parameter(Mandatory = $false)]
	[int] $RetentionPolicyYearly = 0
	,
	# $PlanTemplate.isTrial = 'true'
	# $PlanTemplate.subscriptionPeriod = $TrialDays
	[Parameter(Mandatory = $false)]
	[int] $TrialDays = 0
	,
	#  ($PlanTemplate.services|where serviceName -eq 'Cloud Backup').serviceState = "Disabled"
	[Parameter(Mandatory = $false)]
	[switch] $ServiceCloudBackup = $true
	,
	#  ($PlanTemplate.services|where serviceName -eq 'Seeding').serviceState = "Disabled"
	[Parameter(Mandatory = $false)]
	[switch] $ServiceCloudBackupSeeding = $true
	,
	#  ($PlanTemplate.services|where serviceName -eq 'Remote Access').serviceState = "Disabled"
	[Parameter(Mandatory = $false)]
	[switch] $ServiceRemoteAccess = $true
	,
	#  ($PlanTemplate.services|where serviceName -eq 'Cloud folders').serviceState = "Disabled"
	[Parameter(Mandatory = $false)]
	[switch] $ServiceCloudDrive = $true
	,
	#  ($PlanTemplate.services|where serviceName -eq 'Cloud file sharing').serviceState = "Disabled"
	[Parameter(Mandatory = $false)]
	[switch] $ServiceCloudDriveInvitations = $true
	,
	# $PlanTemplate.availableToEndUsers
	[Parameter(Mandatory = $false)]
	[switch] $AllowJoin = $false
	,
	# $PlanTemplate.sortIndex
	[Parameter(Mandatory = $false)]
	[int] $SortIndex = 0
	,
	# $PlanTemplate.storage.amount
	[Parameter(Mandatory = $false)]
	[int] $QuotaStorage = 10
	,
	# $PlanTemplate.serverAgents.amount
	[Parameter(Mandatory = $false)]
	[int] $QuotaServerAgents = 0
	,
	# $PlanTemplate.workstationAgents.amount
	[Parameter(Mandatory = $false)]
	[int] $QuotaWorkstationAgents = 0
	,
	# $PlanTemplate.appliances.amount
	[Parameter(Mandatory = $false)]
	[int] $QuotaAppliances = 1
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

    $PlanTemplate = Get-DefaultsObj -Name 'Plan' | ConvertFrom-Obj;
	# set name
	$PlanTemplate.name = $Name;
	# set displayName
	if($DisplayName) { $PlanTemplate.displayName = $DisplayName; }
	#  displayDescription
	if($Description) { $PlanTemplate.displayDescription = $Description; }
	# set retention policy
	if($RetentionPolicyDaily) { $PlanTemplate.retentionPolicy.daily = $RetentionPolicyDaily; }
	if($RetentionPolicyMonthly) { $PlanTemplate.retentionPolicy.monthly = $RetentionPolicyMonthly; }
	if($RetentionPolicyQuarterly) { $PlanTemplate.retentionPolicy.quarterly = $RetentionPolicyQuarterly; }
	if($RetentionPolicyWeekly) { $PlanTemplate.retentionPolicy.weekly = $RetentionPolicyWeekly; }
	if($RetentionPolicyYearly) { $PlanTemplate.retentionPolicy.yearly = $RetentionPolicyYearly; }
	# set trial mode
	if($TrialDays) {
		$PlanTemplate.isTrial = 'true';
		$PlanTemplate.subscriptionPeriod = $TrialDays;
	} else {
		$PlanTemplate.isTrial = 'false';
	} # if
	# set services
	if($ServiceCloudBackupSeeding) {
		($PlanTemplate.services | where serviceName -eq 'Seeding').serviceState = "OK";
	} else {
		($PlanTemplate.services | where serviceName -eq 'Seeding').serviceState = "Disabled";
	} # if
	if($ServiceCloudBackup) {
		($PlanTemplate.services | where serviceName -eq 'Cloud Backup').serviceState = "OK";
	} else {
		($PlanTemplate.services | where serviceName -eq 'Cloud Backup').serviceState = "Disabled";
		($PlanTemplate.services | where serviceName -eq 'Seeding').serviceState = "Disabled";
	} # if
	if($ServiceRemoteAccess) {
		($PlanTemplate.services | where serviceName -eq 'Remote Access').serviceState = "OK";
	} else {
		($PlanTemplate.services | where serviceName -eq 'Remote Access').serviceState = "Disabled";
	} # if
	if($ServiceCloudDriveInvitations) {
		($PlanTemplate.services | where serviceName -eq 'Cloud file sharing').serviceState = "OK";
	} else {
		($PlanTemplate.services | where serviceName -eq 'Cloud file sharing').serviceState = "Disabled";
	} # if
	if($ServiceCloudDrive) {
		($PlanTemplate.services | where serviceName -eq 'Cloud folders').serviceState = "OK";
	} else {
		($PlanTemplate.services | where serviceName -eq 'Cloud folders').serviceState = "Disabled";
		($PlanTemplate.services | where serviceName -eq 'Cloud file sharing').serviceState = "Disabled";
	} # if
	# set availableToEndUsers
	if($AllowJoin) {
		$PlanTemplate.availableToEndUsers = 'true';
	} else {
		$PlanTemplate.availableToEndUsers = 'false';
	} # if
	# set sortIndex
	if($SortIndex) { $PlanTemplate.sortIndex = $SortIndex; }
    # set quota
    [int64] $nAmount = $QuotaStorage;
    $nAmount = $nAmount * (1024 * 1024 * 1024);
    $PlanTemplate.storage.amount = "{0}" -f $nAmount;
	$PlanTemplate.serverAgents.amount = $QuotaServerAgents;
	$PlanTemplate.workstationAgents.amount = $QuotaWorkstationAgents;
	$PlanTemplate.appliances.amount = $QuotaAppliances;

	# format payload
	$Body = Format-ExtendedMethod -Name add -Parameters ($PlanTemplate | ConvertTo-Xml);

    if($PSCmdlet.ShouldProcess($Name)) {
        $r = Invoke-Command -Method "POST" -Api 'plans' -Body $Body;
        if(!$r) {
		    $e = New-CustomErrorRecord -m ("Creating plan '{0}' FAILED." -f $Name) -cat NotSpecified -o $Body;
		    throw($gotoError);
        } # if
        $tmpPlan = ConvertFrom-Obj -XmlString ("<obj class='#uri'><att id='#uri'>{0}</att></obj>" -f $r);
        Log-Info $fn ("Created plan '{0}' [{1}]." -f $Name, $tmpPlan.'#uri') -Verbose:$Verbose;
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
	Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;
} # END
} # function
Export-ModuleMember -Function New-Plan;

