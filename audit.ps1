# BLOC 1 : INITIALISATION
$Mode = $args[0]
$DateJour = Get-Date -Format "yyyy-MM-dd_HHmm"
$DossierSource = "incoming"
$Rapport = "audit_report_$DateJour.csv"
$Log = "audit_$DateJour.log"

# Tableaux pour le stockage groupé
$ListeC = New-Object System.Collections.Generic.List[String]
$ListeNC = New-Object System.Collections.Generic.List[String]
$ListeA = New-Object System.Collections.Generic.List[String]

# Compteurs
$NbC = 0; $NbNC = 0; $NbA = 0

# BLOC 2 : VALIDATIONS
# Vérification du mode
if ($Mode -ne "STRICT" -and $Mode -ne "RELAXED") {
    Write-Host "Usage : .\audit.ps1 STRICT ou RELAXED" -ForegroundColor Red
    exit 1
}

# Vérification du dossier
if (-not (Test-Path $DossierSource)) {
    Add-Content -Path $Log -Value "$(Get-Date) - ERREUR : Dossier source introuvable."
    exit 1
}

Add-Content -Path $Log -Value "$(Get-Date) - Début audit (Mode: $Mode)"

# BLOC 3 : TRAITEMENT
# On liste uniquement les fichiers principaux (on exclut les .meta)
$Fichiers = Get-ChildItem -Path $DossierSource -File | Where-Object { $_.Extension -ne ".meta" }

foreach ($Fichier in $Fichiers) {
    $Statut = ""
    $Raison = ""
    $MetaPath = "$($Fichier.FullName).meta"

    # A. Vérification de l'extension (.csv ou .json)
    if ($Fichier.Extension -notmatch "^\.(csv|json)$") {
        $Statut = "NON_CONFORME"
        $Raison = "Extension $($Fichier.Extension) interdite"
    }
    # B. Vérification du nom (Regex -cnotmatch pour forcer les minuscules)
    elseif ($Fichier.BaseName -cnotmatch "^[a-z]{3,10}_\d{8}_v\d{1,3}$") {
        $Statut = "NON_CONFORME"
        $Raison = "Format de nom invalide (minuscules obligatoires)"
    }
    # C. Analyse des métadonnées (.meta)
    else {
        $MetaExiste = Test-Path $MetaPath
        
        if ($Mode -eq "STRICT") {
            if (-not $MetaExiste) {
                $Statut = "NON_CONFORME"
                $Raison = "Fichier .meta absent (obligatoire en STRICT)"
            } else {
                # Lecture du fichier .meta comme un tableau de lignes
                $Contenu = Get-Content $MetaPath
                $Manquant = $false
                
                # Correction : on vérifie si chaque clé est présente au moins une fois
                foreach ($Cle in "author", "source", "created_at", "checksum") {
                    if (-not ($Contenu -match "^$Cle=")) { 
                        $Manquant = $true 
                    }
                }
                
                if ($Manquant) {
                    $Statut = "NON_CONFORME"; $Raison = "Cles obligatoires manquantes dans .meta"
                } else {
                    $Statut = "CONFORME"
                }
            }
        } 
        else { # MODE RELAXED
            if (-not $MetaExiste) {
                $Statut = "AMBIGU"
                $Raison = "Mode Relaxed : fichier meta absent"
            } else {
                $Contenu = Get-Content $MetaPath
                # Author et Source sont obligatoires en RELAXED si le fichier existe
                if (-not ($Contenu -match "^author=") -or -not ($Contenu -match "^source=")) {
                    $Statut = "NON_CONFORME"; $Raison = "Champs obligatoires (author/source) absents"
                }
                # Created_at ou Checksum manquants = Acceptable mais AMBIGU
                elseif (-not ($Contenu -match "^created_at=") -or -not ($Contenu -match "^checksum=")) {
                    $Statut = "AMBIGU"; $Raison = "Champs optionnels absents"
                } else {
                    $Statut = "CONFORME"
                }
            }
        }
    }

    # D. Stockage par catégorie + incrémentation compteurs
    $Ligne = "$($Fichier.Name),$Statut,$Raison"
    if ($Statut -eq "CONFORME") { $ListeC.Add($Ligne); $NbC++ }
    elseif ($Statut -eq "NON_CONFORME") { $ListeNC.Add($Ligne); $NbNC++ }
    else { $ListeA.Add($Ligne); $NbA++ }
}

# BLOC 4 : GÉNÉRATION DU RAPPORT GROUPÉ
$Entete = "filename,status,reasons"
$Entete | Out-File -FilePath $Rapport -Encoding utf8

"# --- FICHIERS CONFORMES ---" | Add-Content -Path $Rapport
$ListeC | Add-Content -Path $Rapport
"# --- FICHIERS AMBIGUS ---" | Add-Content -Path $Rapport
$ListeA | Add-Content -Path $Rapport
"# --- FICHIERS NON CONFORMES ---" | Add-Content -Path $Rapport
$ListeNC | Add-Content -Path $Rapport

# BLOC 5 : FINALISATION
$MsgFinal = "Resultats : $NbC Conformes, $NbNC Non Conformes, $NbA Ambigus"
Add-Content -Path $Log -Value "$(Get-Date) - Fin d'audit. $MsgFinal"

Write-Host "`nAUDIT TERMINE (PowerShell)" -ForegroundColor Cyan
Write-Host "Rapport genere : $Rapport"
Write-Host $MsgFinal -ForegroundColor White