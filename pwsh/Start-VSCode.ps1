function Start-VSCode {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ArgumentCompleter({ ProjectName_ArgumentCompleter @args })]
    [string]$ProjectName,

    [Parameter(Mandatory = $false)]
    [ArgumentCompleter({ RepoName_ArgumentCompleter @args })]
    [string]$RepoName
  )

  & $Global:VSCodeVersion $(Get-RepoFullPath $ProjectName $RepoName)
}
