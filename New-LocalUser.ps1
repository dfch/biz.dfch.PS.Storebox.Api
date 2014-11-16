function New-LocalUser {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium",
	HelpURI='http://dfch.biz/biz/dfch/PS/Storebox/Api/New-LocalUser/'
)]
[OutputType([hashtable])]
PARAM (
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'param')]
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'global')]
	[alias('n')]
	[alias('cn')]
	[alias('Identity')]
	[alias('u')]
	[alias('user')]
	[string] $UserName
	,
	[Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'param')]
	[Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'global')]
	[alias('mail')]
	[alias('email')]
	[string] $EmailAddress
	,
	[Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'param')]
	[Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'global')]
	[alias('givenName')]
	[string] $FirstName
	,
	[Parameter(Mandatory = $true, Position = 3, ParameterSetName = 'param')]
	[Parameter(Mandatory = $true, Position = 3, ParameterSetName = 'global')]
	[alias('sn')]
	[string] $LastName
	,
	[Parameter(Mandatory = $false, Position = 6, ParameterSetName = 'param')]
	[Parameter(Mandatory = $false, Position = 6, ParameterSetName = 'global')]
	[alias('pw')]
	$Password = $(New-SecurePassword)
	,
	[Parameter(Mandatory = $false, Position = 5, ParameterSetName = 'param')]
	[alias('org')]
	[string] $Company = ''
	,
	[Parameter(Mandatory = $false, Position = 6, ParameterSetName = 'param')]
	[Parameter(Mandatory = $false, Position = 6, ParameterSetName = 'global')]
	[alias('Description')]
	[alias('c')]
	[string] $Comment = ''
	,
	[Parameter(Mandatory = $false, Position = 7, ParameterSetName = 'param')]
	[int] $UUID
	,
	[ValidateSet('active', 'inactive')]
	[Parameter(Mandatory = $false, Position = 8, ParameterSetName = 'param')]
	[alias('s')]
	[alias('accountStatus')]
	[string] $Status = 'active'
	,
	[ValidateSet('EndUser', 'ReadOnlyAdmin', 'ReadWriteAdmin', 'Support', 'Disabled')]
	[Parameter(Mandatory = $false, Position = 9, ParameterSetName = 'param')]
	[Parameter(Mandatory = $false, Position = 9, ParameterSetName = 'global')]
	[alias('r')]
	[string] $Role = 'EndUser'
	,
	[Parameter(Mandatory = $false, Position = 10, ParameterSetName = 'param')]
	[Parameter(Mandatory = $false, Position = 10, ParameterSetName = 'global')]
	[alias('requirePasswordChangeOn')]
	[datetime] $PasswordExpires = 0
	,
	[Parameter(Mandatory = $false, ParameterSetName = 'global')]
	[alias('GlobalAdmin')]
	[switch] $Global = $false
)
BEGIN {
	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
	Log-Debug -fn $fn -msg ("CALL. ParameterSetName: '{0}'" -f $PSCmdlet.ParameterSetName) -fac 1;
	
	$fReturn = $false;
	$OutputParameter = @();
	$ParameterSetName = $PSCmdlet.ParameterSetName;
} # BEGIN

PROCESS {
try {
	# Parameter validation
	# N/A

    if($Password -is [System.Security.SecureString]) {
        $credUser = New-Object PSCredential -ArgumentList $Name, $Password
        $Password = $credUser.GetNetworkCredential().Password;
    } # if
    if($UUID -eq 0) {
        $UUID = '';
    } # if

	if($Global) {
		$UserTemplate = Get-DefaultsObj -Name 'PortalAdmin' | ConvertFrom-Obj;
		
		$UserTemplate.name = [System.Web.HttpUtility]::HtmlEncode($UserName);
		$UserTemplate.email = [System.Web.HttpUtility]::HtmlEncode($EmailAddress);
		$UserTemplate.firstName = [System.Web.HttpUtility]::HtmlEncode($FirstName);
		$UserTemplate.lastName = [System.Web.HttpUtility]::HtmlEncode($LastName);
		$UserTemplate.password = [System.Web.HttpUtility]::HtmlEncode($Password);
		$UserTemplate.role = [System.Web.HttpUtility]::HtmlEncode($Role);
		$UserTemplate.comment = [System.Web.HttpUtility]::HtmlEncode($Comment);
		$UserTemplate.requirePasswordChangeOn = [System.Web.HttpUtility]::HtmlEncode($PasswordExpires.ToString('yyyy-MM-dd'));
		
		$Body = Format-ExtendedMethod -name add -p ($UserTemplate | ConvertTo-Xml);
	} else {
		$sUserDefaults = Get-DefaultsObj -Name 'PortalUser';
		$oUserDefaults = ConvertFrom-Obj -XmlString $sUserDefaults;
		[xml] $xUserDefaults = $sUserDefaults;

		# set Name
		$n = $xUserDefaults.obj.SelectSingleNode("att[@id = 'name']");
		$n.set_InnerXML( ('<val>{0}</val>' -f [System.Web.HttpUtility]::HtmlEncode($UserName)) );
		# set Email
		$n = $xUserDefaults.obj.SelectSingleNode("att[@id = 'email']");
		$n.set_InnerXML( ('<val>{0}</val>' -f [System.Web.HttpUtility]::HtmlEncode($EmailAddress)) );
		# set LastName
		$n = $xUserDefaults.obj.SelectSingleNode("att[@id = 'lastName']");
		$n.set_InnerXML( ('<val>{0}</val>' -f [System.Web.HttpUtility]::HtmlEncode($LastName)) );
		# set FirstName
		$n = $xUserDefaults.obj.SelectSingleNode("att[@id = 'firstName']");
		$n.set_InnerXML( ('<val>{0}</val>' -f [System.Web.HttpUtility]::HtmlEncode($FirstName)) );
		# set Password
		$n = $xUserDefaults.obj.SelectSingleNode("att[@id = 'password']");
		$n.set_InnerXML( ('<val>{0}</val>' -f [System.Web.HttpUtility]::HtmlEncode($Password)) );
		# set Status
		$n = $xUserDefaults.obj.SelectSingleNode("att[@id = 'accountStatus']");
		$n.set_InnerXML( ('<val>{0}</val>' -f [System.Web.HttpUtility]::HtmlEncode($Status)) );
		# set Role
		$n = $xUserDefaults.obj.SelectSingleNode("att[@id = 'role']");
		$n.set_InnerXML( ('<val>{0}</val>' -f [System.Web.HttpUtility]::HtmlEncode($Role)) );
		# set UUID
		if($UUID -ne 0) {
			$n = $xUserDefaults.obj.SelectSingleNode("att[@id = 'uuid']");
			$n.set_InnerXML( ('<val>{0}</val>' -f [System.Web.HttpUtility]::HtmlEncode($UUID)) );
		} # if
		# set PasswordExpiry
		if($PasswordExpires.Ticks -ne 0) {
			$n = $xUserDefaults.obj.SelectSingleNode("att[@id = 'requirePasswordChangeOn']");
			$n.set_InnerXML( ('<val>{0}</val>' -f [System.Web.HttpUtility]::HtmlEncode($PasswordExpires.ToString('yyyy-MM-dd'))) );
		} # if
		# set comment
		if($Comment) {
			$n = $xUserDefaults.obj.SelectSingleNode("att[@id = 'comment']");
			$n.set_InnerXML( ('<val>{0}</val>' -f [System.Web.HttpUtility]::HtmlEncode($Comment)) );
		} # if
		# set company
		if($Company) {
			$n = $xUserDefaults.obj.SelectSingleNode("att[@id = 'company']");
			$n.set_InnerXML( ('<val>{0}</val>' -f [System.Web.HttpUtility]::HtmlEncode($Company)) );
		} # if

		$oUserDefaults = $xUserDefaults.OuterXml | ConvertFrom-Obj;
		$Body = Format-ExtendedMethod -name add -p $xUserDefaults.OuterXml;
	} # if

    if($PSCmdlet.ShouldProcess($UserName)) {
		if($Global) {
			$r = Invoke-Command -Method "POST" -Api 'administrators' -Body $Body;
		} else {
			$r = Invoke-Command -Method "POST" -Api 'users' -Body $Body;
		} # if
        if(!$r) {
		    $e = New-CustomErrorRecord -m ("Creating localUser '{0}' FAILED." -f $UserName) -cat NotSpecified -o $Body;
		    throw($gotoError);
        } # if
        $tmpLocalUser = ConvertFrom-Obj -XmlString ("<obj class='#uri'><att id='#uri'>{0}</att></obj>" -f $r);
        Log-Info $fn ("Created localUser '{0}' [{1}]." -f $UserName, $tmpLocalUser.'#uri') -Verbose:$Verbose;
	    $OutputParameter = $tmpLocalUser.Clone();
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
Export-ModuleMember -Function New-LocalUser;

