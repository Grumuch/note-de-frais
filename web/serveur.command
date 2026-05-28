#!/bin/bash
# Mini-serveur HTTP pour l'app "Note de frais".
# Double-cliquez sur ce fichier (serveur.command) dans le Finder du Mac,
# ou lancez-le depuis le Terminal : ./serveur.command
#
# Il sert le dossier courant en HTTP sur le port 8080 et affiche l'adresse
# à ouvrir dans Safari sur l'iPhone (même Wi-Fi que le Mac et l'imprimante).

cd "$(dirname "$0")" || exit 1

PORT=8080

# Adresse IP locale du Mac (première interface active).
IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)
if [ -z "$IP" ]; then
  IP="<adresse-IP-du-Mac>"
fi

echo "================================================================"
echo "  Note de frais — serveur démarré"
echo "  Sur l'iPhone (même Wi-Fi), ouvrez dans Safari :"
echo ""
echo "      http://$IP:$PORT/"
echo ""
echo "  Puis 'Partager' > 'Sur l'écran d'accueil' pour l'installer."
echo "  Laissez cette fenêtre ouverte tant que vous imprimez."
echo "  Fermez-la (ou Ctrl+C) pour arrêter le serveur."
echo "================================================================"

python3 -m http.server "$PORT"
