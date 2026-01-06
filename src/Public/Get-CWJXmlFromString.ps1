function Get-CWJXmlFromString
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=1)]
        [string]
        $String,

        [Alias('XmlStartString')]
        [Parameter()]
        [string]
        $StartPattern = '<',

        [Alias('XmlEndString')]
        [Parameter()]
        [string]
        $EndPattern = '>',

        [Parameter()]
        [switch]
        $ReturnObject,

        [Parameter()]
        [switch]
        $ReturnInvalid,
        
        [Parameter()]
        [switch]
        $HideProgress,
        
        [Parameter()]
        [uint]
        $MinLength = [uint]::MinValue,
        
        [Parameter()]
        [uint]
        $MaxLength = [uint]::MaxValue
    )

    #TODO: prevent identical start and end strings?

    $xmlStartOffsetCandidates = @([regex]::Matches($String, $StartPattern).Index)

    Write-Verbose ('Start offset candidates: {0} - {1}' -f $xmlStartOffsetCandidates.Count, [string]$xmlStartOffsetCandidates)

    $xmlEndOffsetCandidates = @([regex]::Matches($String, $EndPattern).Index)

    # reversing to start with longest candidates first, otherwise some XML can parse as two valid objects 
    [array]::Reverse($xmlEndOffsetCandidates)

    Write-Verbose ('End offset candidates:   {0} - {1}' -f $xmlEndOffsetCandidates.Count, [string]$xmlEndOffsetCandidates)

    $xmlPossibleCandidates = $xmlStartOffsetCandidates.Count * $xmlEndOffsetCandidates.Count

    Write-Verbose ('Possible candidates: {0,5}' -f $xmlPossibleCandidates)

    $lastValidEnd = -1

    $xmlCandidateCounter = 0

    foreach($start in $xmlStartOffsetCandidates)
    {
        foreach($end in $xmlEndOffsetCandidates)
        {
            if(-not $HideProgress)
            {
                $xmlCandidateCounter++

                $WriteProgressParams = @{
                    Activity        = "$xmlCandidateCounter of $xmlPossibleCandidates"
                    Status          = "$start $end"
                    PercentComplete = ($xmlCandidateCounter/$xmlPossibleCandidates*100)
                }

                Write-Progress @WriteProgressParams
            }
            # sleep -m 0
            
            if($start -lt $end)
            {
                # seemed like we were finding valid XML nested inside valid XML, 
                # so we push the next start offset past the current/last end offset 
                if($start -gt $lastValidEnd)
                {
                        $length = $end - $start + 1
                        #TODO: need to deal with >1 length ending strings

                        # test for min/max candidate length
                        if($length -ge $MinLength -and $length -le $MaxLength)
                        {
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
    }
}
