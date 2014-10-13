function New-Portal {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="High",
	HelpURI='http://dfch.biz/PS/Storebox/Api/New-Portal/'
)]
[OutputType([String])]
Param (
	[Parameter(Mandatory = $true, Position = 0)]
	[Alias('n')]
	[string] $Name
    ,
	[Parameter(Mandatory = $true, Position = 1, ParameterSetName = 't')]
	[Alias('t')]
	[switch] $TeamPortal
    ,
	[Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'r')]
	[Alias('r')]
	[switch] $ResellerPortal
    ,
	[Parameter(Mandatory = $false, Position = 1)]
	[Alias('p')]
	[Alias('Subscription')]
	[string] $Plan = $biz_dfch_PS_Storebox_Api.DefaultPlan
    ,
	[Parameter(Mandatory = $false, Position = 1)]
	[Alias('e')]
	[datetime] $Expiration
    ,
	[Parameter(Mandatory = $false, Position = 3)]
	[Alias('a')]
	$AddOn
    ,
	[Parameter(Mandatory = $false, Position = 2)]
	[Alias('c')]
	[string] $Comment
    ,
	[Parameter(Mandatory = $false, Position = 4)]
	[Alias('billing')]
	[Alias('BillingID')]
	[int] $externalPortalId = $null
    ,
	[Parameter(Mandatory = $false, ParameterSetName = 'r')]
	[Alias('q')]
	[switch] $enableResellerProvisioning = $true
)
BEGIN {
$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. countLimit '{0}'" -f $countLimit) -fac 1;

#$oPortalSlim = ("<obj class='#uri'><att id='name'>{0}</att></obj>" -f (Invoke-Command name)) | ConvertFrom-Obj;
$oPortalSelected = Invoke-Command / | ConvertFrom-Obj;
$null = Select-Portal -AdminPortal;

} # BEGIN

PROCESS {
[boolean] $fReturn = $false;
$OutputParameter = $null;

try {
	# Parameter validation
	# N/A

    if($PSCmdlet.ParameterSetName -eq 'r') {
        $Uri = 'resellerPortals';
        $oResellerPortalDefault = Get-DefaultsObj -Name ResellerPortal | ConvertFrom-Obj;
        $oResellerPortalDefault.enableResellerProvisioning = $enableResellerProvisioning -as [string];
        if(!$enableResellerProvisioning -and $Plan) { 
            $e = New-CustomErrorRecord -m ("Conflicting arguments. You must not specify a subscription plan ['{0}'] when 'enableResellerProvisioning' is disabled ['{1}']." -f $Plan, $enableResellerProvisioning) -cat InvalidArgument -o $PSCmdlet.MyInvocation;
            throw($gotoError);
        } # if
        $oPortalDefault = $oResellerPortalDefault;
    } elseif($PSCmdlet.ParameterSetName -eq 't') {
        $Uri = 'teamPortals';
        $oTeamPortalDefault = Get-DefaultsObj -Name TeamPortal | ConvertFrom-Obj;
        $oTeamPortalDefault.portalType = 'team';
        $oPortalDefault = $oTeamPortalDefault;

    } else {
        $e = New-CustomErrorRecord -m ("Unsupported ParameterSetName '{0}'." -f $PSCmdlet.ParameterSetName) -cat InvalidArgument -o $PSCmdlet.ParameterSetName;
        throw($gotoError);
    } # if

    $oPortalDefault.name = [System.Web.HttpUtility]::HtmlEncode($Name);
    $oPortalDefault.comment = [System.Web.HttpUtility]::HtmlEncode($Comment);
    if($externalPortalId) { $oPortalDefault.externalPortalId = [System.Web.HttpUtility]::HtmlEncode($externalPortalId -as [string]); }

    if($Plan) {
        $oPlan = Invoke-Command ('plans/{0}' -f $Plan) | ConvertFrom-Obj
        if(!$oPlan) {
            $e = New-CustomErrorRecord -m ("Invalid plan name: '{0}'." -f $Plan) -cat ObjectNotFound -o $Plan;
            throw($gotoError);
        } # if
        $oPortalDefault.plan = 'objs/{0}' -f $oPlan.uid;
    } # if

    $oPortalDefault.portalAddOns = @();
    $oUserAddOnDefault = Get-DefaultsObj -Name UserAddOn | ConvertFrom-Obj;
    $oUserAddOnDefault.startDate = [datetime]::Now.ToString('yyyy-MM-dd');
    $htAddOns = @{};
    foreach($a in $AddOn) {
        if(!$htAddOns.Contains($a)) {
            $oAddOn = Invoke-Command ('addOns/{0}' -f $a) | ConvertFrom-Obj;
            if($oAddOn) { $htAddOns.Add($a, $oAddOn); }
        } # if
        if(!$htAddOns.Contains($a)) {
            $e = New-CustomErrorRecord -m ("Invalid addOn name: '{0}'." -f $a) -cat ObjectNotFound -o $AddOn;
            throw($gotoError);
        } # if
        $oUserAddOn = $oUserAddOnDefault.Clone();
        $oUserAddOn.addOn = 'objs/{0}' -f $oAddOn.uid;
        $oPortalDefault.portalAddOns += $oUserAddOn.Clone();
        Log-Info $fn ("AddOn: '{0}' [{1}]" -f $htAddOns.$a.name, $htAddOns.$a.uid) -v;
    } # foreach

    $Body = Format-ExtendedMethod -Name add -Parameters ($oPortalDefault | ConvertTo-Xml);
    $msg = "Creating '{0}' '{1}' with plan '{2}' ..." -f $oPortalDefault.'#class', $oPortalDefault.name, $Plan;
	Log-Info $fn $msg -v;
	if(!$PSCmdlet.ShouldProcess($msg)) {
		$fReturn = $false;
		throw($gotoFailure);
	} # if
    $r = Invoke-Command -Method POST -Api $Uri -Body $Body;
    if(!$r) {
        $e = New-CustomErrorRecord -m ("Creating '{0}' '{1}' with plan '{2}' FAILED." -f $oPortalDefault.portalType, $oPortalDefault.name, $Plan) -cat InvalidData -o $Body;
        throw($gotoError);
    } # if
    Log-Notice $fn ("Creating '{0}' '{1}' with plan '{2}' SUCCEEDED [{3}]." -f $oPortalDefault.'#class', $oPortalDefault.name, $Plan, $r) -v;
	$OutputParameter = ("<obj class='#uri'><att id='#uri'>{0}</att></obj>" -f $r) | ConvertFrom-Obj;
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
#if($oPortalSelected.uid -ne 1) {
#    $null = Select-Portal -Name $oPortalSlim.name;
#} # if
return $OutputParameter;

$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;
} # END

} # New-Portal
Export-ModuleMember -Function New-Portal;

