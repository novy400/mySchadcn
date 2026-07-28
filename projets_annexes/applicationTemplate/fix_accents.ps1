# Script de Nettoyage des Caracteres Accentues
# Usage: .\fix_accents.ps1

$OutputEncoding = [System.Text.UTF8Encoding]::new($false)

function Write-FileUTF8NoBOM {
    param([string]$Path, [string]$Content)
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Remove-Accents {
    param([string]$Text)
    
    $Text = $Text -replace 'à|á|â|ä', 'a'
    $Text = $Text -replace 'è|é|ê|ë', 'e'
    $Text = $Text -replace 'ì|í|î|ï', 'i'
    $Text = $Text -replace 'ò|ó|ô|ö', 'o'
    $Text = $Text -replace 'ù|ú|û|ü', 'u'
    $Text = $Text -replace 'ç', 'c'
    $Text = $Text -replace 'ñ', 'n'
    
    $Text = $Text -replace 'À|Á|Â|Ä', 'A'
    $Text = $Text -replace 'È|É|Ê|Ë', 'E'
    $Text = $Text -replace 'Ì|Í|Î|Ï', 'I'
    $Text = $Text -replace 'Ò|Ó|Ô|Ö', 'O'
    $Text = $Text -replace 'Ù|Ú|Û|Ü', 'U'
    $Text = $Text -replace 'Ç', 'C'
    $Text = $Text -replace 'Ñ', 'N'
    
    return $Text
}

Write-Host "Nettoyage des caracteres accentues dans generate_resource.ps1..." -ForegroundColor Yellow

$scriptPath = "scripts\generate_resource.ps1"
if (Test-Path $scriptPath) {
    $content = Get-Content $scriptPath -Raw -Encoding UTF8
    $cleanContent = Remove-Accents -Text $content
    
    Write-FileUTF8NoBOM -Path $scriptPath -Content $cleanContent
    Write-Host "Scripts nettoye avec succes!" -ForegroundColor Green
} else {
    Write-Host "Script non trouve: $scriptPath" -ForegroundColor Red
}

Write-Host "Fini!" -ForegroundColor Green