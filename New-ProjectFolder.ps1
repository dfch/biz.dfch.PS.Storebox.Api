<#

.SYNOPSIS

Creates a storebox portal.



.DESCRIPTION

Creates a storebox portal.

$acl = @(); 
$acl += New-AclEntry -Name EdgarSchnittenfittich -Type localUser -Permission ReadWrite;
$acl += New-AclEntry -Name some-user -Type localUser -Permission ReadOnly;
$acl += New-AclEntry -Name ProjectsReadWrite -Type localGroup -Permission ReadWrite;
$acl += New-AclEntry -Name ProjectsReadOnly -Type localGroup -Permission ReadOnly;
New-ProjectFolder -Name EdgarSchnittenfittichProject -Owner EdgarSchnittenfittich -Description "this is a description" -Permissions $acl



.EXAMPLE

Creates a storebox portal.

$acl = @(); 
$acl += New-AclEntry -Name EdgarSchnittenfittich -Type localUser -Permission ReadWrite;
$acl += New-AclEntry -Name some-user -Type localUser -Permission ReadOnly;
$acl += New-AclEntry -Name ProjectsReadWrite -Type localGroup -Permission ReadWrite;
$acl += New-AclEntry -Name ProjectsReadOnly -Type localGroup -Permission ReadOnly;
New-ProjectFolder -Name EdgarSchnittenfittichProject -Owner EdgarSchnittenfittich -Description "this is a description" -Permissions $acl

#>
function New-ProjectFolder {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium",
	HelpURI='http://dfch.biz/biz/dfch/PS/Storebox/Api/New-ProjectFolder/'
)]
[OutputType([string])]
Param (
	[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Mandatory = $true, Position = 0, ParameterSetName = 'r')]
	$InputObject
    ,
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'p')]
	[string] $Name
    ,
	[Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'p')]
	[string] $Owner
    ,
	[Parameter(Mandatory = $false, Position = 2, ParameterSetName = 'p')]
	[string] $Description = ''
    ,
	[Parameter(Mandatory = $false, Position = 3, ParameterSetName = 'p')]
	[string] $Group = ''
    ,
	[Parameter(Mandatory = $false, ParameterSetName = 'p')]
	[switch] $ShowUnderRoot = $false
    ,
	[Parameter(Mandatory = $false, Position = 4, ParameterSetName = 'p')]
    [Alias('acl')]
	[hashtable[]] $Permissions = $null
    ,
	[Parameter(Mandatory = $false)]
	[switch] $Validate = $false
)
BEGIN {
$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL.") -fac 1;

$oProjectTemplate = Get-ObjTemplate ProjectCreateParams|ConvertFrom-Obj;
$r = Invoke-Command defaultGroup;
$dbSlim = ("<obj class='user-defined' ><att id='defaultGroup' >{0}</att></obj>" -f $r) | ConvertFrom-Obj;
$oAclRuleTemplate = Get-DefaultsObj ProjectACLRule | ConvertFrom-Obj;

} # BEGIN

PROCESS {
[boolean] $fReturn = $false;
$OutputParameter = $null;

try {
	# Parameter validation
	# N/A
    $obj = $null;

    $oProjectFolder = $oProjectTemplate.Clone();
    $r = @{};
    if($PSCmdlet.ParameterSetName -eq 'p') {
        $oProjectFolder.name = $Name;
        $oProjectFolder.description = $Description;
		if($ShowUnderRoot) { $oProjectFolder.ShowUnderRoot = 'true'; } else { $oProjectFolder.ShowUnderRoot = 'false'; }
        $r.Owner = $Owner;
        $r.Group = $Group;
        $r.Permissions = $Permissions;
    } else {
        $oProjectFolder.Name = $InputObject.Name;
        $oProjectFolder.Description = $InputObject.Description;
		if($InputObject.ShowUnderRoot) { $oProjectFolder.ShowUnderRoot = 'true'; } else { $oProjectFolder.ShowUnderRoot = 'false'; }
        $r.Owner = $InputObject.Owner;
        $r.Group = $InputObject.Group;
        $r.Permissions = $InputObject.Permissions;
    } # if
    if(!$r.Group) {
        $oProjectFolder.group = $dbSlim.defaultGroup;
    } else {
        $oProjectFolder.group = $r.Group;
    } # if
    $oUser = Invoke-Command ('users/{0}' -f $r.Owner) | ConvertFrom-Obj;
    $oProjectFolder.owner = 'objs/{0}' -f $oUser.uid;
    if(!$r.Permissions) {
        $oProjectFolder.Acl = @();
    } else {
        $aoAclRule = @();
        foreach($a in $r.Permissions) { 
            foreach($acl in $a.GetEnumerator()) { 
                $fReturn = $acl.Name -match '^(?<type>local.+)\\(?<name>.+)$'; 
                if(!$fReturn) {
                    $e = New-CustomErrorRecord -m ("Permissions contains invalid data on 'name' property: '{0}'" -f $acl.Name)-cat InvalidArgument -o $r.Permissions;
                    throw($gotoError);
                } # if
                switch($Matches.type) {
                'localUser' {
                    $oUser = Invoke-Command ('users/{0}' -f $Matches.name) | ConvertFrom-Obj;
                    $uid = $oUser.uid;
                }
                'localGroup' {
                    $oGroup = Invoke-Command ('localGroups/{0}' -f $Matches.name) | ConvertFrom-Obj;
                    $uid = $oGroup.uid;
                }
                default {
                    $e = New-CustomErrorRecord -m ("Permissions contains invalid data on 'name' property: '{0}'" -f $Matches.type)-cat InvalidArgument -o $r.Permissions;
                    throw($gotoError);
                }
                } # switch
                $oAclRule = $oAclRuleTemplate.Clone();
                $oAclRule.permissions = $acl.Value;
                $oAclRule.name = $Matches.name;
                $oAclRule.type = $Matches.type;
                $oAclRule.uid = $uid;
                $aoAclRule += $oAclRule.Clone();
            } # foreach
        } # foreach
        $oProjectFolder.Acl = $aoAclRule;
    } # if

    if($Validate) {
        $oProjectFolderValidate = $oProjectFolder.Clone();
        $oProjectFolderValidate.'#class' = 'PortalProject';
        $Parameters = $oProjectFolderValidate | ConvertTo-Xml;
        $Uri = 'projects';
        $Body = Format-ExtendedMethod -Name 'validate' -Parameters $Parameters;
        $r = Invoke-Command -Method 'POST' -Api $Uri -Body $Body;
        if(![System.Object]::Equals($r, $null)) {
            $e = New-CustomErrorRecord -m ("Validation of adding projectFolder '{0}' FAILED." -f $oProjectFolder.Name) -cat InvalidData -o $Body;
            throw($gotoError);
        } # 
    } # if
    $Parameters = $oProjectFolder | ConvertTo-Xml;
    $Body = Format-ExtendedMethod -Name 'addProject' -Parameters $Parameters;
	if(!$PSCmdlet.ShouldProcess($Name)) {
        $fReturn = $true;
        $OutputParameter = $null;
        throw($gotoSuccess);
    } # if
    $Uri = '/'
    $r = Invoke-Command -Method 'POST' -Api $Uri -Body $Body;
    if([System.Object]::Equals($r, $null)) {
        $e = New-CustomErrorRecord -m ("Adding projectFolder '{0}' FAILED." -f $oProjectFolder.Name) -cat InvalidData -o $Body;
        throw($gotoError);
    } # 
    $OutputParameter = ("<obj class='#uri'><att id='#uri'>{0}</att></obj>" -f $r) | ConvertFrom-Obj;
    $fReturn = $true;
			
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
Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;
} # END

} # New-ProjectFolder
Set-Alias -Name New-Project -Value New-ProjectFolder;
Set-Alias -Name New-Folder -Value New-ProjectFolder;
Export-ModuleMember -Function New-ProjectFolder -Alias New-Project, New-Folder;

