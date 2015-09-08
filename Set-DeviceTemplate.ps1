#Requires -Modules 'biz.dfch.PS.Storebox.Api';

PARAM
(
	# Specifies the Storebox portal to login
	[ValidateNotNullOrEmpty()]
	$PortalUri
	,
	# Specifies the username for login
	[ValidateNotNullOrEmpty()]
	$Username
	,
	# Specifies the password for login
	[ValidateNotNullOrEmpty()]
	$Password
	,
	# Specifies the name of the device to process
	[ValidateNotNullOrEmpty()]
	$deviceName
	,
	# Specifies the name of the device template to use
	$deviceTemplateName
)

# Parameter validation
if([String]::IsNullOrWhiteSpace($PortalUri))
{
	throw ("PortalUri: Parameter validation FAILED. Value must not be null or empty.");
}

if([String]::IsNullOrWhiteSpace($Username))
{
	throw ("Username: Parameter validation FAILED. Value must not be null or empty.");
}

if([String]::IsNullOrWhiteSpace($Password))
{
	throw ("Password: Parameter validation FAILED. Value must not be null or empty.");
}
# Getting credential from some configuration file
$EncryptedPassword = $Password | ConvertTo-SecureString -asPlainText -Force;
$cred = New-Object System.Management.Automation.PSCredential($Username, $EncryptedPassword);

# login to portal
$svc = Enter-Ctera $PortalUri -Credential $cred -Global;
if($null -eq $svc)
{
	throw ("Login to '{0}' with '{1}' FAILED." -f $PortalUri, $Username);
}

# Getting device templates ...
$deviceTemplates = Invoke-CteraRestCall deviceTemplates | ConvertFrom-CteraObjList
# ... and specific device template
$deviceTemplate = $deviceTemplates | ? name -eq $deviceTemplateName;
if($null -eq $deviceTemplate)
{
	throw ("deviceTemplate '{0}' does not exist on '{1}'." -f $deviceTemplateName, $PortalUri);
}

# Getting 'our' device ...
$deviceRaw = Invoke-CteraRestCall ("devices/{0}" -f $deviceName);
if($null -eq $deviceRaw)
{
	throw ("device '{0}' does not exist on portal '{1}'." -f $deviceName, $PortalUri);
}
$device = $deviceRaw | ConvertFrom-CteraObj;
if($null -eq $device)
{
	throw ("device '{0}' does not exist on portal '{1}'." -f $deviceName, $PortalUri);
}

# Check if template already matches target template name
if($device.template -eq $deviceTemplate.baseObjectRef)
{
	Write-Warning ("device '{0}' is already set to deviceTemplate '{1}'. Skipping ..." -f $deviceName, $deviceTemplateName);
	Exit;
}

# assigning deviceTemplate to device ...
$device.template = $deviceTemplate.baseObjectRef
# ... and saving back to portal.
$result = Update-CteraObj $device -Validate -Confirm:$false;

# Verifying save operation and reloading device
$deviceUpdated = Invoke-CteraRestCall ("devices/{0}" -f $deviceName) | ConvertFrom-CteraObj
if($null -eq $deviceUpdated)
{
	throw ("deviceUpdated '{0}' does not exist on portal '{1}'. Save operation seems to have FAILED." -f $deviceName, $PortalUri);
}

if($device.template -ne $deviceUpdated.template)
{
	throw ("Save operation for device '{0}' on portal '{1}' FAILED. Template for this device is still set to '{2}'." -f $deviceName, $PortalUri, $deviceUpdated.template);
}
