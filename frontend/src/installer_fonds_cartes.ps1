# =========================================================================
# Script : installer_fonds_cartes.ps1
# Objet  : Copie les 2 images de fond degrade (utilisees en alternance sur
#          les 5 cartes du tableau de bord) dans le dossier public du projet.
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

$images = @(
    @{
        Name = "carte-fond-1.jpg"
        Size = 13223
        Hash = "e33d14794a57964f2dac33bb8ce1e4b93d504da3b5ed69abf5422b5d4c4ee56b"
        B64Parts = @(
            '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/',
            '2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAH2A4QDASIAAhEBAxEB/8QA',
            'HwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkK',
            'FhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXG',
            'x8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAEC',
            'AxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOE',
            'hYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD080w080w1',
            '6JBG1RmpDUZpgRmozUhphFUBG1RmpSKjamBEajYVK1RtTERNUTCpmqI0wImGKjxUzCoyOaoCJgcVEe9TsKjKjrTEV260xuhqZhzUZFUgIGFRNzxU5FMZaYiu',
            'RzUTKeasEVGRVIRXIOKiYY4qywqJlzVICsQc0x15NTMuDTGXFUhFdhxioypqwy80wiqEV2FMxUzKDTSv0pgQFabtqcrTdtMCuVppFWCtNKj0pgQbaNuan20m',
            '046UAQBSDSlak2ml25oAhC0u2pglAXFAEag07BzTwuKcFoAYBTgtO24xTgvFIBoFSAUAU9RzSAUCnigLUgWkAqipAOKRR7VIo5qWMVV4qRcEUAY7VIFA7VIC',
            'jipFGDSKue1SAelSxjlHAp6ihRUirUsY5RUgHNIoqRRk1DGKoxUqikUcVIopDFWpR6U1RzUgFSwHAVKKao7VIBSAValWmKMGpQKQCgVItNAp4FIY4GnjrTQK',
            'eBSAUVIBTVFPUUAPFOFNFPApAOFOpop4FACinCkFOFIBRS0lKKQC0tJmigYvenCkFOFIBaUUlKKQDhSikpRSGOpRSUFVFTOQ4qRRk1DGKoxUqikUcVIopDFWpR6U1RzUgFSwHAVKKao7VIBSAValWmKMGpQKQCgVItNAp4FIY4GnjrTQK',