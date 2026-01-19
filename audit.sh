#!/bin/bash

# BLOC 1 : INITIALISATION
MODE=$1
DATE_JOUR=$(date +%Y-%m-%d_%H%M)
DOSSIER_SOURCE="incoming"
RAPPORT="audit_report_${DATE_JOUR}.csv"
LOG="audit_${DATE_JOUR}.log"

TMP_C="tmp_conforme.csv"
TMP_NC="tmp_non_conforme.csv"
TMP_A="tmp_ambigu.csv"

> "$TMP_C"; > "$TMP_NC"; > "$TMP_A"

nb_conforme=0; nb_non_conforme=0; nb_ambigu=0

# BLOC 2 : VALIDATION MODE
if [[ "$MODE" != "STRICT" && "$MODE" != "RELAXED" ]]; then
    echo "Usage : ./audit.sh [STRICT|RELAXED]"
    exit 1
fi

echo "$(date) - Début audit (Mode: $MODE)" >> "$LOG"

# BLOC 3 : BOUCLE DE TRAITEMENT 
for chemin_fichier in "$DOSSIER_SOURCE"/*; do
    [ -d "$chemin_fichier" ] && continue
    [[ "$chemin_fichier" == *.meta ]] && continue

    nom_complet=$(basename "$chemin_fichier")
    ext="${nom_complet##*.}"
    nom_sans_ext="${nom_complet%.*}"
    meta="${chemin_fichier}.meta"
    
    statut=""; raison=""

    # Règle 1 : Vérif extension (.csv ou .json)
    if [[ "$ext" != "csv" && "$ext" != "json" ]]; then
        statut="NON_CONFORME"
        raison="Extension $ext interdite"
    
    # Règle 2 : Vérif format nom (regex)
    elif [[ ! "$nom_sans_ext" =~ ^[a-z]{3,10}_[0-9]{8}_v[0-9]{1,3}$ ]]; then
        statut="NON_CONFORME"
        raison="Format de nom invalide"

    # Règle 3 : Vérif métadonnées selon MODE
    else
        if [ "$MODE" == "STRICT" ]; then
            if [ ! -f "$meta" ]; then
                statut="NON_CONFORME"; raison="Meta absent (STRICT)"
            else
                manquant=0
                for cle in "author" "source" "created_at" "checksum"; do
                    grep -q "^${cle}=" "$meta" || manquant=1
                done
                [ $manquant -eq 1 ] && statut="NON_CONFORME" && raison="Cles manquantes (STRICT)" || statut="CONFORME"
            fi
        # MODE RELAXED : .meta optionnel, author+source obligatoires si présent
        else
            if [ ! -f "$meta" ]; then
                statut="AMBIGU"; raison="Meta absent (RELAXED)"
            else
                if ! grep -q "^author=" "$meta" || ! grep -q "^source=" "$meta"; then
                    statut="NON_CONFORME"; raison="Author/Source manquant"
                elif ! grep -q "^created_at=" "$meta" || ! grep -q "^checksum=" "$meta"; then
                    statut="AMBIGU"; raison="Cles secondaires manquantes"
                else
                    statut="CONFORME"
                fi
            fi
        fi
    fi

    # Stockage par catégorie + incrémentation compteurs
    ligne="${nom_complet},${statut},${raison}"
    if [ "$statut" == "CONFORME" ]; then
        echo "$ligne" >> "$TMP_C"; ((nb_conforme++))
    elif [ "$statut" == "NON_CONFORME" ]; then
        echo "$ligne" >> "$TMP_NC"; ((nb_non_conforme++))
    else
        echo "$ligne" >> "$TMP_A"; ((nb_ambigu++))
    fi
done

# === BLOC 4 : GÉNÉRATION RAPPORT GROUPÉ ===
echo "filename,status,reasons" > "$RAPPORT"
echo "# --- FICHIERS CONFORMES ---" >> "$RAPPORT"
cat "$TMP_C" >> "$RAPPORT"
echo "# --- FICHIERS AMBIGUS ---" >> "$RAPPORT"
cat "$TMP_A" >> "$RAPPORT"
echo "# --- FICHIERS NON CONFORMES ---" >> "$RAPPORT"
cat "$TMP_NC" >> "$RAPPORT"

rm "$TMP_C" "$TMP_NC" "$TMP_A"

echo "$(date) - Fin. Resultats : $nb_conforme C, $nb_non_conforme NC, $nb_ambigu A" >> "$LOG"
echo "---------------------------------------"
echo "Audit terminé. Rapport groupé généré : $RAPPORT"
echo "Conformes : $nb_conforme | Ambigus : $nb_ambigu | Non Conformes : $nb_non_conforme"
echo "---------------------------------------"