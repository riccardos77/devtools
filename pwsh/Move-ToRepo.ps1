function Move-ToRepo {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ArgumentCompleter({ ProjectName_ArgumentCompleter @args })]
    [string]$ProjectName,

    [Parameter(Mandatory = $false)]
    [ArgumentCompleter({ RepoName_ArgumentCompleter @args })]
    [string]$RepoName
  )

  Push-Location $(Get-RepoFullPath $ProjectName $RepoName)
}
