$Global:ProjectsJson = @{}
$Global:VSCodeVersion = "code.cmd"

function Set-ProjectJson {
  param(
    [string]$Project,
    [string]$Path
  )

  $Global:ProjectsJson[$Project] = Get-Content -Path $Path -Raw | ConvertFrom-Json
}

function Set-VSCodeVersion {
  param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('stable', 'insiders')]
    [string]$Version
  )

  $Global:VSCodeVersion = $Version -eq 'stable' ? "code.cmd" : "code-insiders.cmd"
}

function Get-RepoList() {
  param(
    [ArgumentCompleter({ ProjectName_ArgumentCompleter @args })]
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Project,
    [string]$Path
  )
  RepoName_ArgumentCompleter -fakeBoundParameters @{ ProjectName = $Project }
}

function Script:ProjectName_ArgumentCompleter {
  param (
    $commandName,
    $parameterName,
    $wordToComplete,
    $commandAst,
    $fakeBoundParameters
  )

  $Global:ProjectsJson.Keys | Where-Object { $_ -like "$wordToComplete*" }
}

function Script:ProjectModuleName_ArgumentCompleter {
  param (
    $commandName,
    $parameterName,
    $wordToComplete,
    $commandAst,
    $fakeBoundParameters
  )

  $projectJson = $Global:ProjectsJson.$($fakeBoundParameters.ProjectName)

  $projectJson.modules.PSObject.Properties.Name | Where-Object { $_ -like "$wordToComplete*" }
}
function Script:RepoName_ArgumentCompleter {
  param (
    $commandName,
    $parameterName,
    $wordToComplete,
    $commandAst,
    $fakeBoundParameters
  )

  if ($fakeBoundParameters.ContainsKey('ProjectName')) {
    $projectJson = $Global:ProjectsJson.$($fakeBoundParameters.ProjectName)
    $projectRootPath = $projectJson.rootPath

    [array]$repoInJson = $projectJson.repos.PSObject.Properties.Name
    [array]$repoFolders = (Get-ChildItem -Path $projectRootPath -Filter .git -Hidden -Recurse -Directory -Depth 4).Parent.FullName | ForEach-Object { $_.Replace($projectRootPath + "\", "") }

    ($repoInJson + $repoFolders) | Get-Unique | Where-Object { $_ -like "*$wordToComplete*" }
  }
  else {
    @()
  }
}

function Script:Get-RepoFullPath([string]$ProjectName, [string]$RepoName) {
  return $(Join-Path $Global:ProjectsJson.$ProjectName.rootPath $RepoName)
}
