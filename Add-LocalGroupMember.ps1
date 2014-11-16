function Add-LocalGroupMember {
[CmdletBinding(
    SupportsShouldProcess = $true
	,
    ConfirmImpact = "Medium"
	,
	HelpURI = 'http://dfch.biz/biz/dfch/PS/Storebox/Api/Add-LocalGroupMember/'
)]
PARAM (
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'name')]
	[string] $Name
	,
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'id')]
	[alias('idPortal')]
	[alias('uid')]
	[int] $id
	,
	[Parameter(ValueFromPipeline = $true, Mandatory = $true, Position = 1)]
	[alias('add')]
	[alias('Member')]
	[string[]] $NewMember
	,
	[Parameter(Mandatory = $false)]
	[switch] $MemberAsUid = $false
	,
	[ValidateRange(0,1)]
	[Parameter(Mandatory = $false)]
	[double] $Threshold = 0.1
)
BEGIN {
try {
	# Parameter validation
	# N/A
	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
	Log-Debug -fn $fn -msg ("CALL. NewMember: '{0}'. ParameterSetName: '{0}'" -f $NewMember.Count, $PSCmdlet.ParameterSetName) -fac 1;
	
	[boolean] $fBulk = $false;
	$r = Invoke-Command 'status/totalUsers';
	$dbStatusSlim = ("<obj class='user-defined' ><att id='totalUsers' >{0}</att></obj>" -f $r) | ConvertFrom-Obj;
	$UriUsers = 'users';
	if( ($NewMember.Count -gt 10) -and ($NewMember.Count -gt $dbStatusSlim.totalUsers * $Threshold) ) {
		Log-Debug $fn ("Specified number of users '{0}' exceeds threshold '{1}' of total number of users '{2}'. Processing users in bulk operation." -f $NewMember.Count, $Threshold, $dbStatusSlim.totalUsers);
		$oUsers = Invoke-Command $UriUsers | ConvertFrom-ObjList;
		$fBulk = $true;
	} # if

	$fReturn = $false;
	$OutputParameter = $null;
    $PSParameterNameSet = $PSCmdlet.ParameterSetName;

	$UriLocalGroups = 'localGroups';
    $UriObjs = 'objs';

    if($PSParameterNameSet -eq 'name') {
    	$slocalGroup = Invoke-Command ( "{0}/{1}" -f $UriLocalGroups, $Name);
    } elseif($PSParameterNameSet -eq 'id') {
    	$slocalGroup = Invoke-Command ( "{0}/{1}" -f $UriObjs, $id);
    } else {
        $e = New-CustomErrorRecord -m "" -cat InvalidArgument -o $PSCmdlet.ParameterSetName;
        throw($gotoError);
        # N/A
    } # if
	$olocalGroup = ConvertFrom-Obj -XmlString $slocalGroup;
	if(!$olocalGroup) {
		$e = New-CustomErrorRecord -m ("Retrieving and converting group names FAILED.") -cat ConnectionError -o $olocalGroup;
		throw($gotoError);
	} # if
    [xml] $xlocalGroup = $slocalGroup;

    $aMembers = @();
    foreach($User in $olocalGroup.Users) {
        $aMembers += $User;
    } # foreach

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

} # BEGIN
PROCESS {
try {
	# Parameter validation
	# N/A

    foreach($Member in $NewMember) {
		if(!$MemberAsUid) {
			if($fBulk) {
				$sUser = ($ousers |? name -eq $Member).'#xml';
			} else {
				$sUser = Invoke-Command ("{0}/{1}" -f $UriUsers, $Member);
			} # if
			$oUser = ConvertFrom-Obj -XmlString $sUser;
			if(!$oUser) {
				$e = New-CustomErrorRecord -m ("Retrieving localUser name '{0}' FAILED." -f $Member) -cat ConnectionError -o $Member;
				throw($gotoError);
			} # if
		} else {
			if(![int]::Parse($Member)) {
				$e = New-CustomErrorRecord -m ("Converting uid '{0}' for localUser name FAILED." -f $Member) -cat InvalidArg -o $Member;
				throw($gotoError);
			} # if
			$id = [int]::Parse($Member);
			$oUser = @{};
			$oUser.uid = $id;
		} # if
        $aMembers += ("objs/{0}" -f $oUser.uid);
    } # foreach

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
	# Adding members to group
    $ListVal = New-ListVal -Values $aMembers;
    $attUsers = $xlocalGroup.obj.SelectSingleNode("att[@id = 'users']")
    $attUsers.set_InnerXML($ListVal);
    $Body = $xlocalGroup.OuterXml;

	$Uri = "objs/{0}" -f $olocalGroup.uid;
	Log-Info $fn ("Adding members to localGroup '{0}' [{1}] ..." -f $olocalGroup.Name, $olocalGroup.uid) -Verbose:$true;
	if($PSCmdlet.ShouldProcess($aMembers)) {
		$r = Invoke-Command -Method 'PUT' -Api $Uri -Body $Body;
        if(!$r) {
		    $e = New-CustomErrorRecord -m ("Adding members to localGroup '{0}' [{1}] FAILED." -f $olocalGroup.Name, $olocalGroup.uid) -cat NotSpecified -o $Body;
		    throw($gotoError);
        } # if
        $tmpLocalGroup = ConvertFrom-Obj -XmlString $r;
        Log-Info $fn ("Adding members to localGroup '{0}' [{1}] SUCCEEDED." -f $Name, $oLocalGroup.'#uri') -Verbose:$Verbose;
        $OutputParameter = $tmpLocalGroup.Clone();
	} # if

	$datEnd = [datetime]::Now;
	Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;

	return $OutputParameter;
} # END

} # function
Export-ModuleMember -Function Add-LocalGroupMember;

