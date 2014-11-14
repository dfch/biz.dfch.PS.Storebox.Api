function ConvertFrom-Obj {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Low",
	HelpURI='http://dfch.biz/biz/dfch/PS/Storebox/Api/ConvertFrom-Obj/'
)]
[OutputType([hashtable[]])]
PARAM (
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'xml')]
	[alias('obj')]
	[alias('e')]
	[alias('Element')]
	[System.Xml.XmlElement] $XmlElement
	,
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'doc')]
	[alias('d')]
	[alias('Document')]
	[System.Xml.XmlDocument] $XmlDocument
	,
	#ValueFromPipelineByPropertyName = $true, 
	[Parameter(ValueFromPipeline = $true, Mandatory = $true, Position = 0, ParameterSetName = 'string')]
	[alias('string')]
	[alias('s')]
	[string] $XmlString
)
BEGIN {
	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
	#Log-Debug -fn $fn -msg ("CALL. ParameterSetName: '{0}'" -f $PSCmdlet.ParameterSetName) -fac 1;
	
	$fReturn = $false;
	$OutputParameter = @();
	$ParameterSetName = $PSCmdlet.ParameterSetName;
} # BEGIN

PROCESS {
try {
	# Parameter validation
	# N/A

	if($ParameterSetName -eq 'string') {
		[xml] $XmlDocument = $XmlString;
		$ParameterSetName = 'doc';
	} # if
	if($ParameterSetName -eq 'doc') {
		$XmlElement = $XmlDocument.SelectSingleNode('/obj');
		$fReturn = $XmlElement -is [System.Xml.XmlElement];
		if(!$fReturn) {
			$e = New-CustomErrorRecord -m ("InputObject contains no ChildNode 'obj': '{0}'" -f $XmlDocument.OuterXml) -cat InvalidData -o $XmlDocument;
			throw($gotoError);
		} # if
		$ParameterSetName = 'xml';
	} # if

	$aatt = $XmlElement.SelectNodes('att');
	$htAtts = @{};
	if($XmlElement.HasAttribute('class')) {
		$htAtts.Add('#class', $XmlElement.class);
	} # if
	if(!$aatt -or ($aatt.Count -le 0)) {
		$e = New-CustomErrorRecord -m ("InputObject contains no ChildNodes 'att': '{0}'" -f $XmlElement.OuterXml) -cat InvalidData -o $XmlElement;
		throw($gotoError);
	} # if
	foreach($att in $aatt) { 
		$id = $att.id;
		if(!$id) {
			Log-Warn $fn ("Unsupported 'att' node: '{0}'. Empty id." -f $att.OuterXml);
			continue;
		} # if
		$nVal = $att.selectSingleNode('val');
		$nList = $att.selectSingleNode('list');
		$nObj = $att.selectSingleNode('obj');
		$Value = '';
		if(!$att.HasChildNodes) {
			if($htAtts.Contains($id)) {
				Log-Warn $fn ("htAtts already contains an attribute with name '{0}'." -f $id);
			} else {
				if([System.Object]::Equals($n.'#text', $null)) {
					$Value = $null; 
				} else {
					$Value = $att.'#text'; 
				} # if
				$htAtts.Add($id, $Value);
			} # if
		} elseif($nVal) { 
			$Value = $nVal.'#text'; 
			$htAtts.Add($id, $Value);
		} elseif($nObj) {
			$htObjChild = ConvertFrom-Obj -XmlElement $nObj;
			$htAtts.Add($id, $htObjChild);
		} elseif($nList) {
			$aListItem = @();
            $anListObj = $nList.SelectNodes('obj');
			foreach($nListObj in $anListObj) {
				$htObjChild = ConvertFrom-Obj -XmlElement $nListObj;
                $aListItem += $htObjChild;
			} # foreach
            $anListVal = $nList.SelectNodes('val');
			foreach($nListVal in $anListVal) {
				$aListItem += $nListVal.'#text';
			} # foreach
			$htAtts.Add($id, $aListItem.Clone());
		} else {
			Log-Warn $fn ("Unsupported 'att' node: '{0}'." -f $att.id);
			continue;
		} # if
	} # foreach
	$htAtts.Add('#xml', $XmlElement.OuterXml);
	$OutputParameter += $htAtts.Clone();

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
	#Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;
} # END
} # function
Export-ModuleMember -Function ConvertFrom-Obj;

