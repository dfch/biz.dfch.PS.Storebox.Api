function Get-Portal {
<#

.SYNOPSIS

Gets Storebox Portals from currently selected Portal on a given UriPortal.



.DESCRIPTION

Gets Storebox Portals from currently selected Portal on a given UriPortal.

For more information about Cmdlets see 'about_Functions_CmdletBindingAttribute'.



.OUTPUTS

This Cmdlet returns an XML document parameter. On failure the string contains $null.

For more information about output parameters see 'help about_Functions_OutputTypeAttribute'.



.INPUTS

See PARAMETER section for a description of input parameters.

For more information about input parameters see 'help about_Functions_Advanced_Parameters'.



.PARAMETER UriPortal

URI of the StoreBox server.



.PARAMETER PortalName

The name of a Storebox Portal to select.



.EXAMPLE

Perform a login to a StoreBox server with username and plaintext password.

Get-Portal -UriPortal 'https://promo.ds01.swisscom.com' -Username 'PeterLustig' -Password 'S0nnensch3!n'



.EXAMPLE

Perform a login to a StoreBox server with username and encrypted password.

Get-Portal -UriPortal 'https://promo.ds01.swisscom.com' -Username 'PeterLustig' -Credentials [PSCredentials]



.LINK

Online Version: http://dfch.biz/biz/dfch/PS/Storebox/Api/Get-Portal/
Enter-Ctera



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

#>
	[CmdletBinding(
		HelpURI='http://dfch.biz/biz/dfch/PS/Storebox/Api/Get-Portal/'
    )]
	[OutputType([xml], ParameterSetName = 'list')]
	[OutputType([System.Collections.Hashtable], ParameterSetName = 'portal')]
    Param (
		[Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'portal')]
		[alias("p")]
		[alias("portal")]
		[string] $PortalName = $biz_dfch_PS_Storebox_Api.PortalName, 
		[Parameter(Mandatory = $false, Position = 1, ParameterSetName = 'list')]
		[alias("f")]
		[string] $Filter, 
		[Parameter(Mandatory = $false, Position = 3)]
		[alias("s")]
		[hashtable] $Session = $biz_dfch_PS_Storebox_Api.Session, 
		[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'list')]
		[alias("l")]
		[switch] $ListAvailable, 
		[Parameter(Mandatory = $false)]
		[alias("x")]
		[switch] $ReturnAsXml
		) # Param
    BEGIN {
		$datBegin = [datetime]::Now;
		[string] $fn = $MyInvocation.MyCommand.Name;
		Log-Debug -fn $fn -msg "CALL. UriPortal: '$Session.UriPortal'; PortalName: '$PortalName'. Filter: '$Filter'. ReturnAsXml: '$ReturnAsXml'. ParameterSetName '$($PsCmdlet.ParameterSetName)'" -fac 1;
	}
    PROCESS {
		[boolean] $fReturn = $false;

		try {
			# Parameter validation
			if(!$Session) {
				Log-Critical $fn "Unable to perform operation because the Session is empty.";
				throw($gotoFailure);
			} # if
			
			if($ListAvailable) {
				$null = Select-Portal -AdminPortal;

				[string] $Uri = [string]::Format("{0}{1}portals", $Session.UriPortal, $biz_dfch_PS_Storebox_Api.UriBase);
				[string] $Body = '';
				$response = Invoke-WebRequest -UseBasicParsing -Method 'GET' -Uri $Uri -UserAgent $biz_dfch_PS_Storebox_Api.UserAgent -WebSession $Session.WebSession;
				if(200 -ne $response.StatusCode) {
					Log-Critical $fn "Getting available portals on UriPortal '$Session.UriPortal' FAILED with StatusCode '$response.StatusCode'.";
					throw($gotoFailure);
				} # if
				$xmlResponse = [xml] $response.Content;
				$nObj = $xmlResponse.list.obj.Length;
				if(0 -ge $nObj) {
					Log-Warn $fn "Getting available portals on UriPortal '$Session.UriPortal' retrieved 0 portals." -v;
					throw($gotoFailure);
				} # if
				if($Filter) {
					for ($i = $xmlResponse.List.obj.Length-1; $i -gt 0; $i--) { 
						$obj = $xmlResponse.List.obj[$i]; 
						$obj.SelectNodes("att[@id = 'name']") | ForEach-Object { 
							if(!($_.val -match $Filter) ) { 
								$xmlResponse.List.RemoveChild($obj);
								return; 
							} # if
						} #forEach-Object
					} # for
#					$xmlResponse.list.obj | % { 
#						$sb = $_.att | Where { 
#						$_.id -eq 'Name'}; 
#						$sbName = $sb.val; 
#						if(!($sbName -match $Filter)) { 
#							$null = $xmlResponse.list.RemoveChild($_); 
#						} # if
#					} # foreach where
				} # if
				if(0 -ge $xmlResponse.list.obj.Length) {
					Log-Warn $fn "Filtering after getting '$nObj' portals on UriPortal '$Session.UriPortal' left 0 portals." -v;
					throw($gotoFailure);
				} # if
				$OutputParameter = $xmlResponse;
				$fReturn = $true;
			} else {
				
				# Check if portal is already selected. If not select it.
				if($PortalName -ne ($biz_dfch_PS_Storebox_Api.PortalName)) {
					if(!$PortalName) {
						Log-Critical $fn "Unable to perform operation on UriPortal '$Session.UriPortal' because the PortalName is empty and no portal has been selected yet. Try Select-Portal first.";
						throw($gotoFailure);
					} # if
					$null = Select-Portal -PortalName $PortalName;
					if(!$null) {
						throw($gotoFailure);
					} # if
				} # if
				# Get currently selected portal
				[string] $Uri = [string]::Format("{0}{1}", $Session.UriPortal, $biz_dfch_PS_Storebox_Api.UriBase);
				[string] $Body = '';
				$response = Invoke-WebRequest -Method 'GET' -Uri $Uri -UserAgent $biz_dfch_PS_Storebox_Api.UserAgent -WebSession $Session.WebSession;
				if(200 -ne $response.StatusCode) {
					Log-Critical $fn "Getting PortalName '$PortalName' on UriPortal '$Session.UriPortal' FAILED with StatusCode '$response.StatusCode'.";
					throw($gotoFailure);
				} # if
				$xmlResponse = [xml] $response.Content;
				if($ReturnAsXml) {
					$OutputParameter = $xmlResponse;
				} else {
					[hashtable] $PortalAttributes = @{};
					#$xmlResponse.obj.att | % { $PortalAttributes.Add($_.id -as [string], $_.val -as [string]); }
					$null = $xmlResponse.obj.att | % { 
						[string] $id = $_.id;
						[string] $val = $_.val;
						$null = $PortalAttributes.Add($id, $val); 
					}
					$OutputParameter = $PortalAttributes;
				} # if
				$fReturn = $true;
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
				
				if($_.Exception -is [System.Net.WebException]) {
					Log-Critical $fn "Operation on '$Uri' FAILED [$_].";
					Log-Debug $fn $ErrorText -fac 3;
					if($gotoFailure -ne $_.Exception.Message) { Write-Verbose ("$fn`n$ErrorText"); }
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
		Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;
    } # END
} # function
Export-ModuleMember -Function Get-Portal;


# SIG # Begin signature block
# MIIcVwYJKoZIhvcNAQcCoIIcSDCCHEQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUXMLM8cIBY59XxK9Jyzb+XbdO
# lzWgghcbMIIEFDCCAvygAwIBAgILBAAAAAABL07hUtcwDQYJKoZIhvcNAQEFBQAw
# VzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExEDAOBgNV
# BAsTB1Jvb3QgQ0ExGzAZBgNVBAMTEkdsb2JhbFNpZ24gUm9vdCBDQTAeFw0xMTA0
# MTMxMDAwMDBaFw0yODAxMjgxMjAwMDBaMFIxCzAJBgNVBAYTAkJFMRkwFwYDVQQK
# ExBHbG9iYWxTaWduIG52LXNhMSgwJgYDVQQDEx9HbG9iYWxTaWduIFRpbWVzdGFt
# cGluZyBDQSAtIEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAlO9l
# +LVXn6BTDTQG6wkft0cYasvwW+T/J6U00feJGr+esc0SQW5m1IGghYtkWkYvmaCN
# d7HivFzdItdqZ9C76Mp03otPDbBS5ZBb60cO8eefnAuQZT4XljBFcm05oRc2yrmg
# jBtPCBn2gTGtYRakYua0QJ7D/PuV9vu1LpWBmODvxevYAll4d/eq41JrUJEpxfz3
# zZNl0mBhIvIG+zLdFlH6Dv2KMPAXCae78wSuq5DnbN96qfTvxGInX2+ZbTh0qhGL
# 2t/HFEzphbLswn1KJo/nVrqm4M+SU4B09APsaLJgvIQgAIMboe60dAXBKY5i0Eex
# +vBTzBj5Ljv5cH60JQIDAQABo4HlMIHiMA4GA1UdDwEB/wQEAwIBBjASBgNVHRMB
# Af8ECDAGAQH/AgEAMB0GA1UdDgQWBBRG2D7/3OO+/4Pm9IWbsN1q1hSpwTBHBgNV
# HSAEQDA+MDwGBFUdIAAwNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFs
# c2lnbi5jb20vcmVwb3NpdG9yeS8wMwYDVR0fBCwwKjAooCagJIYiaHR0cDovL2Ny
# bC5nbG9iYWxzaWduLm5ldC9yb290LmNybDAfBgNVHSMEGDAWgBRge2YaRQ2XyolQ
# L30EzTSo//z9SzANBgkqhkiG9w0BAQUFAAOCAQEATl5WkB5GtNlJMfO7FzkoG8IW
# 3f1B3AkFBJtvsqKa1pkuQJkAVbXqP6UgdtOGNNQXzFU6x4Lu76i6vNgGnxVQ380W
# e1I6AtcZGv2v8Hhc4EvFGN86JB7arLipWAQCBzDbsBJe/jG+8ARI9PBw+DpeVoPP
# PfsNvPTF7ZedudTbpSeE4zibi6c1hkQgpDttpGoLoYP9KOva7yj2zIhd+wo7AKvg
# IeviLzVsD440RZfroveZMzV+y5qKu0VN5z+fwtmK+mWybsd+Zf/okuEsMaL3sCc2
# SI8mbzvuTXYfecPlf5Y1vC0OzAGwjn//UYCAp5LUs0RGZIyHTxZjBzFLY7Df8zCC
# BCgwggMQoAMCAQICCwQAAAAAAS9O4TVcMA0GCSqGSIb3DQEBBQUAMFcxCzAJBgNV
# BAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMRAwDgYDVQQLEwdSb290
# IENBMRswGQYDVQQDExJHbG9iYWxTaWduIFJvb3QgQ0EwHhcNMTEwNDEzMTAwMDAw
# WhcNMTkwNDEzMTAwMDAwWjBRMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFs
# U2lnbiBudi1zYTEnMCUGA1UEAxMeR2xvYmFsU2lnbiBDb2RlU2lnbmluZyBDQSAt
# IEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsk8U5xC+1yZyqzaX
# 71O/QoReWNGKKPxDRm9+KERQC3VdANc8CkSeIGqk90VKN2Cjbj8S+m36tkbDaqO4
# DCcoAlco0VD3YTlVuMPhJYZSPL8FHdezmviaJDFJ1aKp4tORqz48c+/2KfHINdAw
# e39OkqUGj4fizvXBY2asGGkqwV67Wuhulf87gGKdmcfHL2bV/WIaglVaxvpAd47J
# MDwb8PI1uGxZnP3p1sq0QB73BMrRZ6l046UIVNmDNTuOjCMMdbbehkqeGj4KUEk4
# nNKokL+Y+siMKycRfir7zt6prjiTIvqm7PtcYXbDRNbMDH4vbQaAonRAu7cf9DvX
# c1Qf8wIDAQABo4H6MIH3MA4GA1UdDwEB/wQEAwIBBjASBgNVHRMBAf8ECDAGAQH/
# AgEAMB0GA1UdDgQWBBQIbti2nIq/7T7Xw3RdzIAfqC9QejBHBgNVHSAEQDA+MDwG
# BFUdIAAwNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFsc2lnbi5jb20v
# cmVwb3NpdG9yeS8wMwYDVR0fBCwwKjAooCagJIYiaHR0cDovL2NybC5nbG9iYWxz
# aWduLm5ldC9yb290LmNybDATBgNVHSUEDDAKBggrBgEFBQcDAzAfBgNVHSMEGDAW
# gBRge2YaRQ2XyolQL30EzTSo//z9SzANBgkqhkiG9w0BAQUFAAOCAQEAIlzF3T30
# C3DY4/XnxY4JAbuxljZcWgetx6hESVEleq4NpBk7kpzPuUImuztsl+fHzhFtaJHa
# jW3xU01UOIxh88iCdmm+gTILMcNsyZ4gClgv8Ej+fkgHqtdDWJRzVAQxqXgNO4yw
# cME9fte9LyrD4vWPDJDca6XIvmheXW34eNK+SZUeFXgIkfs0yL6Erbzgxt0Y2/PK
# 8HvCFDwYuAO6lT4hHj9gaXp/agOejUr58CgsMIRe7CZyQrFty2TDEozWhEtnQXyx
# Axd4CeOtqLaWLaR+gANPiPfBa1pGFc0sGYvYcJzlLUmIYHKopBlScENe2tZGA7Bo
# DiTvSvYLJSTvJDCCBJ8wggOHoAMCAQICEhEhQFwfDtJYiCvlTYaGuhHqRTANBgkq
# hkiG9w0BAQUFADBSMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBu
# di1zYTEoMCYGA1UEAxMfR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0EgLSBHMjAe
# Fw0xMzA4MjMwMDAwMDBaFw0yNDA5MjMwMDAwMDBaMGAxCzAJBgNVBAYTAlNHMR8w
# HQYDVQQKExZHTU8gR2xvYmFsU2lnbiBQdGUgTHRkMTAwLgYDVQQDEydHbG9iYWxT
# aWduIFRTQSBmb3IgTVMgQXV0aGVudGljb2RlIC0gRzEwggEiMA0GCSqGSIb3DQEB
# AQUAA4IBDwAwggEKAoIBAQCwF66i07YEMFYeWA+x7VWk1lTL2PZzOuxdXqsl/Tal
# +oTDYUDFRrVZUjtCoi5fE2IQqVvmc9aSJbF9I+MGs4c6DkPw1wCJU6IRMVIobl1A
# cjzyCXenSZKX1GyQoHan/bjcs53yB2AsT1iYAGvTFVTg+t3/gCxfGKaY/9Sr7KFF
# WbIub2Jd4NkZrItXnKgmK9kXpRDSRwgacCwzi39ogCq1oV1r3Y0CAikDqnw3u7sp
# Tj1Tk7Om+o/SWJMVTLktq4CjoyX7r/cIZLB6RA9cENdfYTeqTmvT0lMlnYJz+iz5
# crCpGTkqUPqp0Dw6yuhb7/VfUfT5CtmXNd5qheYjBEKvAgMBAAGjggFfMIIBWzAO
# BgNVHQ8BAf8EBAMCB4AwTAYDVR0gBEUwQzBBBgkrBgEEAaAyAR4wNDAyBggrBgEF
# BQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFsc2lnbi5jb20vcmVwb3NpdG9yeS8wCQYD
# VR0TBAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDBCBgNVHR8EOzA5MDegNaAz
# hjFodHRwOi8vY3JsLmdsb2JhbHNpZ24uY29tL2dzL2dzdGltZXN0YW1waW5nZzIu
# Y3JsMFQGCCsGAQUFBwEBBEgwRjBEBggrBgEFBQcwAoY4aHR0cDovL3NlY3VyZS5n
# bG9iYWxzaWduLmNvbS9jYWNlcnQvZ3N0aW1lc3RhbXBpbmdnMi5jcnQwHQYDVR0O
# BBYEFNSihEo4Whh/uk8wUL2d1XqH1gn3MB8GA1UdIwQYMBaAFEbYPv/c477/g+b0
# hZuw3WrWFKnBMA0GCSqGSIb3DQEBBQUAA4IBAQACMRQuWFdkQYXorxJ1PIgcw17s
# LOmhPPW6qlMdudEpY9xDZ4bUOdrexsn/vkWF9KTXwVHqGO5AWF7me8yiQSkTOMjq
# IRaczpCmLvumytmU30Ad+QIYK772XU+f/5pI28UFCcqAzqD53EvDI+YDj7S0r1tx
# KWGRGBprevL9DdHNfV6Y67pwXuX06kPeNT3FFIGK2z4QXrty+qGgk6sDHMFlPJET
# iwRdK8S5FhvMVcUM6KvnQ8mygyilUxNHqzlkuRzqNDCxdgCVIfHUPaj9oAAy126Y
# PKacOwuDvsu4uyomjFm4ua6vJqziNKLcIQ2BCzgT90Wj49vErKFtG7flYVzXMIIE
# rTCCA5WgAwIBAgISESFgd9/aXcgt4FtCBtsrp6UyMA0GCSqGSIb3DQEBBQUAMFEx
# CzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMScwJQYDVQQD
# Ex5HbG9iYWxTaWduIENvZGVTaWduaW5nIENBIC0gRzIwHhcNMTIwNjA4MDcyNDEx
# WhcNMTUwNzEyMTAzNDA0WjB6MQswCQYDVQQGEwJERTEbMBkGA1UECBMSU2NobGVz
# d2lnLUhvbHN0ZWluMRAwDgYDVQQHEwdJdHplaG9lMR0wGwYDVQQKDBRkLWZlbnMg
# R21iSCAmIENvLiBLRzEdMBsGA1UEAwwUZC1mZW5zIEdtYkggJiBDby4gS0cwggEi
# MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDTG4okWyOURuYYwTbGGokj+lvB
# go0dwNYJe7HZ9wrDUUB+MsPTTZL82O2INMHpQ8/QEMs87aalzHz2wtYN1dUIBUae
# dV7TZVme4ycjCfi5rlL+p44/vhNVnd1IbF/pxu7yOwkAwn/iR+FWbfAyFoCThJYk
# 9agPV0CzzFFBLcEtErPJIvrHq94tbRJTqH9sypQfrEToe5kBWkDYfid7U0rUkH/m
# bff/Tv87fd0mJkCfOL6H7/qCiYF20R23Kyw7D2f2hy9zTcdgzKVSPw41WTsQtB3i
# 05qwEZ3QCgunKfDSCtldL7HTdW+cfXQ2IHItN6zHpUAYxWwoyWLOcWcS69InAgMB
# AAGjggFUMIIBUDAOBgNVHQ8BAf8EBAMCB4AwTAYDVR0gBEUwQzBBBgkrBgEEAaAy
# ATIwNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFsc2lnbi5jb20vcmVw
# b3NpdG9yeS8wCQYDVR0TBAIwADATBgNVHSUEDDAKBggrBgEFBQcDAzA+BgNVHR8E
# NzA1MDOgMaAvhi1odHRwOi8vY3JsLmdsb2JhbHNpZ24uY29tL2dzL2dzY29kZXNp
# Z25nMi5jcmwwUAYIKwYBBQUHAQEERDBCMEAGCCsGAQUFBzAChjRodHRwOi8vc2Vj
# dXJlLmdsb2JhbHNpZ24uY29tL2NhY2VydC9nc2NvZGVzaWduZzIuY3J0MB0GA1Ud
# DgQWBBTwJ4K6WNfB5ea1nIQDH5+tzfFAujAfBgNVHSMEGDAWgBQIbti2nIq/7T7X
# w3RdzIAfqC9QejANBgkqhkiG9w0BAQUFAAOCAQEAB3ZotjKh87o7xxzmXjgiYxHl
# +L9tmF9nuj/SSXfDEXmnhGzkl1fHREpyXSVgBHZAXqPKnlmAMAWj0+Tm5yATKvV6
# 82HlCQi+nZjG3tIhuTUbLdu35bss50U44zNDqr+4wEPwzuFMUnYF2hFbYzxZMEAX
# Vlnaj+CqtMF6P/SZNxFvaAgnEY1QvIXI2pYVz3RhD4VdDPmMFv0P9iQ+npC1pmNL
# mCaG7zpffUFvZDuX6xUlzvOi0nrTo9M5F2w7LbWSzZXedam6DMG0nR1Xcx0qy9wY
# nq4NsytwPbUy+apmZVSalSvldiNDAfmdKP0SCjyVwk92xgNxYFwITJuNQIto4zCC
# BX8wggNnoAMCAQICCmELf2sAAAAAABkwDQYJKoZIhvcNAQEFBQAwfzELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEpMCcGA1UEAxMgTWljcm9zb2Z0
# IENvZGUgVmVyaWZpY2F0aW9uIFJvb3QwHhcNMDYwNTIzMTcwMDUxWhcNMTYwNTIz
# MTcxMDUxWjBXMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1z
# YTEQMA4GA1UECxMHUm9vdCBDQTEbMBkGA1UEAxMSR2xvYmFsU2lnbiBSb290IENB
# MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2g7mmY3Oo+NPin778YuD
# JWvqSB/xKrC5lREEvfBj0eJnZs8c3c8bSCvujYmOmq8pgGWr6cctEsurHExwB6E9
# CjDNFY1P+N3UjFAVHO9Q7sQu9/zpUvKRfeBt1TUwjl5Dc/JB6dVq47KJOlY5OG8G
# PIhpWypNxadUuGyJzJv5PMrl/Yn1EjySeJbW3HRuk0Rh0Y3HRrJ1DoboGYrVbWzV
# eBaVounICjjr8iQTT3NUkxOFOhu8HjS1iwWMuXeLsdsfIJGrCVNukM57N3S5cEeR
# IlFjFnmusa5BJgjIGSvRRqpI1mQq14M0/ywqwWwZQ0oHhefTfPYhaO/q8lKff5OQ
# zwIDAQABo4IBIzCCAR8wEQYDVR0gBAowCDAGBgRVHSAAMDYGCSsGAQQBgjcVBwQp
# MCcGHysGAQQBgjcVCI3g0YlOhNecwweGpob7HI/Tv6YVARkCAW4CAQAwCwYDVR0P
# BAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFGB7ZhpFDZfKiVAvfQTN
# NKj//P1LMB0GCSsGAQQBgjcUAgQQHg4AQwByAG8AcwBzAEMAQTAfBgNVHSMEGDAW
# gBRi+wohW39DbhHaCVRQa/XSlnHxnjBVBgNVHR8ETjBMMEqgSKBGhkRodHRwOi8v
# Y3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNyb3NvZnRDb2Rl
# VmVyaWZSb290LmNybDANBgkqhkiG9w0BAQUFAAOCAgEAE8VsXgd/PFf/mzFfP72V
# VCXGefksMQNNZGlLVtlbl2988/DQJGV1OGOYE3AWE/enAfHGI+CFhmwL8ICUWnXo
# fOQekrRzv8Gzp7AL0xiEy8wJo1ycTz6wOpwtG8QE75c3lm/l7LqsarPU4jzfiyXn
# rLxiRTHdpApy5Bv4eEMBzLo5FN5dkK7YWs9eykaBUTPVpg5YZ9PYZliIFpvusRrK
# rZEThCHamm4g79oAdCi6yV/zTV3D2iVpJVTqRLzDmykzHNY8lh+HgcVT1yonM9Qu
# GXwIWG3bThmZqepf85qdjFE6Wly9L6kINZtUp9s1GlIWMzQ6o4AEav20g4ytkM8M
# OmWW7DNOGCa4SbvrgZL/E00ySyPHM+e2cWsV9pyA5ry3bL5B1QM6cTMVAFB0Ow5d
# +Zaq7ZA+qxNMgJkmvDil6wI2iR22IL6DqxD4GZ7XY3nUrrEvYTb5SkuoM8cOckH5
# 8bGQfq5G7945e3WgQRRZBB1CvEeIuBMOBfod8ICN/3DGd9hL3EYOIxpy1b/e/qqu
# aVg8/FxG5NWBmotuZVl3GjKlkKa2ZJNk/QdTyaDeKK0qbMY40YHOmPVAGeksF0Ok
# Jl/TRDBT5B0CuqQKLxbdemAnUkK7rZg3KJfkuNJ5EeMQjEjVMF0KDFLe9YjqjRot
# Z8n0gBSEt4UM0WYopcZvJGExggSmMIIEogIBATBnMFExCzAJBgNVBAYTAkJFMRkw
# FwYDVQQKExBHbG9iYWxTaWduIG52LXNhMScwJQYDVQQDEx5HbG9iYWxTaWduIENv
# ZGVTaWduaW5nIENBIC0gRzICEhEhYHff2l3ILeBbQgbbK6elMjAJBgUrDgMCGgUA
# oHAwEAYKKwYBBAGCNwIBDDECMAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFF1w
# krnJAzOkH1vCCmgVWRSVAHQzMA0GCSqGSIb3DQEBAQUABIIBADkoZOtluOsTJky0
# HmvGiXZtnIoKdXJNYcOBa3fR1nH65woOLW0WWaf2XBU5uj379CgnIGM1Nsllhbxk
# 2eIssl0+5Np8DVv+1qB0P3/1wUcXNFmDvYBOEmMC50e4vXJ4OVPUPxtF1tlox+7N
# V5SbG87KeyJ/ausUhQxmTvV7yessSJGPfA1VQwEoJuQtJUtjwG7qdekpEinwcp3F
# ZRSGiZ0uo+M4BvkqEo/1fqvCefPwI1YTNGGuu3j4225V7kGYOH862V9X+7Uf3sbD
# Mi10gQTnEJyZ9vpXVd8WjhJyL5lYalYifRrZXQ9DX4hmpdWPpGZ6rvMpWDo8lE1b
# siAmQeyhggKiMIICngYJKoZIhvcNAQkGMYICjzCCAosCAQEwaDBSMQswCQYDVQQG
# EwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTEoMCYGA1UEAxMfR2xvYmFs
# U2lnbiBUaW1lc3RhbXBpbmcgQ0EgLSBHMgISESFAXB8O0liIK+VNhoa6EepFMAkG
# BSsOAwIaBQCggf0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0B
# CQUxDxcNMTQxMTE2MDgwMzMxWjAjBgkqhkiG9w0BCQQxFgQU73EElfoSoHCPn68C
# tQ1xPansBAUwgZ0GCyqGSIb3DQEJEAIMMYGNMIGKMIGHMIGEBBSM5p9QEuHRqPs5
# Xi4x4rQr3js0OzBsMFakVDBSMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFs
# U2lnbiBudi1zYTEoMCYGA1UEAxMfR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0Eg
# LSBHMgISESFAXB8O0liIK+VNhoa6EepFMA0GCSqGSIb3DQEBAQUABIIBAD2VYmnE
# 27RX+93BRdr2KMbItt5WOWKIjqkntZUP4nz0jm9j5rNmIHoo6axkEp5OWsIfRcYT
# YaZ9rCaNOtaQ40n8SwRIAgdvEkfmkb5vHjEBROppmYLPtGMTk/tWbIPX2MbSo1hc
# cUT5SFzD2uhUT+qdTg2k75A6J2tqOnLIA9/ZCWvcjIRHjf6zdPsjOPzYHQ52Xhcx
# +oExC7xyPfeVY9aESGi+OHc6e/AVyVJQ+4CW8U1fAf2J84IkI7FfBbRbpyI/xpp+
# lKHTpgo9vuzpe5xXrT9gY1XUCqs4BwW8+FNmcYLUcy5x+CKZ9je07SiiuDKxonop
# aHS1g2R0CT3BF9U=
# SIG # End signature block
