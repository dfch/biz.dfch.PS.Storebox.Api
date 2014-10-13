function Get-LocalGroup {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium",
	HelpURI='http://dfch.biz/PS/Storebox/Api/Get-LocalGroup/'
)]
PARAM (
	[Parameter(ValueFromPipeline = $true, Mandatory = $true, Position = 0, ParameterSetName = 'name')]
	[string] $Name
	,
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'id')]
	[alias('uid')]
	[int] $id
	,
	[Parameter(Mandatory = $false, ParameterSetName = 'list')]
	[alias('all')]
	[switch] $ListAvailable = $true
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
	$UriLocalGroups = 'localGroups'
	
	$slocalGroups = Invoke-Command $UriLocalGroups;
	$olocalGroups = ConvertFrom-ObjList -XmlString $slocalGroups;
	if(!$olocalGroups) {
		$e = New-CustomErrorRecord -m ("Retrieving and converting group names FAILED.") -cat ConnectionError -o $olocalGroups;
		throw($gotoError);
	} # if
	if(($PSCmdlet.ParameterSetName -eq 'list') -and $ListAvailable) {
		$OutputParameter = $olocalGroups.Clone();
		throw($gotoSuccess);
	} # if
    $OutputParameter = @();
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

	if($PSCmdlet.ParameterSetName -eq 'name') {
        $fReturn = $false;
        $olocalGroup = $null;
        foreach($olocalGroup in $olocalGroups) { 
            if($olocalGroup.name -eq $Name) { $fReturn = $true; break; } # if
        } # foreach
		if(!$fReturn) {
			$e = New-CustomErrorRecord -m ("Getting localGroup FAILED. Group '{0}' not found." -f $Name) -cat ObjectNotFound -o $olocalGroups;
            throw($gotoError);
		} # if
        $OutputParameter += $olocalGroup.Clone();
	} elseif($PSCmdlet.ParameterSetName -eq 'id') {
        $fReturn = $false;
        $olocalGroup = $null;
        foreach($olocalGroup in $olocalGroups) { 
            if($olocalGroup.uid -eq $id) { $fReturn = $true; break; } # if
        } # foreach
		if(!$fReturn) {
			$e = New-CustomErrorRecord -m ("Getting localGroup FAILED. Group id '{0}' not found." -f $id) -cat ObjectNotFound -o $olocalGroups;
            throw($gotoError);
		} # if
        $OutputParameter += $olocalGroup.Clone();
	} elseif($PSCmdlet.ParameterSetName -eq 'list') {
		# N/A
        # already handled in BEGIN block
    } else {
        $e = New-CustomErrorRecord -m ("Invalid ParameterSetName encountered: '{0}'." -f $PSCmdlet.ParameterSetName) -cat InvalidArgument -o $PSCmdlet.ParameterSetName;
		Log-Error $fn $e.Exception.Message;
		throw($gotoError);
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

    if($OutputParameter -and $OutputParameter -is [Array] -and $OutputParameter.Count -eq 1) {
        $OutputParameter = $OutputParameter[0];
    } # if
	$datEnd = [datetime]::Now;
	Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;

	return $OutputParameter;
} # END

} # function
Export-ModuleMember -Function Get-LocalGroup;

