#######################################
##### REQUIRES InvokeBuild MODULE #####
#######################################

$moduleName = $PSScriptRoot.Split('\')[-1]

$srcPath     = "$PSScriptRoot\src"
$publicPath  = "$srcPath\public"
$privatePath = "$srcPath\private"
$classesPath = "$srcPath\classes"

$buildPath  = "$PSScriptRoot\build"
$modulePath = "$buildPath\$moduleName"




task Build {

    if(-not (Test-Path $modulePath))
    {
        New-Item $modulePath -ItemType Directory | Out-Null
    }

    $publicFiles  = @(Get-ChildItem -Path $publicPath  -Filter *.ps1 -Recurse -Force -File)
    $privateFiles = @(Get-ChildItem -Path $privatePath -Filter *.ps1 -Recurse -Force -File)
    $classesFiles = @(Get-ChildItem -Path $classesPath -Filter *.ps1 -Recurse -Force -File)

    $AddContentParams = @{
        Path     = "$modulePath\$moduleName.psm1"
        Encoding = 'utf8'
    }
    
    Add-Content @AddContentParams -Value $null

    foreach($file in ($publicFiles+$privateFiles+$classesFiles))
    {
        Add-Content @AddContentParams -Value (Get-Content -Path $file.FullName)
    }

    #Copy-Item -Path "$srcPath\$moduleName.psd1" -Destination $modulePath

    $FunctionsToExport = $publicFiles.BaseName | Where-Object{$_ -Match '^[^-]+-[^-]+$'}
    


    ##### ModuleGuid #####

    $moduleGuidPath = "$PSScriptRoot\ModuleGuid.txt"

    if(-not (Test-Path $moduleGuidPath))
    {
        Set-Content -Path $moduleGuidPath -Value ([guid]::NewGuid().Guid) -NoNewline
    }

    $moduleGuid = Get-Content -Path $moduleGuidPath

    ##### ModuleGuid #####





    ##### Increment version #####
    $versionPath = "$PSScriptRoot\version.txt"

    if(-not (Test-Path $versionPath))
    {
        Set-Content -Value '0.0.0' -Path $versionPath -Encoding utf8
    }

    $version = [version]::Parse((Get-Content -Path $versionPath))
    
    $version = '{0}.{1}.{2}' -f $version.Major,$version.Minor,($version.Build+1)

    Set-Content -Value $version -Path $versionPath -Encoding utf8




    $NewModuleManifestParams = @{
        Path              = "$modulePath\$moduleName.psd1"
        RootModule        = "$moduleName.psm1"
        ModuleVersion     = $version
        FunctionsToExport = $FunctionsToExport
        #AliasesToExport   = $AliasesToExport
        GUID = $moduleGuid
        Author = 'Charles W. Jones'
        CompanyName = 'charleswj'
        Copyright = '(c) {0} Charles W. Jones. All rights reserved.' -f [datetime]::Now.Year
        Description = ''

    }

    New-ModuleManifest @NewModuleManifestParams

    <#
    $UpdatePSModuleManifestParams = @{
        Path              = "$modulePath\$moduleName.psd1"
        RootModule        = "$moduleName.psm1"
        ModuleVersion     = $version
        FunctionsToExport = $FunctionsToExport
        #AliasesToExport   = $AliasesToExport
    }
    Update-PSModuleManifest @UpdatePSModuleManifestParams
    #>
        




}

# # Synopsis: Remove temp files.
task Clean {
    remove $modulePath
    # sleep 5
}


task PublishToPowerShellGallery {        

    $apiKey = Read-Host -Prompt 'Enter PowerShell Gallery API key' -MaskInput

    $PublishModuleParams = @{
        Path        = $modulePath
        NuGetApiKey = $apiKey
        Repository  = 'PSGallery'
        # WhatIf      = $true
    }

    Publish-Module @PublishModuleParams

}


# Synopsis: Build and clean.
# task . Build, Clean
task . Clean, Build
