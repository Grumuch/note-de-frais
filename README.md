# Note de frais — iPhone + Epson TM-m30III

Application iOS native (SwiftUI) qui imprime une **note de frais** sur une imprimante
**Epson TM-m30III** connectée en Wi-Fi.

Vous saisissez :
- le **nombre de repas** (ex. « 2 repas »)
- le **montant HT** pour chaque taux de TVA (5,5 % / 10 % / 20 %)

L'app calcule la TVA, les totaux HT et TTC, affiche un aperçu, puis imprime
un ticket avec le détail de la TVA (sans le détail des plats).

## Pré-requis

- Un Mac avec **Xcode 15** ou plus récent
- Un iPhone (iOS 16+)
- Une imprimante **Epson TM-m30III** sur le même réseau Wi-Fi que l'iPhone
- Le **SDK ePOS d'Epson pour iOS** (gratuit, à télécharger sur le site Epson)
- (Optionnel) `xcodegen` pour générer le projet Xcode : `brew install xcodegen`

## Étapes de mise en route

### 1. Cloner le projet sur votre Mac

```bash
git clone <url-du-repo>
cd note-de-frais
```

### 2. Télécharger le SDK Epson

1. Allez sur <https://www.epson-biz.com/modules/pos/index.php?page=single_soft&cid=6993&scat=58>
   (ou cherchez « Epson ePOS SDK for iOS » sur le site support Epson).
2. Téléchargez le ZIP, dézippez-le.
3. Copiez le dossier `libepos2.xcframework` dans :
   ```
   note-de-frais/Vendor/EpsonSDK/libepos2.xcframework
   ```

### 3. Générer le projet Xcode

```bash
xcodegen generate
open NoteDeFrais.xcodeproj
```

Si vous ne voulez pas utiliser XcodeGen, vous pouvez :
1. Créer un nouveau projet Xcode iOS (App, SwiftUI, Swift, iOS 16+).
2. Glisser le dossier `NoteDeFrais/` dans le projet.
3. Glisser `libepos2.xcframework` dans la section « Frameworks, Libraries » du target
   (« Embed & Sign »).
4. Recopier les clés `NSLocalNetworkUsageDescription` et `NSBonjourServices` du
   fichier `project.yml` dans votre `Info.plist`.

### 4. Configurer la signature

Dans Xcode :
1. Sélectionnez le projet `NoteDeFrais` → onglet **Signing & Capabilities**.
2. Cochez **Automatically manage signing**.
3. Choisissez votre **Team** (Apple ID gratuit ou compte développeur).
4. Modifiez le **Bundle Identifier** pour qu'il soit unique
   (ex. `com.votrenom.notedefrais`).

### 5. Installer sur l'iPhone

1. Connectez votre iPhone au Mac.
2. Dans Xcode, choisissez votre iPhone dans la barre supérieure.
3. **Cmd+R** pour compiler et installer.
4. Sur l'iPhone : **Réglages → Général → VPN et gestion d'appareils →**
   approuvez votre profil développeur.

> Avec un Apple ID gratuit, l'app fonctionne 7 jours puis il faut la
> réinstaller. Pour la garder installée durablement, il faut un compte
> Apple Developer Program (99 $/an).

## Utilisation

1. **Premier lancement** : l'app ouvre l'écran « Réglages »
   - Saisissez nom, adresse, téléphone, SIRET, numéro de TVA du restaurant
   - Touchez « Rechercher sur le Wi-Fi » pour détecter l'imprimante,
     ou « Saisir l'IP manuellement »
2. **Écran principal** :
   - Choisissez la date et le nombre de repas
   - Saisissez les montants HT par taux de TVA (laissez à 0 les taux inutilisés)
   - Touchez **Aperçu & imprimer**
3. **Aperçu** : vérifiez le rendu, puis touchez **Imprimer**.

## Trouver l'IP de l'imprimante

Sur la TM-m30III, appuyez sur le bouton **FEED** en mettant l'imprimante
sous tension : elle imprime un ticket de configuration avec l'IP attribuée
par votre routeur.

## Calculs effectués

Pour chaque taux de TVA :
- `TVA = HT × taux`
- `TTC = HT + TVA`

Totaux :
- `Total HT = somme des HT`
- `Total TVA = somme des TVA`
- `Total TTC = Total HT + Total TVA`

## Structure du projet

```
NoteDeFrais/
├── NoteDeFraisApp.swift
├── Models/
│   ├── AppSettings.swift     (persistance UserDefaults)
│   └── Receipt.swift         (modèle de ticket + formatters)
├── Services/
│   ├── PrinterService.swift  (envoi à l'imprimante)
│   ├── PrinterDiscovery.swift (découverte Bonjour)
│   └── ReceiptBuilder.swift  (commandes ePOS)
└── Views/
    ├── ContentView.swift     (écran principal)
    ├── ReceiptViewModel.swift
    ├── ReceiptPreviewView.swift
    ├── SettingsView.swift
    └── DiscoveryView.swift
```

## Dépannage

- **« SDK Epson non installé »** : le dossier `Vendor/EpsonSDK/libepos2.xcframework`
  est manquant ou pas correctement ajouté au target Xcode.
- **« Connexion impossible »** : vérifiez que l'iPhone et l'imprimante
  sont sur le même Wi-Fi, et que l'IP saisie est correcte.
- **Découverte qui ne trouve rien** : iOS demande l'autorisation
  « Réseau local » au premier lancement. Si vous avez refusé, allez dans
  **Réglages iOS → Note de frais → Réseau local** pour réactiver.
