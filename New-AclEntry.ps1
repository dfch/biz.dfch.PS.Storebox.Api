function New-AclEntry {
[CmdletBinding(
	HelpURI='http://dfch.biz/PS/Storebox/Utilities/New-AclEntry'
)]
[OutputType([hashtable])]
Param (
    [Parameter(Mandatory = $true, Position = 0)]
    [alias("n")]
    [string] $Name
    ,
    [ValidateSet('localUser', 'localGroup')]
    [Parameter(Mandatory = $false, Position = 1)]
    [alias("t")]
    [string] $Type = 'localUser'
    ,
    [ValidateSet('ReadWrite', 'ReadOnly')]
    [Parameter(Mandatory = $false, Position = 2)]
    [alias("p")]
    [string] $Permission = 'ReadOnly'
)
BEGIN {
	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
} # BEGIN
PROCESS {
	if([string]::IsNullOrEmpty($Name) -or [string]::IsNullOrWhiteSpace($Name)) {
        $e = New-CustomErrorRecord -m "Invalid argument 'Name' specified. Object is empty." -cat InvalidArgument -o $Name;
		Log-Debug $fn $e.Exception.Message;
		$OutputParameter = $null;
        $PSCmdlet.ThrowTerminatingError($e);
	} else {
		$OutputParameter = @{ ('{0}\{1}' -f $Type, $Name) = $Permission };
	} # if
	return $OutputParameter;
} # PROCESS
END {
} # END

} # New-AclEntry
Export-ModuleMember -Function New-AclEntry;

