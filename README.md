# Note de frais — iPhone + Epson TM-m30III

Imprime une **note de frais** sur une imprimante **Epson TM-m30III** en Wi-Fi.

Vous saisissez :
- le **nombre de repas** (ex. « 2 repas »)
- le **montant HT** pour chaque taux de TVA (5,5 % / 10 % / 20 %)

L'app calcule la TVA, les totaux HT et TTC, affiche un aperçu, puis imprime
un ticket avec le détail de la TVA (sans le détail des plats).

Deux versions sont disponibles :

1. **App web** (`web/`) — **recommandée si vous n'avez pas Xcode.**
   S'ouvre dans Safari, s'ajoute à l'écran d'accueil comme une vraie app.
   Aucun Xcode, aucun compte développeur Apple.
2. **App native iOS** (`NoteDeFrais/`) — nécessite un Mac avec Xcode.
   Voir la section « App native » plus bas.

---

## Version recommandée : l'app web

La TM-m30III sait imprimer directement depuis un navigateur grâce au
SDK JavaScript d'Epson (`epos-2.js`). On utilise donc une simple page web,
servie en HTTP depuis votre Mac, et ouverte dans Safari sur l'iPhone.

> **Pourquoi en HTTP et pas en ligne (HTTPS) ?** Safari interdit à une page
> HTTPS de parler à un appareil en HTTP comme l'imprimante. La page doit donc
> être servie en HTTP sur le **même Wi-Fi** que l'imprimante. Le mini-serveur
> ci-dessous s'en occupe.

### 1. Récupérer le SDK Epson

1. Téléchargez **« Epson ePOS SDK for JavaScript »** sur le site support Epson.
2. Dézippez et copiez le fichier `epos-2.js` dans le dossier `web/` :
   ```
   note-de-frais/web/epos-2.js
   ```
   (le nom exact peut être `epos-2.x.y.z.js` — renommez-le `epos-2.js`).

### 2. Lancer le mini-serveur sur le Mac

Dans le Finder, ouvrez le dossier `web/` et **double-cliquez sur
`serveur.command`**. Une fenêtre Terminal s'ouvre et affiche une adresse, ex :

```
http://192.168.1.20:8080/
```

> Si macOS refuse d'ouvrir le fichier (« développeur non identifié »),
> faites **clic droit → Ouvrir**, puis confirmez. Python est déjà installé
> sur macOS, rien d'autre à télécharger.

Laissez cette fenêtre ouverte tant que vous imprimez. Pour arrêter : fermez
la fenêtre ou faites **Ctrl+C**.

### 3. Ouvrir l'app sur l'iPhone

1. Vérifiez que l'iPhone est sur le **même Wi-Fi** que le Mac et l'imprimante.
2. Dans **Safari**, ouvrez l'adresse affichée (ex. `http://192.168.1.20:8080/`).
3. Touchez **Partager** (carré avec flèche) → **Sur l'écran d'accueil**.
   Vous obtenez une icône « Note de frais » comme une vraie app.

### 4. Configurer

1. Au premier lancement, l'écran **Réglages** s'ouvre.
2. Saisissez les infos du restaurant (nom, adresse, SIRET, n° TVA…).
3. Saisissez l'**adresse IP de l'imprimante** (port `8008` par défaut).
4. **Enregistrer**.

### 5. Imprimer

1. Saisissez le nombre de repas et les montants HT par taux.
2. Touchez **Aperçu & imprimer**, vérifiez le rendu, puis **Imprimer**.

### Trouver l'IP de l'imprimante

Appuyez sur le bouton **FEED** en allumant la TM-m30III : elle imprime
un ticket de configuration avec son adresse IP.

### Dépannage (web)

- **« SDK Epson (epos-2.js) introuvable »** : le fichier `epos-2.js`
  n'est pas dans le dossier `web/`.
- **« Connexion impossible »** : IP ou port incorrect, ou iPhone/imprimante
  pas sur le même Wi-Fi. Vérifiez aussi que le port est `8008`.
- **Colonnes décalées sur le ticket** : ajustez la constante `LINE_WIDTH`
  en haut de `web/app.js` (essayez `48` au lieu de `42`).
- **L'adresse `http://…:8080` ne s'ouvre pas** : le serveur n'est pas lancé,
  ou un pare-feu macOS bloque le port. Autorisez Python dans
  **Réglages Système → Réseau → Pare-feu**.

---

## Version native iOS (optionnelle, nécessite Xcode)

Application SwiftUI dans `NoteDeFrais/`. Mêmes fonctions, plus la découverte
automatique de l'imprimante (Bonjour). À réserver si vous disposez d'un Mac
avec Xcode et de l'espace de stockage nécessaire.

### Pré-requis

- Un Mac avec **Xcode 15+**
- Un iPhone (iOS 16+)
- Le **SDK ePOS d'Epson pour iOS** (`libepos2.xcframework`)
- (Optionnel) `xcodegen` : `brew install xcodegen`

### Mise en route

1. Téléchargez le **SDK ePOS pour iOS** et copiez `libepos2.xcframework` dans
   `Vendor/EpsonSDK/`.
2. `xcodegen generate` puis `open NoteDeFrais.xcodeproj`
   (ou créez un projet Xcode iOS et glissez le dossier `NoteDeFrais/` + le
   framework dedans).
3. Onglet **Signing & Capabilities** : cochez « Automatically manage signing »,
   choisissez votre Team, mettez un Bundle ID unique.
4. **Cmd+R** pour installer sur l'iPhone connecté, puis approuvez le profil
   développeur dans **Réglages → Général → VPN et gestion d'appareils**.

> Avec un Apple ID gratuit, l'app expire après 7 jours. Pour une utilisation
> durable, il faut un compte Apple Developer Program (99 $/an).

### Structure (native)

```
NoteDeFrais/
├── NoteDeFraisApp.swift
├── Models/        (AppSettings, Receipt)
├── Services/      (PrinterService, PrinterDiscovery, ReceiptBuilder)
└── Views/         (ContentView, Preview, Settings, Discovery)
```

---

## Calculs effectués (commun aux deux versions)

Pour chaque taux de TVA :
- `TVA = HT × taux`
- `TTC = HT + TVA`

Totaux :
- `Total HT = somme des HT`
- `Total TVA = somme des TVA`
- `Total TTC = Total HT + Total TVA`
