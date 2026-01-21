# Audit de Conformité - CAS 3

**Auteurs :** Ridwan ABDOULKADER HOUMED & Henri TURCAS (Sup de Vinci)

Scripts d'automatisation du contrôle de conformité de fichiers entrants (Bash et PowerShell).

## Prérequis

- **Bash** 4.0+ (Linux/WSL)
- **PowerShell** 5.1+ (Windows)
- Dossier `incoming/` contenant les fichiers à auditer

## Lancement

### Bash (Linux/WSL)
```bash
chmod +x audit.sh
./audit.sh STRICT    # Mode exigeant
./audit.sh RELAXED   # Mode tolérant
```

### PowerShell (Windows)
```powershell
.\audit.ps1 STRICT   # Mode exigeant
.\audit.ps1 RELAXED  # Mode tolérant
```

## Règles de validation

### Nommage
Format exact : `[a-z]{3,10}_YYYYMMDD_v[0-9]{1,3}.[csv|json]`

**Exemples valides :**
- `projet_20260119_v1.csv`
- `database_20260119_v123.json`

**Exemples invalides :**
- `Projet_20260119_v1.csv` (majuscule)
- `projet20260119v1.csv` (sans underscores)
- `projet_20241399_v1.csv` (date invalide)

### Métadonnées
Fichier `.meta` associé avec structure clé=valeur :
```
author=Nom
source=systeme
created_at=2026-01-19T10:00:00Z
checksum=abc123def456
```

## Modes

**STRICT :** Le fichier `.meta` et les 4 clés (author, source, created_at, checksum) sont obligatoires. Toute absence → NON_CONFORME.

**RELAXED :** Le `.meta` peut être absent → statut AMBIGU. Si présent, author et source sont obligatoires. Absence de created_at ou checksum → statut AMBIGU.

## Lancement Automatique
Lancement de l'audit en continu (exécution chaque matin à 8h) grâce au Crontab. 

## Résultats

**Rapport CSV :** `audit_report_YYYY-MM-DD_HHMM.csv` - Fichiers groupés par statut (Conforme, Ambigu, Non Conforme).

**Log :** `audit_YYYY-MM-DD_HHMM.log` - Trace d'exécution avec statistiques finales.