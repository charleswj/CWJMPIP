function Get-CWJMpipFileSensitivityLabelInfo
{
    [CmdletBinding()]
    param
    (
        [Alias('PSPath')]
        [Parameter(Mandatory=1, Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]
        [ValidateNotNullOrWhiteSpace]
        $Path
    )

    process
    {
        foreach($filePath in $Path)
        {
            $filePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($filePath)

            $rawFile = Get-Content $filePath -Raw

            $xml = @(Get-CWJXmlFromString -String $rawFile -XmlStartString '<\?xml' -XmlEndString '>')

            if($xml.Count -gt 1)
            {
                Write-Warning 'more than one XML object found, checking each until a valid one is found'
            }

            foreach($xmlObject in $xml)
            {
                if($null -ne $xmlObject.XrML)
                {
                    $MpipInfo = $xml
                    break
                }
            }

            if($null -ne $MpipInfo)
            {
                [pscustomobject]@{
                    FileName        = $filePath #: C:\Users\admin\Documents\Doc1.docx
                    IsLabeled       = $null #: True
                    MainLabelId     = $xml.SelectNodes('/XrML/BODY/AUTHENTICATEDDATA[@id=''LABEL'' and @name=''ID'']/text()').Value #: 7fff6936-455f-4307-b66d-378f7866d130
                    MainLabelName   = $xml.SelectNodes('/XrML/BODY/DESCRIPTOR/OBJECT/NAME/text()').Value.Split(':').Where{$_ -like 'NAME *'}.Substring(5) #: SSAN Label # LCID locale identifyer aka language code, DESCRIPTION (admin?) description
                    SubLabelId      = $null #:
                    SubLabelName    = $null #:
                    LabelingMethod  = $null #: Privileged
                    LabelDate       = [datetime]$xml.SelectNodes('/XrML/BODY/ISSUEDTIME/text()').Value #: 4/1/2025 10:12:14 AM
                    IsRMSProtected  = $null #: True
                    RMSTemplateId   = ([guid]$xml.SelectNodes('/XrML/BODY/DESCRIPTOR/OBJECT/ID/text()').Value).ToString('D') # 01a95542-8dd7-42b6-9444-bb402a459a1e
                    RMSTemplateName = $xml.SelectNodes('/XrML/BODY/DESCRIPTOR/OBJECT/NAME/text()').Value.Split(':').Where{$_ -like 'NAME *'}.Substring(5) #: SSAN Label
                    RMSOwner        = $xml.SelectNodes('/XrML/BODY/WORK/METADATA/OWNER/OBJECT/NAME/text()').Value #: admin@motherchucker.com
                    IssuedTo        = $xml.SelectNodes('/XrML/BODY/WORK/METADATA/OWNER/OBJECT/NAME/text()').Value #: admin@motherchucker.com
                    ContentId       = ([guid]$xml.SelectNodes('/XrML/BODY/WORK/OBJECT/ID/text()').Value).ToString('D') #: 7af202e8-44ec-4c81-a6cc-0073935a9089
                }
            }
        }
    }
}



    #TODO can a file be encrypted w/o a label? what will it look like? what does the purviewinformationprotection module say?

    

    #TODO: deal with no matches, more than one match, more than one opening, more thn one closing


    <#

    $b=$a.Where{$_ -match 'XrML'}
    $c=[xml]($b[0]+$b[1])
    $c.XrML.BODY.AUTHENTICATEDDATA[0].'#text'



    XrML.BODY.

            XrML.BODY.ISSUEDTIME 			= 2025-04-01T15:12
    label name	XrML.BODY.DESCRIPTOR.OBJECT.NAME	= LCID 1033:NAME SSAN Label:DESCRIPTION SSAN Label Admin Name Description;


    DESCRIPTOR.OBJECT.
            <ID type="MS-GUID" version="2025-02-27T18:14">{01a95542-8dd7-42b6-9444-bb402a459a1e}</ID>



        <ISSUER>
        <SECURITYLEVEL name="Tenant-ID" value="{e8f87eb4-3f2f-49e5-91df-452640f0e36e}"/>
        </ISSUER>
        <ISSUEDPRINCIPALS>
        <PRINCIPAL internal-id="1">
            <SECURITYLEVEL name="Tenant-ID" value="{e8f87eb4-3f2f-49e5-91df-452640f0e36e}"/>
        </PRINCIPAL>
        </ISSUEDPRINCIPALS>
        <WORK>
        <METADATA>
            <OWNER>
            <OBJECT>
                <ID type="Unspecified"/>
                <NAME>admin@motherchucker.com</NAME>
            </OBJECT>
            </OWNER>
        </METADATA>
        </WORK>
        <AUTHENTICATEDDATA name="ID" id="LABEL">7fff6936-455f-4307-b66d-378f7866d130</AUTHENTICATEDDATA>		#label guid
        <AUTHENTICATEDDATA name="TenantId" id="LABEL">e8f87eb4-3f2f-49e5-91df-452640f0e36e</AUTHENTICATEDDATA>

    #>