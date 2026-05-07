# Business Mindset Widget iOS - Guide d'intégration

## 📱 Présentation

Widget iOS natif (WidgetKit) pour afficher les citations de Business Mindset directement sur l'écran d'accueil.

### Fonctionnalités

- ✅ **Affichage initial** : Icône d'engrenage + texte "Tap to configure your widget"
- ✅ **Mode configuré** : Citation avec fond thématique + icônes (share, favori)
- ✅ **70 thèmes** : Couleurs et images copiées depuis `themedatas.dart`
- ✅ **Background crop centré** : Comme `home_page.dart`, l'image est tronquée au centre
- ✅ **Autonome** : Fonctionne sur simulateur sans données Flutter
- ✅ **Prêt pour App Group** : Commentaires pour activation future

---

## 📂 Structure des fichiers

```
ios/BusinessMindsetWidget/
├── BusinessMindsetWidget.swift      # Widget principal
├── ThemeData.swift                  # 70 thèmes (copie de themedatas.dart)
├── Info.plist                       # Configuration du widget
└── README_WIDGET.md                 # Ce fichier
```

---

## 🚀 Étapes d'intégration dans Xcode

### 1. Créer le Widget Extension

1. Ouvrir `ios/Runner.xcworkspace` dans Xcode
2. File > New > Target
3. Choisir **Widget Extension**
4. Nom : `BusinessMindsetWidget`
5. Bundle ID : `com.votreapp.businessmindset.BusinessMindsetWidget`
6. Cocher **Include Configuration Intent** : NON
7. Cliquer sur **Finish**

### 2. Remplacer les fichiers générés

1. Supprimer le fichier `BusinessMindsetWidget.swift` généré automatiquement
2. Copier les fichiers depuis `ios/BusinessMindsetWidget/` :
   - `BusinessMindsetWidget.swift`
   - `ThemeData.swift`
   - `Info.plist`

### 3. Ajouter les assets (images et polices)

#### **Images de fond** (45 backgrounds)

1. Dans Xcode, aller dans le dossier `BusinessMindsetWidget` target
2. Cliquer droit > Add Files to "BusinessMindsetWidget"
3. Sélectionner toutes les images PNG/JPG de `assets/images/backgrounds/`
4. ⚠️ **Cocher** : "Copy items if needed"
5. ⚠️ **Cocher** : Target Membership = `BusinessMindsetWidget`

Les images nécessaires (45 fichiers) :
- 1_skyline.png à 45_aurore.png (voir `assets/images/backgrounds/`)

#### **Polices** (toutes les polices custom)

Pour chaque police dans `assets/fonts/` :

1. Cliquer droit sur `BusinessMindsetWidget` > Add Files
2. Sélectionner les fichiers `.ttf`
3. ⚠️ **Cocher** : "Copy items if needed"
4. ⚠️ **Cocher** : Target Membership = `BusinessMindsetWidget`

Polices nécessaires (23 familles) :
- InterTight, YesevaOne, DidactGothic, JosefinSlab, Raleway
- AbhayaLibre, Allerta, BebasNeue, BodoniModa, CormorantGaramond
- EBGaramond, JosefinSans, Lato, LibreBaskerville, Lustria
- MontSerrat (Montserrat), Oranlenbaum, Oswald, Ovo
- PlayfairDisplay, Quicksand, Sanchez, SourceSansPro, Volkhov

### 4. Configurer Info.plist du Widget

Ajouter les polices dans `Info.plist` du **Widget** (pas de l'app principale) :

```xml
<key>UIAppFonts</key>
<array>
    <string>InterTight.ttf</string>
    <string>YesevaOne.ttf</string>
    <string>DidactGothic-Regular.ttf</string>
    <string>JosefinSlab-Regular.ttf</string>
    <string>Raleway-Regular.ttf</string>
    <!-- Ajouter toutes les autres polices -->
</array>
```

### 5. Configurer les Capabilities (Optionnel - pour App Group)

Pour partager les données entre l'app Flutter et le widget :

1. Sélectionner le target `Runner` (app principale)
2. Signing & Capabilities > + Capability > **App Groups**
3. Ajouter : `group.com.votreapp.businessmindset`

4. Sélectionner le target `BusinessMindsetWidget`
5. Signing & Capabilities > + Capability > **App Groups**
6. Ajouter le même : `group.com.votreapp.businessmindset`

---

## 🔧 Configuration Flutter (WidgetPage)

### Créer la page de configuration du widget

Fichier : `lib/views/widget_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/user_provider.dart';

class WidgetPage extends ConsumerWidget {
  const WidgetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Ajouter un bouton pour marquer le widget comme configuré
    // et sauvegarder dans UserDefaults via platform channel
    
    return Scaffold(
      appBar: AppBar(title: const Text('Configuration Widget')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Widget Configuration'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Appeler un platform channel pour:
                // 1. Marquer widgetConfigured = true
                // 2. Sauvegarder le themeIndex actuel
                // 3. Rafraîchir le widget
              },
              child: const Text('Activer le widget'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Configurer le routing Flutter

Dans votre app Flutter, ajoutez la route pour ouvrir `WidgetPage` :

```dart
// Dans votre MaterialApp ou routing
if (uri.path == '/widget') {
  return MaterialPageRoute(builder: (_) => const WidgetPage());
}
```

---

## 🔗 Activation des fonctionnalités avancées

### 1. Deeplinks (commentés dans le code)

Pour activer les deeplinks, décommenter dans `BusinessMindsetWidget.swift` :

```swift
// Ligne ~110 : Ouvrir l'app sur WidgetPage
.widgetURL(URL(string: "businessmindset://widget")!)

// Ligne ~90 : Share
Link(destination: URL(string: "businessmindset://share")!) {
    Image(systemName: "square.and.arrow.up")
    ...
}

// Ligne ~100 : Favorite
Link(destination: URL(string: "businessmindset://favorite")!) {
    Image(systemName: "heart")
    ...
}
```

Puis configurer les URL schemes dans `Info.plist` de l'app principale :

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>businessmindset</string>
        </array>
    </dict>
</array>
```

### 2. App Group (données partagées)

Décommenter dans `BusinessMindsetWidget.swift` ligne ~45 :

```swift
// Remplacer
let themeIndex = UserDefaults.standard.integer(forKey: "widgetThemeIndex")
let isConfigured = UserDefaults.standard.bool(forKey: "widgetConfigured")

// Par
let sharedDefaults = UserDefaults(suiteName: "group.com.votreapp.businessmindset")
let themeIndex = sharedDefaults?.integer(forKey: "themeIndex") ?? 0
let isConfigured = sharedDefaults?.bool(forKey: "widgetConfigured") ?? false
let quote = sharedDefaults?.string(forKey: "currentQuote") ?? "Mock quote"
```

Côté Flutter, utiliser `shared_preferences` avec App Group :

```dart
// TODO: Implémenter un platform channel pour écrire dans App Group
```

### 3. Citations réelles (au lieu du mock)

Une fois App Group configuré, le widget lira automatiquement la citation depuis :

```swift
let savedQuote = sharedDefaults?.string(forKey: "currentQuote") ?? "Fallback quote"
```

Il suffit de sauvegarder depuis Flutter via platform channel.

---

## ✅ Test sur simulateur

1. Build l'app : `flutter build ios --simulator`
2. Ouvrir dans Xcode et lancer sur simulateur
3. Sur l'écran d'accueil iOS : long press > + > Business Mindset
4. Le widget devrait afficher l'icône d'engrenage
5. Taper sur le widget → ouvre l'app (une fois deeplinks activés)

---

## 📝 TODO / Améliorations futures

- [ ] Créer `widget_page.dart` avec UI de configuration
- [ ] Implémenter platform channel pour sauvegarder dans App Group
- [ ] Activer les deeplinks (share, favorite, widget config)
- [ ] Remplacer le mock quote par une vraie citation
- [ ] Ajouter un système de rafraîchissement périodique (toutes les heures par défaut)
- [ ] Gérer les thèmes custom (actuellement seulement les 70 thèmes app)

---

## 🐛 Dépannage

### Les images ne s'affichent pas
- Vérifier que les images sont bien dans `Assets.xcassets` du widget target
- Ou vérifier que `Target Membership` inclut `BusinessMindsetWidget`

### Les polices ne fonctionnent pas
- Vérifier `Info.plist` du widget (pas l'app)
- Vérifier que les `.ttf` ont `Target Membership` = `BusinessMindsetWidget`

### Le widget ne se rafraîchit pas
- Forcer le rafraîchissement : long press widget > Remove > Re-add
- Vérifier les logs Xcode : Console > Filter: BusinessMindsetWidget

---

## 📚 Ressources

- [Apple WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)
- [Flutter Platform Channels](https://docs.flutter.dev/development/platform-integration/platform-channels)
- [App Groups Guide](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups)

---

**Créé par Assistant pour Business Mindset**
Version : 1.0 - Novembre 2025

