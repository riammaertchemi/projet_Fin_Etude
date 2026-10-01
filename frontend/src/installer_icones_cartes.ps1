# =========================================================================
# Script : installer_icones_cartes.ps1
# Objet  : Copie les 5 nouvelles images d'icones (une par carte du tableau de
#          bord) directement dans le dossier public du projet.
#
# A executer depuis la racine du projet : albideynet-frontend
# (le dossier qui contient le sous-dossier "src")
# =========================================================================

$ErrorActionPreference = "Stop"

if (-not (Test-Path "src\app\app.ts")) {
    Write-Host "ERREUR : ce script doit etre execute depuis la racine du projet 'albideynet-frontend' (le dossier qui contient 'src')." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path "public")) {
    Write-Host "ERREUR : le dossier 'public' est introuvable a la racine du projet." -ForegroundColor Red
    exit 1
}

$icons = @(
    @{
        Name = "icone-produits.jpg"
        Size = 2412
        Hash = "8aa8c76babb75f0d693d3c6c92898c119d1a557aee5dfdc6e22fa2a2d3cb95be"
        B64Parts = @(
            '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'
        )
    },
    @{
        Name = "icone-categories.jpg"
        Size = 3687
        Hash = "df3a68e7859bb04c1e4aee1c6af5acce6aabfe7b9e0441e4726f04851b643ffa"
        B64Parts = @(
            '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'
        )
    },
    @{
        Name = "icone-fournisseurs.jpg"
        Size = 2737
        Hash = "0266f1dc40862cebaaf64792825f60df515bd30f27104aa622bfc4dd577db823"
        B64Parts = @(
            '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'
        )
    },
    @{
        Name = "icone-mouvements.jpg"
        Size = 3536
        Hash = "5dd0076626929ef7bb140500f45f955b5f7a89a1f2925a0bafe8b73fcb4ad62d"
        B64Parts = @(
            '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',
            'sBKhBsKABCELg7SBCEKBFQhIgQEIQoE//9k='
        )
    },
    @{
        Name = "icone-alertes.jpg"
        Size = 3273
        Hash = "a4694979762656fad2141812e2b4a30f09c80097f506142ba4c78b20cffa4cfc"
        B64Parts = @(
            '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'
        )
    }
)

foreach ($icon in $icons) {
    $destPath = "public\" + $icon.Name
    Write-Host "Installation de $($icon.Name) ..." -ForegroundColor Cyan
    $b64 = [string]::Join('', $icon.B64Parts)
    $bytes = [Convert]::FromBase64String($b64)
    [IO.File]::WriteAllBytes($destPath, $bytes)

    $actualSize = (Get-Item $destPath).Length
    $actualHash = (Get-FileHash -Path $destPath -Algorithm SHA256).Hash.ToLower()

    if ($actualSize -ne $icon.Size -or $actualHash -ne $icon.Hash) {
        Write-Host "ERREUR : $($icon.Name) ne correspond pas au fichier attendu." -ForegroundColor Red
        exit 1
    }
    Write-Host "  OK : $($icon.Name) ($actualSize octets)." -ForegroundColor Green
}

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Green
Write-Host "  TERMINE : les 5 icones sont installees dans public\" -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Prochaine etape : lance remplacer_icones_cartes.ps1" -ForegroundColor Yellow
Write-Host ""