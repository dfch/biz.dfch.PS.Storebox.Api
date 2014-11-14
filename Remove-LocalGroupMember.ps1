function Remove-LocalGroupMember {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="High",
	HelpURI='http://dfch.biz/biz/dfch/PSStorebox/Api/Remove-LocalGroupMember/'
)]
PARAM (
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'name')]
	[string] $Name
	,
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'id')]
	[alias('uid')]
	[int] $id
	,
	[Parameter(ValueFromPipeline = $true, Mandatory = $true)]
	[alias('del')]
	[alias('Member')]
	[string[]] $RemoveMember
)
BEGIN {
try {
	# Parameter validation
	# N/A
	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
	Log-Debug -fn $fn -msg ("CALL. ParameterSetName: '{0}'" -f $PSCmdlet.ParameterSetName) -fac 1;
	
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

    $aMembers = New-Object System.Collections.ArrayList;
    foreach($User in $olocalGroup.Users) {
        if(!$aMembers.Contains($User)) { $aMembers.Add($User); }
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
				$PSCmdlet.ThrowTerminatingError($_);
			} else {
				$PSCmdlet.ThrowTerminatingError($_);
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
    foreach($Member in $RemoveMember) {
        $sUser = Invoke-Command ("{0}/{1}" -f 'users', $Member);
        $oUser = ConvertFrom-Obj -XmlString $sUser;
	    if(!$oUser) {
		    $e = New-CustomErrorRecord -m ("Retrieving localUser name '{0}' FAILED." -f $Member) -cat ConnectionError -o $Member;
		    throw($gotoError);
	    } # if
        foreach($ExistingMember in $aMembers) {
            if($ExistingMember -match ("^objs/{0}" -f $oUser.uid)) {
                $aMembers.Remove($ExistingMember);
                break;
            } # if
        } # foreach
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
				$PSCmdlet.ThrowTerminatingError($_);
			} else {
				$PSCmdlet.ThrowTerminatingError($_);
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
	# Removing members from group
    if($aMembers.Count -le 0) {
        $ListVal = '<list />';
    } else {
        $ListVal = New-ListVal -Values $aMembers;
    } # if
    $attUsers = $xlocalGroup.obj.SelectSingleNode("att[@id = 'users']")
    $attUsers.set_InnerXML($ListVal);
    $Body = $xlocalGroup.OuterXml;

	$Uri = "objs/{0}" -f $olocalGroup.uid;
	Log-Info $fn ("Removing '{2}' members ['{3}'] from localGroup '{0}' [{1}] ..." -f $olocalGroup.Name, $olocalGroup.uid, $RemoveMember.Count, ($RemoveMember -join ' ')) -Verbose:$true;
	if($PSCmdlet.ShouldProcess($RemoveMember -join ' ')) {
		$r = Invoke-Command -Method 'PUT' -Api $Uri -Body $Body;
        if(!$r) {
		    $e = New-CustomErrorRecord -m ("Removing members from localGroup '{0}' [{1}] FAILED." -f $olocalGroup.Name, $olocalGroup.uid) -cat NotSpecified -o $Body;
		    throw($gotoError);
        } # if
        $tmpLocalGroup = ConvertFrom-Obj -XmlString $r;
        Log-Info $fn ("Removing members from localGroup '{0}' [{1}] SUCCEEDED." -f $Name, $oLocalGroup.'#uri') -Verbose:$Verbose;
        $OutputParameter = $tmpLocalGroup.Clone();
	} # if

	$datEnd = [datetime]::Now;
	Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;

	return $OutputParameter;
} # END

} # function
Export-ModuleMember -Function Remove-LocalGroupMember;

