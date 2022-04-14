function Pull-Repo {
  [CmdletBinding(DefaultParameterSetName = 'ByModule')]
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

    [Parameter(ParameterSetName = 'ByModule')]
    [Parameter(ParameterSetName = 'ByRepo')]
    [ValidateSet('develop')]
    [string]$CheckoutCodeline,

    [Parameter(ParameterSetName = 'ByModule')]
    [Parameter(ParameterSetName = 'ByRepo')]
    [ValidateSet('pull', 'showBranch', 'showStatus')]
    [string]$Action = 'pull'
  )

  function Get-Branch() {
    $currentBranch = git branch --show-current | Out-String -NoNewline
    return $currentBranch;
  }

  function Write-Branch([string]$branch) {
    if ($branch -eq "master") {
      Write-Host "Current branch: $branch" -ForegroundColor Black -BackgroundColor Gray
    }
    elseif ($branch -eq "develop") {
      Write-Host "Current branch: $branch" -ForegroundColor Black -BackgroundColor Gray
    }
    elseif ($branch -eq "sprint") {
      Write-Host "Current branch: $branch" -ForegroundColor Black -BackgroundColor DarkYellow
    }
    else {
      Write-Host "Current branch: $branch" -ForegroundColor White -BackgroundColor DarkGreen
    }
    Write-Host ""
  }

  function Get-Repo([string] $repo) {
    $repoFullPath = Get-RepoFullPath $ProjectName $repo

    Write-Host ""
    Write-Host -Object "----- Repo $repoFullPath" -ForegroundColor Yellow -BackgroundColor DarkBlue
    Write-Host ""

    if (Test-Path -Path $repoFullPath) {
      Set-Location $repoFullPath

      switch ($Action) {
        'pull' {
          if (!$CheckoutCodeline) {
            $currentBranch = Get-Branch
            Write-Branch $currentBranch

            git pull
            git submodule update
          }
          else {
            $newBranch = $CheckoutCodeline
            $currentBranch = Get-Branch

            if ($currentBranch -eq $newBranch) {
              Write-Branch $currentBranch

              git pull
              git submodule update
            }
            else {
              Write-Host "Switching branch to $newBranch..."

              git fetch
              git checkout $newBranch

              $currentBranch = Get-Branch

              if ($currentBranch -eq $newBranch) {
                Write-Branch $currentBranch

                git pull
                git submodule update
              }
              else {
                Write-Host "Error switching branch, still on $currentBranch"  -ForegroundColor White -BackgroundColor DarkRed
                Write-Host ""
              }
            }
          }
        }
        'showBranch' {
          $currentBranch = Get-Branch
          Write-Branch $currentBranch
        }
        'showStatus' {
          $currentBranch = Get-Branch
          Write-Branch $currentBranch

          git fetch
          git status
        }
      }
    }
    else {
      Write-Host "Repo not found, skipping"
    }
  }


  $currentFolder = Get-Location

  try {
    if ($ModuleName -ne "") {
      foreach ($repoInModule in $Global:ProjectsJson.$ProjectName.modules.$ModuleName) {
        Get-Repo $repoInModule
      }
    }

    if ($RepoName -ne "") {
      Get-Repo $RepoName
    }
  }
  finally {
    Set-Location $currentFolder.Path
  }
}
