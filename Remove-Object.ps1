function Remove-Object {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="High",
	HelpURI='http://dfch.biz/biz/dfch/PSStorebox/Api/Remove-Object/'
)]
[OutputType([Boolean])]
Param (
	[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Mandatory = $true, Position = 0, ParameterSetName = 'o')]
	$InputObject
    ,
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'id')]
	[int] $id
    ,
	[Parameter(Mandatory = $false)]
	[switch] $Validate = $false
)
BEGIN {
$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. ParameterSetName '{0}'" -f $PSCmdlet.ParameterSetName) -fac 1;

$Body = Format-ExtendedMethod -Name delete -Parameters '<val>true</val>'
} # BEGIN

PROCESS {
[boolean] $fReturn = $false;
$OutputParameter = $null;

try {
	# Parameter validation
	# N/A
    if($PSCmdlet.ParameterSetName -eq 'id') {
        $InputObject = $id;
    } # if

    foreach($oObj in $InputObject) {
        if(!$oObj) {
            $e = New-CustomErrorRecord -m ("InputObject contains null value.") -cat InvalidData -o $InputObject;
            throw($gotoError);
        } # if
        if($oObj -is [hashtable] -or $oObj -is [System.Collections.Specialized.OrderedDictionary]) {
            if(!$oObj.Contains('#class') -or !$oObj.Contains('name') -or !$oObj.Contains('uid')) {
                $e = New-CustomErrorRecord -m ("InputObject item is hashtable but does not class, name or uid.") -cat InvalidData -o $oObj;
                throw($gotoError);
            } # if
            if($Validate) {
                $oObjV = Invoke-Command ("objs/{0}" -f $oObj.uid) | ConvertFrom-Obj;
                if(!$oObjV -or !$oObjV.Contains('uid') -or $oObjV.uid -ne $oObj.uid) {
                    $e = New-CustomErrorRecord -m ("Object with id '{0}' not found." -f $oObj.uid) -cat ObjectNotFound -o $oObj.uid;
                    throw($gotoError);
                } # if
                $oObj = $oObjV.Clone();
            } # if
            Log-Info $fn ("Deleting '{0}' '{1}' [{2}] ..." -f $oObj.'#class', $oObj.name, $oObj.uid) -v;
	        if(!$PSCmdlet.ShouldProcess($oObj.uid)) {
                throw($gotoSuccess);
            } # if
            $r = Invoke-Command -Method POST -Api ("objs/{0}" -f $oObj.uid) -Body $Body;
            if(![System.Object]::Equals($r, $null)) {
                Log-Error $fn ("Deleting object id [{0}] FAILED." -f $oObj.uid) -v;
            } else {
                Log-Debug $fn ("Deleting object id [{0}] SUCCEEDED." -f $oObj.uid);
            } # if
        } elseif([int]::Parse($oObj)) {
            $id = [int]::Parse($oObj);
            if($Validate) {
                $oObjV = Invoke-Command ("objs/{0}" -f $id) | ConvertFrom-Obj;
                if(!$oObjV -or !$oObjV.Contains('uid') -or $oObjV.uid -ne $id) {
                    $e = New-CustomErrorRecord -m ("Object with id '{0}' not found." -f $id) -cat ObjectNotFound -o $id;
                    throw($gotoError);
                } # if
                $oObj = $oObjV.Clone();
            } else {
                $oObj = @{};
                $oObj.uid = $id -as [string];
                $oObj.'#class' = '#unknown';
                $oObj.name = '#unknown';
            } # if
            Log-Info $fn ("Deleting '{0}' '{1}' [{2}] ..." -f $oObj.'#class', $oObj.name, $oObj.uid) -v;
	        if(!$PSCmdlet.ShouldProcess($oObj.uid)) {
                throw($gotoSuccess);
            } # if
            $r = Invoke-Command -Method POST -Api ("objs/{0}" -f $oObj.uid) -Body $Body;
            if(![System.Object]::Equals($r, $null)) {
                Log-Error $fn ("Deleting object id [{0}] FAILED." -f $oObj.uid) -v;
            } else {
                Log-Debug $fn ("Deleting object id [{0}] SUCCEEDED." -f $oObj.uid);
            } # if
        } else {
            $e = New-CustomErrorRecord -m ("Object '{0}' is not a valid uid." -f $oObj) -cat InvalidData -o $oObj;
            throw($gotoError);
        } # if
    } # foreach
    $fReturn = $true;
    $OutputParameter = $fReturn;
    throw($gotoSuccess);

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
$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;
return $OutputParameter;
} # END

} # Remove-Object
Set-Alias -Name Remove-Obj -Value Remove-Object;
Export-ModuleMember -Function Remove-Object -Alias Remove-Obj;

