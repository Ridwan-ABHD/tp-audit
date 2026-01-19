# Audit de Conformité - CAS 3
Script Bash pour l'automatisation du contrôle de fichiers entrants. Projet réalisé par Ridwan ABDOULKADER HOUMED & Henri TURCAS (Sup de Vinci).

## Prérequis
- Bash 4.0+
- Dossier `incoming/` avec les fichiers à auditer

## Lancement
```bash
chmod +x audit.sh
./audit.sh STRICT    # Mode exigeant
./audit.sh RELAXED   # Mode tolérant
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
Fichier `.meta` associé obligatoire avec structure :
```
author=Nom
source=systeme
created_at=2026-01-19T10:00:00Z
checksum=abc123def456
```

## Modes

**STRICT :** Le .meta et les 4 clés (author, source, created_at, checksum) sont obligatoires.

**RELAXED :** Le .meta peut être absent (→ AMBIGU). Si présent, seuls author et source sont obligatoires. Absence de created_at ou checksum → AMBIGU.

## Résultats

**Rapport CSV :** `audit_report_YYYY-MM-DD_HHMM.csv` - Fichiers groupés par statut (Conforme, Ambigu, Non Conforme).

**Log :** `audit_YYYY-MM-DD_HHMM.log` - Trace d'exécution avec statistiques finales.