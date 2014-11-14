function ConvertTo-Xml {
	[CmdletBinding(
		HelpURI='http://dfch.biz/biz/dfch/PS/Storebox/Api/ConvertTo-Xml/'
    )]
	[OutputType([string])]
Param (
    [Parameter(ValueFromPipeline = $true, Mandatory = $true, Position = 0)]
    [alias("o")]
    $obj
    ,
	[Parameter(Mandatory = $false, Position = 1)]
	[alias("x")]
	$XmlWriter = $null
) # Param
BEGIN {
$datBegin = Get-Date;
[string] $fn = $MyInvocation.MyCommand.Name;
#Log-Debug -fn $fn -msg ("CALL. obj.GetType() '{0}'" -f $obj.GetType())-fac 1;

} # BEGIN

PROCESS {
[boolean] $fReturn = $false;
$OutputParameter = $null;
$XmlStringTemp = '';
$fCalledByRecursion = $false;

try {

    if(!$XmlWriter) {
	    $settings = New-Object System.Xml.XmlWriterSettings;
	    $settings.OmitXmlDeclaration = $true;
	    $ms = New-Object System.IO.MemoryStream;
	    $XmlWriter = [System.Xml.XmlWriter]::Create($ms, $settings);
    } else {
        $fCalledByRecursion = $true;
    } # if

	if($obj -is [System.Collections.Hashtable]) {
		$XmlWriter.WriteStartElement('obj');
        if($obj.'#class') { $XmlWriter.WriteAttributeString('class', $obj.'#class'); }
		#Write-Host ("<obj> @class {0}" -f $obj.'class');
		foreach($item in $obj.GetEnumerator()) {
            if($item.name -match '^#') { continue; }
		    $XmlWriter.WriteStartElement('att');
            $XmlWriter.WriteAttributeString('id', $item.name);
			#Write-Host ("<att> @id {0}" -f $item.name);
			$XmlString = ConvertTo-Xml -obj $item -XmlWriter $XmlWriter;
			$XmlWriter.WriteEndElement();
		} # foreach
        $XmlWriter.WriteEndElement();
	} elseif($obj -is [Array] -or $obj -is [System.Collections.ArrayList]) {
		$XmlWriter.WriteStartElement('list');
		#Write-Host ("<list>")
		foreach($item in $obj) {
			$XmlString = ConvertTo-Xml -obj $item -XmlWriter $XmlWriter;
			$XmlWriter.WriteString($XmlString);
		} # foreach
        $XmlWriter.WriteEndElement();
	} elseif($obj -is [System.Collections.DictionaryEntry]) {
        if($obj.Value -is [Array] -or $obj -is [System.Collections.ArrayList]) {
		    $XmlWriter.WriteStartElement('list');
		    #Write-Host ("<list>")
		    foreach($item in $obj.Value) {
                if([System.Object]::Equals($null, $item)) { continue; }
			    $XmlString = ConvertTo-Xml -obj $item -XmlWriter $XmlWriter;
			    $XmlWriter.WriteString($XmlString);
		    } # foreach
            $XmlWriter.WriteEndElement();
        } elseif($obj.Value -is [System.Collections.Hashtable]) {
            $XmlString = ConvertTo-Xml -obj $obj.Value -XmlWriter $XmlWriter;
        } else {
            if($obj.Value -is [string]) {
		        $XMLWriter.WriteElementString('val', $obj.Value);
            } elseif($obj.Value -is [int]) {
		        $XMLWriter.WriteElementString('val', $obj.Value);
            } else {
				if($obj.Value) {
					Log-Warn $fn ("Unexpected type for obj.Name '{0}' found: '{1}'" -f $obj.Name, $obj.Value);
					$XMLWriter.WriteElementString('val', $obj.Value);
				} else {
					# N/A 
				} # if
            } # if
        } # if
	} else {
        if($obj -is [string]) {
		    $XMLWriter.WriteElementString('val', $obj);
        } elseif($obj -is [int]) {
		    $XMLWriter.WriteElementString('val', $obj);
        } else {
			Log-Warn $fn ("Unexpected type for obj '{0}' found: '{1}'" -f $obj, $obj.GetType());
		} # if
    } # if

    if(!$fCalledByRecursion) {
	    $XmlWriter.Flush();
	    $XmlWriter.Close();
	    [xml] $y = New-Object System.Xml.XmlDocument;
	    $ms.Flush();
	    $ms.Position = 0;
	    $y.Load($ms);
	    $ms.Close();
	    #$y.OuterXml;
        $OutputParameter = $y.OuterXml;
        $fReturn = $true;
    } else {
        $fReturn = $false;
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
		
		if( [System.Net.WebException] -eq (($_.Exception).GetType()) ) {
			Log-Critical $fn "Operation on '$Uri' FAILED [$_].";
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
} # finally
return $OutputParameter;
} # PROCESS

END {
$datEnd = [datetime]::Now;
#Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;
} # END

} # function
Export-ModuleMember -Function ConvertTo-Xml;

