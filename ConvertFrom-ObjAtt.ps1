function ConvertFrom-ObjAtt {
[CmdletBinding(
	HelpURI='http://dfch.biz/biz/dfch/PSStorebox/Utilities/ConvertFrom-ObjAtt'
)]
[OutputType([string])]
Param (
    [Parameter(ValueFromPipeline = $true, Mandatory = $true, Position = 0)]
    [alias("o")]
    $InputObject
    ,
    [Parameter(Mandatory = $true, Position = 1)]
    [alias("id")]
    [string] $idAttribute
    ,
    [ValidateSet('Value', 'List')]
    [Parameter(Mandatory = $false, Position = 2)]
    [alias("t")]
    [string] $Type = 'Value'
)
BEGIN {
	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
} # BEGIN
PROCESS {
	if([string]::IsNullOrEmpty($idAttribute) -or [string]::IsNullOrWhiteSpace($idAttribute)) {
        $e = New-CustomErrorRecord -m "Invalid argument 'idAttribute' specified. Object is empty." -cat InvalidArgument -o $idAttribute;
		Log-Debug $fn $e.Exception.Message;
		$OutputParameter = $null;
        $PSCmdlet.ThrowTerminatingError($e);
	} # if
	if($InputObject -is [string]) {
		[xml] $xml = $InputObject;
	} elseif($InputObject -is [System.Xml.XmlElement]) {
		$xml = $InputObject;
	} else {
        $e = New-CustomErrorRecord -m ("Invalid argument 'InputObject' specified. Object has invalid type: '{0}'." -f $InputObject.GetType()) -cat InvalidType -o $InputObject;
		Log-Debug $fn $e.Exception.Message;
		$OutputParameter = $null;
        $PSCmdlet.ThrowTerminatingError($e);
	} # if
	$fReturn = $false;
	$OutputParameter = $null;
	foreach($a in $xml.att) { 
		if($a.id -eq $idAttribute) { 
			if($Type -eq 'List') {
				$OutputParameter = $a.list.OuterXml;
			} else {
				$OutputParameter = '{0}' -f $a.val;
			} # if
			$fReturn = $true;
			break;
		} # if
	} # foreach
	if(!$fReturn) { $OutputParameter = $null; }
	return $OutputParameter;
} # PROCESS
END {
} # END

} # ConvertFrom-ObjAtt
Export-ModuleMember -Function ConvertFrom-ObjAtt;

