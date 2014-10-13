function New-ProjectAclRule {
[CmdletBinding(
	HelpURI='http://dfch.biz/PS/Storebox/Utilities/New-ProjectAclRule'
)]
[OutputType([string])]
Param (
    [Parameter(Mandatory = $true, Position = 0)]
    [alias("acl")]
    [hashtable[]] $AclEntries
)
BEGIN {
	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
} # BEGIN
PROCESS {
    if($AclEntries -isnot [Array]) {
        $e = New-CustomErrorRecord -m "Invalid argument 'AclEntries' specified. Object has invalid type." -cat InvalidArgument -o $AclEntries;
		Log-Debug $fn $e.Exception.Message;
		$OutputParameter = $null;
        $PSCmdlet.ThrowTerminatingError($e);
	} # if

    [xml] $l = "<list id='bogusAttribute' />";
	foreach($AclEntry in $AclEntries) {
        if($AclEntry.Count -gt 1) {
            $e = New-CustomErrorRecord -m "Invalid entry 'AclEntry' found. Object has 'Count' of more than '1'." -cat InvalidType -o $AclEntry;
		    Log-Debug $fn $e.Exception.Message;
		    $OutputParameter = $null;
            $PSCmdlet.ThrowTerminatingError($e);
        } #
        # Extract user/group, name
        $AclEntry.GetEnumerator() | % { 

            $x = $l.CreateElement('obj');
            $x.SetAttribute('class', 'ProjectACLRule');

            $UserObject = $_.Name; 
            # Split '\'
            $fReturn = $UserObject -match '^([^\\]+)\\([^$]+)$';
            if(!$fReturn) {
                $e = New-CustomErrorRecord (-m "Invalid data in 'AclEntry' found. Property 'Name' [Group/User] contains no '\': '{0}'." -f $UserObject) -cat InvalidData -o $UserObject;
		        Log-Debug $fn $e.Exception.Message;
		        $OutputParameter = $null;
                $PSCmdlet.ThrowTerminatingError($e);
            } # if
            $Scope = $Matches[1];
            $User = $Matches[2];
            # Check permission
            $Permission = $_.Value;
            if([string]::IsNullOrEmpty($Permission) -or [string]::IsNullOrWhiteSpace($Permission)) {
                $e = New-CustomErrorRecord -m "Invalid data in 'AclEntry' found. Property 'Value' [Permission] contains no data." -cat InvalidData -o $Permission;
		        Log-Debug $fn $e.Exception.Message;
		        $OutputParameter = $null;
                $PSCmdlet.ThrowTerminatingError($e);
            } # if

            # Get uid for user or group
            if($Scope -eq 'localUser') {
                [xml] $r = Invoke-Command ('users/{0}' -f $User);
            } elseif($Scope -eq 'localGroup') {
                [xml] $r = Invoke-Command ('localGroups/{0}' -f $User);
            } else {
                $e = New-CustomErrorRecord -m ("Invalid data in 'AclEntry' found. Property 'Name' [Scope] contains invalid data: '{0}'." -f $Scope) -cat InvalidData -o $Scope;
		        Log-Debug $fn $e.Exception.Message;
		        $OutputParameter = $null;
                $PSCmdlet.ThrowTerminatingError($e);
            } # if
			if(!$r) {
                $e = New-CustomErrorRecord -m ("Invalid data in 'AclEntry' found. Property 'Name' [Scope: '{0}'] contains invalid data: '{1}'." -f $Scope, $User) -cat InvalidData -o $User;
		        Log-Debug $fn $e.Exception.Message;
		        $OutputParameter = $null;
                $PSCmdlet.ThrowTerminatingError($e);
			} # if
            # Create 
            $uid = ConvertFrom-ObjAtt $r.obj uid;
            $new = $l.CreateElement('att');
            $new.SetAttribute('id', 'name');
            $new.set_InnerXML('<val>{0}</val>' -f $User);
            $null = $x.AppendChild($new);
            $new = $l.CreateElement('att');
            $new.SetAttribute('id', 'uid');
            $new.set_InnerXML('<val>{0}</val>' -f $uid);
            $null = $x.AppendChild($new);
            $new = $l.CreateElement('att');
            $new.SetAttribute('id', 'type');
            $new.set_InnerXML('<val>{0}</val>' -f $Scope);
            $null = $x.AppendChild($new);
            $new = $l.CreateElement('att');
            $new.SetAttribute('id', 'permissions');
            $new.set_InnerXML('<val>{0}</val>' -f $Permission);
            $null = $x.AppendChild($new);
        } # GetEnum
        $null = $l.list.AppendChild($x);
    } # foreach
    $null = $l.list.RemoveAttribute('id');
    $OutputParameter = $l.OuterXml;

	return $OutputParameter;
} # PROCESS
END {
    # N/A
} # END

} # New-ProjectAclRule
Export-ModuleMember -Function New-ProjectAclRule;

