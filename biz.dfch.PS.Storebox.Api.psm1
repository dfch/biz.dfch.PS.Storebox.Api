Set-Variable MODULE_NAME -Option 'Constant' -Value 'biz.dfch.PS.Storebox.Api';
$fn = $MODULE_NAME;

Set-Variable gotoSuccess -Option 'Constant' -Value 'biz.dfch.System.Exception.gotoSuccess';
Set-Variable gotoError -Option 'Constant' -Value 'biz.dfch.System.Exception.gotoError';
Set-Variable gotoFailure -Option 'Constant' -Value 'biz.dfch.System.Exception.gotoFailure';
Set-Variable gotoNotFound -Option 'Constant' -Value 'biz.dfch.System.Exception.gotoNotFound';

# Load module configuration file
# As (Get-Module $MODULE_NAME).ModuleBase does not return the module path during 
# module load we resort to searching the whole PSModulePath. Configuration file 
# is loaded on a first match basis.
$mvar = $MODULE_NAME.Replace('.', '_');
foreach($var in $ENV:PSModulePath.Split(';')){ 
	[string] $ModuleDirectoryBase = Join-Path -Path $var -ChildPath $MODULE_NAME;
	[string] $ModuleConfigFile = '{0}.xml' -f $MODULE_NAME;
	[string] $ModuleConfigurationPathAndFile = Join-Path -Path $ModuleDirectoryBase -ChildPath $ModuleConfigFile;
	if($true -eq (Test-Path -Path $ModuleConfigurationPathAndFile)) {
		if($true -ne (Test-Path variable:$($mvar))) {
			Log-Debug $fn ("Loading module configuration file from: '{0}' ..." -f $ModuleConfigurationPathAndFile);
			Set-Variable -Name $mvar -Value (Import-Clixml -Path $ModuleConfigurationPathAndFile) -Description "The array contains the public configuration properties of the module '$MODULE_NAME'." ;
			break;
		} # if()
	} # if()
} # for()
if($true -ne (Test-Path variable:$($mvar))) {
	Write-Error "Could not find module configuration file '$ModuleConfigFile' in 'ENV:PSModulePath'.`nAborting module import...";
	break; # Aborts loading module.
} # if()
Export-ModuleMember -Variable $mvar;

<#
 # ########################################
 # Version history
 # ########################################
 #
 # 2014-10-13; rrink; CHG: move Cmdlets to separate ps1 files (and rename cmdlets to support DefaultPrefix)
 # 2014-10-10; ckreissl; ADD: Invoke-FileTransfer, add help example 
 # 2013-12-15; rrink; CHG: Invoke-RestCall, moved $wc.Dispose() to finally
 # 2013-12-15; rrink; CHG: Invoke-FileTransfer, moved $wc.Dispose() to finally
 # 2013-11-27; rrink; CHG: Invoke-FileTransfer, Parameter validation for PortalName
 # 2013-11-27; rrink; CHG: Enter-Ctera, for non global logins the PortalName property on $biz_dfch_PS_Storebox_Api will be set after login
 # 2013-11-18; rrink; CHG: Global, HelpUri 'vCD/Utilities' to 'Storebox/Api'
 # 2013-08-14; rrink; ADD: Set-EmailTemplate, new Cmdlet to set / update email templates
 # 2013-08-14; rrink; ADD: Get-EmailTemplate, new Cmdlet to get email templates
 # 2013-08-14; rrink; ADD: Format-ExtendedMethod, Add 'getTemplates', 'getTemplate', 'unCustomizeTemplate' and 'customizeTemplate' value for Name parameter (for email templates)
 # 2013-08-14; rrink; ADD: New-LocalUser, Add "Global" parameter to support creation of global administrators and portal staff users
 # 2013-08-14; rrink; ADD: Get-DefaultsObj, Add "PortalAdmin" value for class parameter
 # 2013-08-14; rrink; CHG: Select-Storebox, Replace "AdminPortal" parameter with "Global"
 # 2013-08-14; rrink; CHG: Enter-Storebox, Replace "GlobalLogin" parameter with "Global"
 # 2013-08-14; rrink; ADD: Remove-AddOn; new Cmdlet to delete addOns
 # 2013-08-14; rrink; ADD: New-CteraAddOn, new Cmdlet to create addOns
 # 2013-08-14; rrink; ADD: Remove-Plan; new Cmdlet to delete plans
 # 2013-08-14; rrink; ADD: New-Plan, new Cmdlet to create plans
 # 2013-08-13; rrink; CHG: ConvertTo-Xml, FIX handling of integers (now same as string); corrected error message for unexpected object type
 # 2013-08-01; rrink; CHG: Enter-Storebox, Uri can now end with an trailing "/" and is converted to [Uri] datatype before first use
 # 2013-08-01; rrink; CHG: Enter-Storebox, Replace "UriPortal" parameter with "Uri"
 # 2013-07-24; rrink; ADD: Invoke-CteraRestCommand, ErrorLogging on WebException. The actual response is now displayed as Log-Critical
 # 2013-07-24; rrink; CHG: Enter-Ctera, Corrected examples help
 # 2013-07-24; rrink; CHG: Enter-Ctera, Corrected UrlEncoding on user/pass parameters in HTML payload on login
 #
 # ########################################
 #>

