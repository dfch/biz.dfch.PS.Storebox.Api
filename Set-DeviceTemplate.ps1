#Requires -Modules 'biz.dfch.PS.Storebox.Api';

PARAM
(
	$PortalUri = "https://eni.ds98.swisscom.com"
	,
	$Username = "test-api"
	,
	$Password
	,
	$deviceTemplateName = "storebox_agent"
	# ,
	# $deviceName = "W2012-7"
	,
	$deviceName = $ENV:COMPUTERNAME.ToLower()
)

# Getting credential from some configuration file
$cred = Get-Credential $Username;

# login to portal
$svc = Enter-Ctera $PortalUri -Credential $cred -Global;
if($null == $svc)
{
	throw ("Login to '{0}' with '{1}' FAILED." -f $PortalUri, $Username);
}

# Getting device templates ...
$deviceTemplates = Invoke-CteraRestCall deviceTemplates | ConvertFrom-CteraObjList
# ... and specific device template
$deviceTemplate = $deviceTemplates | ? name -eq $deviceTemplateName;
if($null == $deviceTemplate)
{
	throw ("deviceTemplate '{0}' does not exist on '{1}'." -f $deviceTemplateName, $PortalUri);
}

# Getting 'our' template ...
$device = Invoke-CteraRestCall ("devices/{0}" -f $deviceName) | ConvertFrom-CteraObj
if($null == $device)
{
	throw ("device '{0}' does not exist on portal '{1}'." -f $deviceName, $PortalUri);
}

# assigning deviceTemplate to device ...
$device.template = $deviceTemplate.baseObjectRef
# ... and saving back to portal.
$result = Update-CteraObj $device -Validate -Confirm:$false;

# Verifying save operation and reloading device
$deviceUpdated = Invoke-CteraRestCall ("devices/{0}" -f $deviceName) | ConvertFrom-CteraObj
if($null == $deviceUpdated)
{
	throw ("deviceUpdated '{0}' does not exist on portal '{1}'. Save operation seems to have FAILED." -f $deviceName, $PortalUri);
}

if($device.template -ne $deviceUpdated.template)
{
	throw ("Save operation for device '{0}' on portal '{1}' FAILED. Template for this device is still set to '{2}'." -f $deviceName, $PortalUri, $deviceUpdated.template);
}
