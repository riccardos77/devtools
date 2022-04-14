function Invoke-DockerBuild {
  [CmdletBinding(DefaultParameterSetName = "ByModule")]
  param (
    [Parameter(ParameterSetName = "ByModule", Mandatory = $true, Position = 0)]
    [Parameter(ParameterSetName = "ByRepo", Mandatory = $true, Position = 0)]
    [ArgumentCompleter({ ProjectName_ArgumentCompleter @args })]
    [string]$ProjectName,

    [Parameter(ParameterSetName = "ByModule", Position = 1)]
    [ArgumentCompleter({ ProjectModuleName_ArgumentCompleter @args })]
    [string]$ModuleName,

    [Parameter(ParameterSetName = "ByRepo", Mandatory = $false)]
    [ArgumentCompleter({ RepoName_ArgumentCompleter @args })]
    [string]$RepoName,

    [Parameter(ParameterSetName = "ByModule")]
    [ValidateSet("all", "server", "client")]
    [string]$Layer = "server",

    [Parameter(ParameterSetName = "ByModule")]
    [Parameter(ParameterSetName = "ByRepo")]
    [Switch]$ExtractBuildArtifacts,

    [Parameter(ParameterSetName = "ByModule")]
    [Parameter(ParameterSetName = "ByRepo")]
    [ValidateSet('WEB', 'CC', 'UP')]
    [string]$Channel = $null
  )

  function Invoke-Build($repoNameArg) {
    $repoJson = $Global:ProjectsJson.$ProjectName.repos.$repoNameArg;

    $bm = $repoJson.localBuildMetadata
    if ($null -ne $bm) {
      if (($repoJson.layer -eq $Layer) -or ($Layer -eq "all")) {
        $repoFullPath = Get-RepoFullPath $ProjectName $repoNameArg

        $cmdDockerFile = "-f " + $repoFullPath + "\" + $bm.dockerFile
        $cmdImageName = "-t " + $bm.imageNameAndTag
        $cmdNetwork = $bm.network -ne "" ? "--network " + $bm.network : ""
        $cmdBuildArg = ($null -ne $Channel) -and ($Channel -ne "") ? " --build-arg channel=$($Channel.ToLower())" : ""
        $cmdPath = $repoFullPath

        $cmd = "docker build $cmdNetwork $cmdDockerFile $cmdImageName $cmdBuildArg $cmdPath"
        Write-Host -Object "----- Executing $cmd" -ForegroundColor Yellow -BackgroundColor DarkBlue
        Invoke-Expression $cmd

        $artifactsSource = $bm.artifactsSourceDirectory
        $artifactsTarget = $bm.artifactsTargetDirectory
        $extractContainerName = "build-artifact-extractor"
        if ($ExtractBuildArtifacts -and ($artifactsSource -ne "") -and ($artifactsTarget -ne "")) {
          Write-Host -Object "Copying artifacts to $artifactsTarget" -ForegroundColor Yellow -BackgroundColor DarkBlue
          Invoke-Expression "docker create -ti --name $extractContainerName $($bm.imageNameAndTag) bash"
          Remove-Item $artifactsTarget -Force -Recurse -ErrorAction Ignore
          Invoke-Expression "docker cp $($extractContainerName):$artifactsSource $artifactsTarget"
          Invoke-Expression "docker rm -f $extractContainerName"
        }
      }
    }
  }


  if ($ModuleName -ne "") {
    foreach ($repoInModule in $Global:ProjectsJson.$ProjectName.modules.$ModuleName) {
      Invoke-Build $repoInModule
    }
  }

  if ($RepoName -ne "") {
    $Layer = "all"
    Invoke-Build $RepoName
  }
}
