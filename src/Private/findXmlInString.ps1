function findXmlInString
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=1)]
        [string]
        $String,

        [Parameter()]
        [string]
        $XmlStartString = '<',

        [Parameter()]
        [string]
        $XmlEndString = '>',

        [Parameter()]
        [switch]
        $ReturnObject,

        [Parameter()]
        [switch]
        $ReturnInvalid
    )

    #TODO: prevent identical start and end strings?
    #TODO: allow regex?

    $xmlStartOffsetCandidates = @([regex]::Matches($String, $XmlStartString).Index)

    Write-Verbose ('xmlStartOffsetCandidates: {0}' -f [string]$xmlStartOffsetCandidates)

    $xmlEndOffsetCandidates = @([regex]::Matches($String, $XmlEndString).Index)

    # reversing to start with longest candidates first, otherwise some XML can parse as two valid objects 
    [array]::Reverse($xmlEndOffsetCandidates)

    Write-Verbose ('xmlEndOffsetCandidates:   {0}' -f [string]$xmlEndOffsetCandidates)

    Write-Verbose ('Possible candidates: {0,5}' -f ($xmlStartOffsetCandidates.Count * $xmlEndOffsetCandidates.Count))

    $lastValidEnd = -1

    foreach($start in $xmlStartOffsetCandidates)
    {
        foreach($end in $xmlEndOffsetCandidates)
        {
            if(
                $start -lt $end -and

                # seemed like we were finding valid XML nested inside valid XML, 
                # so we push the next start offset past the current/last end offset 
                $start -gt $lastValidEnd
            )
            {
                $length = $end - $start + 1
                #TODO: need to deal with >1 length ending strings

                $xmlString = $String.Substring($start, $length)

                $xml = $null
                $isValidXml = $false

                try
                {
                    $xml = [xml]$xmlString
                    $isValidXml = $true
                    $lastValidEnd = $end
                }
                catch{}

                if($ReturnInvalid -or $null -ne $xml)
                {
                    if($ReturnObject)
                    {
                        [PSCustomObject]@{
                            Start  = $start
                            End    = $end
                            Length = $length
                            Valid  = $isValidXml
                            XML    = $xml
                            String = $xmlString
                        }
                    }
                    else
                    {
                        $xml
                    }
                }
            }
        }
    }
}
