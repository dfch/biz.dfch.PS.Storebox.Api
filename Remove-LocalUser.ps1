function Remove-LocalUser {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="High",
	HelpURI='http://dfch.biz/biz/dfch/PS/Storebox/Api/Remove-LocalUser/'
)]
[OutputType([Boolean])]
PARAM (
	[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Mandatory = $true, Position = 0, ParameterSetName = 'name')]
	[alias('n')]
	[alias('cn')]
	[alias('Identity')]
	[alias('name')]
	$UserName
	,
	[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Mandatory = $true, Position = 0, ParameterSetName = 'id')]
	[alias('uid')]
	[int] $id
)
BEGIN {
	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
	Log-Debug -fn $fn -msg ("CALL. ParameterSetName: '{0}'" -f $PSCmdlet.ParameterSetName) -fac 1;
	
	$fReturn = $false;
	$ParameterSetName = $PSCmdlet.ParameterSetName;
} # BEGIN

PROCESS {
try {
	# Parameter validation
	# N/A

    if($ParameterSetName -eq '__AllParameterSets') {
        if($UserName -is [System.Collections.Hashtable]) {
		    $e = New-CustomErrorRecord -m ("Input parameter from pipeline has wrong data type '{0}'." -f $UserName.GetType().FullName) -cat InvalidArgument -o $UserName;
		    throw($gotoError);
        } # if
        $id = $UserName.uid;
        $UserName = $UserName.name;
    } elseif($ParameterSetName -eq 'name') {
        if($UserName -is [System.Collections.Hashtable]) {
            $UserName = $UserName.name;
        } # if
        $sUser = Invoke-Command -Api ("users/{0}" -f $UserName);
        if(!$sUser) {
		    $e = New-CustomErrorRecord -m ("Cannot delete localUser '{0}' as user retrieving uid of user FAILED." -f $UserName) -cat ObjectNotFound -o $UserName;
		    throw($gotoError);
        } # if
        $oUser = ConvertFrom-Obj -XmlString $sUser;
        $id = $oUser.uid;
    } else {
        $UserName = '';
    } # if
    $Body = Format-ExtendedMethod  -name delete -Parameters '<val>true</val>'
    if($PSCmdlet.ShouldProcess(("{0} [{1}]" -f $UserName, $id))) {
        $r = Invoke-Command -Method "POST" -Api ('objs/{0}' -f $id) -Body $Body;
        if($r) {
		    $e = New-CustomErrorRecord -m ("Deleting localUser '{0}' [{1}] FAILED." -f $UserName, $id) -cat NotSpecified -o $oUser;
		    throw($gotoError);
        } # if
        $tmpLocalUser = ConvertFrom-Obj -XmlString ("<obj class='#uri'><att id='#uri'>{0}</att></obj>" -f $r);
        Log-Notice $fn ("Deleted localUser '{0}' [{1}]." -f $UserName, $id) -Verbose:$Verbose;
	    $OutputParameter = $true
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
Export-ModuleMember -Function Remove-LocalUser;

