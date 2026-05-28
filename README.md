# Note de frais — iPhone → Epson TM-m30III (Wi-Fi)

App web (PWA) qui imprime une **note de frais** sur une imprimante
**Epson TM-m30III** connectée au **même Wi-Fi** que l'iPhone.

- **Développée sous Windows**, utilisée **sur iPhone**.
- **Pas d'App Store**, pas de Xcode, pas de compte développeur Apple.
- Elle s'installe sur l'écran d'accueil comme une vraie app (PWA) et
  parle directement à l'imprimante via l'**API ePOS-Print** d'Epson
  (aucun SDK propriétaire à télécharger).
- La mise en page du ticket reproduit le modèle fourni (en-tête restaurant,
  lignes, sous-total HT, TVA par taux, TOTAL TTC, paiements). Tous les
  champs sont saisissables et mémorisés sur le téléphone.

> **Pourquoi en HTTPS ?** Safari interdit à une page HTTPS de parler à un
> appareil en HTTP. On héberge donc l'app en **HTTPS** (GitHub Pages) et on
> active le **HTTPS sur l'imprimante**, puis on fait confiance à son
> certificat une seule fois sur l'iPhone (voir étape 3).

---

## 1. Mettre l'app en ligne (HTTPS) — depuis Windows

L'app est un site statique. Le plus simple est **GitHub Pages** (HTTPS gratuit) :

1. Poussez ce dépôt sur GitHub (déjà fait si vous lisez ceci sur GitHub).
2. Dans le dépôt : **Settings → Pages → Build and deployment → Source = GitHub Actions**.
3. À chaque `git push` sur la branche, le workflow `.github/workflows/pages.yml`
   publie le site. L'URL s'affiche dans l'onglet **Actions** puis **Settings → Pages**,
   du type `https://VOTRE-COMPTE.github.io/note-de-frais/`.

> Tester en local sous Windows (optionnel) : `py -m http.server 8080` puis
> `http://localhost:8080`. ⚠️ En HTTP local, l'impression vers une imprimante
> en HTTPS sera bloquée par le navigateur — utilisez l'URL Pages (HTTPS) pour
> les vrais essais d'impression.

## 2. Préparer l'imprimante (une fois)

1. Branchez la TM-m30III en Wi-Fi sur le **même réseau** que l'iPhone.
2. Trouvez son **adresse IP** : appuyez sur le bouton **FEED** en l'allumant,
   elle imprime un ticket de configuration avec l'IP (ex. `192.168.1.125`).
3. Dans la page de configuration web de l'imprimante (Epson TM Utility ou
   `http://IP-de-l-imprimante/`), vérifiez que **ePOS-Print** est **activé**
   et que le **SSL/TLS** (HTTPS) est activé.

## 3. Installer l'app sur l'iPhone

1. Vérifiez que l'iPhone est sur le **même Wi-Fi** que l'imprimante.
2. **Faites confiance au certificat de l'imprimante** : dans Safari, ouvrez
   `https://IP-de-l-imprimante/` une fois et acceptez l'avertissement de
   sécurité (certificat auto-signé). Sans cette étape, l'impression échoue.
3. Ouvrez l'**URL GitHub Pages** dans Safari.
4. **Partager** (carré avec flèche) → **Sur l'écran d'accueil**. Vous obtenez
   l'icône « Note de frais ».

## 4. Configurer

1. Touchez l'engrenage **⚙︎** (en haut à droite).
2. Renseignez l'en-tête du restaurant (nom, adresse, téléphone, TVA intra, SIRET).
3. **Adresse ePOS-Print** : `https://IP-de-l-imprimante/cgi-bin/epos/service.cgi?devid=local_printer&timeout=10000`
   (remplacez l'IP). **Largeur** : `48` pour du 80 mm.
4. Fermez : tout est enregistré sur le téléphone.

## 5. Imprimer

1. Saisissez les **lignes** (désignation + montant), les **montants HT par
   taux de TVA**, puis les **paiements**.
2. Vérifiez l'**aperçu**, puis touchez **Imprimer**.

---

## Calculs (par taux de TVA)

- `TVA = HT × taux`, `TTC = HT + TVA`
- `Sous total HT = Σ HT`, `Total TVA = Σ TVA`, `TOTAL TTC = HT + TVA`

## Dépannage

- **« Échec … »** à l'impression : IP/port incorrects, iPhone et imprimante
  pas sur le même Wi-Fi, ou **certificat de l'imprimante non accepté** (étape 3.2).
- **Colonnes décalées** : changez la **Largeur** dans Réglages (essayez `42`).
- **Accents mal imprimés** : réglez le **jeu de caractères** de l'imprimante
  sur **WPC1252 / Europe de l'Ouest** dans sa configuration.
- **L'app ne parle pas à l'imprimante alors que l'aperçu est correct** :
  l'app doit être servie en **HTTPS** (URL GitHub Pages), pas en `http://localhost`.

## Structure

```
index.html              écran principal (formulaire + aperçu)
css/styles.css          interface
js/app.js               état, formulaires, persistance, impression
js/receipt.js           calculs TVA + mise en forme du ticket
js/epos.js              génération XML ePOS-Print + envoi HTTP
manifest.webmanifest    PWA (ajout à l'écran d'accueil)
sw.js                   service worker (ouverture hors connexion)
icons/                  icônes de l'app
tools/make_icons.py     (re)génère les icônes
.github/workflows/      déploiement GitHub Pages
```
