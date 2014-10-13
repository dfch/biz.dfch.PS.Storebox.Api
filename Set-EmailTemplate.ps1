function Set-EmailTemplate {
[CmdletBinding(
	HelpURI='http://dfch.biz/PS/Storebox/Api/Set-EmailTemplate/'
)]
Param (
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'reset')]
	[string] $Name
	,
	[Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'name')]
	$Template
	,
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'reset')]
	[alias("r")]
	[alias("Revert")]
	[switch] $Reset
)
BEGIN {
$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. ParameterSetName '{0}'" -f $PsCmdlet.ParameterSetName) -fac 1;
} # BEGIN

PROCESS {
[boolean] $fReturn = $false;
$OutputParameter = $null;

try {
	# Parameter validation
	# N/A

	if($PsCmdlet.ParameterSetName -eq 'reset') {
		$Body = Format-ExtendedMethod -Name 'unCustomizeTemplate' -Parameters ('<val>{0}</val>' -f $Name);
		$Response = Invoke-Command -Method 'POST' -Api '/' -Body $Body;
		if($Response) {
			$e = New-CustomErrorRecord -m ("Resetting template '{0}' to default. FAILED." -f $Name) -cat InvalidData -o $Body;
			throw($gotoError);
		} # if
	} else {
		if($Template -is [hashtable]) {
			$Parameters = $Template | ConvertTo-Xml;
		} else {
			$Template = $Template | ConvertFrom-Obj;
			if(!$Temmplate) {
				$e = New-CustomErrorRecord -m ("Template contains no valid XML data. Conversion FAILED.") -cat InvalidData -o $Template;
				throw($gotoError);
			} # if
			$Parameters = $Template;
		} # if
		if(!$Template.Contains('name')) {
			$e = New-CustomErrorRecord -m ("Template contains no name.") -cat InvalidData -o $Template;
			throw($gotoError);
		} # if
		$Name = $Template.Name;
		$Body = Format-ExtendedMethod -Name 'customizeTemplate' -Parameters ($Template | ConvertTo-Xml);
		$Response = Invoke-Command -Method 'POST' -Api '/' -Body $Body;
		if($Response) {
			$e = New-CustomErrorRecord -m ("Setting template '{0}' FAILED." -f $Name) -cat InvalidData -o $Body;
			throw($gotoError);
		} # if
	} # if

	$Body = Format-ExtendedMethod -Name 'getTemplate' -Parameters ('<val>{0}</val>' -f $Name);
	$Response = Invoke-Command -Method 'POST' -Api '/' -Body $Body;
	if(!$Response) {
		$e = New-CustomErrorRecord ("Retrieving 'getTemplate' '{0}' FAILED." -f $Name) -cat ObjectNotFound -o $Body;
		throw($gotoError);
	} # if
	$Template = $Response | ConvertFrom-Obj;
	$OutputParameter = $Template.Clone();

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
} # function
Export-ModuleMember -Function Set-EmailTemplate;

