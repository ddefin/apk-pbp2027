# PBP2027 Planner — appli Android

Appli Android de <https://pbp2027.lameteoducyclo.fr>, sous forme de **Trusted Web
Activity** (TWA) générée avec [Bubblewrap](https://github.com/GoogleChromeLabs/bubblewrap).

L'appli ne contient pas de code métier. Elle ouvre le site dans Chrome, en plein
écran et sans barre d'adresse. Le site, la connexion, le service worker et le mode
hors ligne restent ceux de la PWA (dépôt `ddefin/pbp2027-planner`). Une mise à jour
du site s'applique donc à l'appli sans republier l'APK.

| Élément | Valeur |
|---|---|
| Identifiant | `fr.lameteoducyclo.pbp2027` |
| Origine | `https://pbp2027.lameteoducyclo.fr/` (même adresse que le site) |
| Android minimum | 7.0 (API 24, imposé par `androidbrowserhelper` 2.7) |
| Cible | API 36 |
| Permissions | localisation précise/approximative, **au premier plan uniquement** |
| Notifications | désactivées (le site n'utilise pas Web Push) |

## Choix faits

- **Connexion inchangée.** Le cookie de session `SameSite=Strict` fonctionne tel quel.
  L'appli charge exactement la même origine que le site, dans le même profil Chrome.
  Une personne déjà connectée dans Chrome l'est aussi dans l'appli.
- **Pas de suivi GPS continu.** La « délégation de localisation » (`features.locationDelegation`)
  sert seulement à afficher la demande d'accès au nom de l'appli. La position n'est
  lue qu'au moment d'un pointage volontaire (`getCurrentPosition`, bouton
  « Pointer ma position »). Il n'y a ni service en arrière-plan, ni
  `ACCESS_BACKGROUND_LOCATION`, ni `watchPosition`.
- **Strava.** Le bouton « Connecter Strava » quitte le site vers `strava.com`. Chrome
  l'affiche avec une barre d'adresse, comme tout site extérieur. Le retour
  `/api/strava/callback` revient sur le site, et la barre disparaît. Le compte est
  retrouvé grâce au `state` signé, sans cookie, comme dans le navigateur.
- **Repli** (`fallbackType: customtabs`). Sans Chrome compatible TWA, l'appli s'ouvre
  dans un onglet personnalisé, avec une barre d'adresse.

## Clé de signature

La clé `android.keystore` (alias `pbp2027`) et son mot de passe `keystore.env` ne sont
**pas** dans git. Il faut les sauvegarder à part, par exemple dans un gestionnaire de
mots de passe ou dans Hyper Backup sur la NAS. **Sans cette clé, impossible de publier
une mise à jour de l'appli** : il faudrait désinstaller l'appli et en installer une
nouvelle.

Empreinte SHA-256 actuelle, déclarée dans
`pbp2027-planner/web/public/.well-known/assetlinks.json` :

```
5B:75:1C:52:0F:B3:DC:5B:3E:E1:AF:75:B6:ED:EB:09:5C:F0:3D:18:9D:C3:09:FB:75:48:17:04:A1:F3:CA:D3
```

`sh scripts/empreinte.sh` réaffiche cette empreinte et le JSON attendu.

**Publication sur le Play Store.** Avec la signature d'applications Play, Google
re-signe l'appli avec sa propre clé. Il faut alors **ajouter** l'empreinte « Clé de
signature de l'application » (Play Console → Intégrité de l'application) dans
`sha256_cert_fingerprints`, à côté de celle-ci. L'APK installé à la main reste ainsi
reconnu.

## Construire

Prérequis : Node 18+, puis `npm i -g @bubblewrap/cli`. Au premier lancement,
Bubblewrap propose d'installer le JDK 17 et le SDK Android. Placer `android.keystore`
et `keystore.env` à la racine du dépôt, puis lancer :

```bash
sh scripts/build.sh
```

Résultat : `app-release-signed.apk` pour installer directement,
`app-release-bundle.aab` pour le Play Store.

Pour une nouvelle version, augmenter `appVersionCode` et `appVersion` dans
`twa-manifest.json`, lancer `bubblewrap update`, puis reconstruire. Après une
modification du manifeste du site (`web/vite.config.ts` : couleurs, nom, icônes),
lancer `bubblewrap update` aussi.

## Mettre en ligne côté site (une fois)

Le fichier `assetlinks.json` doit être servi par le site **avant** de tester l'appli.
Sinon, Android affiche une barre d'adresse.

1. Fusionner dans `main` la branche du dépôt `pbp2027-planner` qui ajoute
   `web/public/.well-known/assetlinks.json`.
2. Sur la NAS : `sudo sh scripts/auto-deploy.sh`. La tâche planifiée le fait aussi,
   toutes les 5 min.
3. Vérifier :
   ```bash
   curl -sI https://pbp2027.lameteoducyclo.fr/.well-known/assetlinks.json
   ```
   La réponse doit être `200` avec `content-type: application/json`, et non du HTML.
   Vérification côté Google :
   <https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://pbp2027.lameteoducyclo.fr&relation=delegate_permission/common.handle_all_urls>

## Installer sur un téléphone

Activer « Sources inconnues » pour le navigateur ou le gestionnaire de fichiers, puis
ouvrir `app-release-signed.apk`. Sinon, depuis un ordinateur :

```bash
adb install -r app-release-signed.apk
```

Diagnostic si la barre d'adresse reste affichée :

```bash
adb shell pm verify-app-links --re-verify fr.lameteoducyclo.pbp2027
```

```bash
adb shell pm get-app-links fr.lameteoducyclo.pbp2027
```

Le domaine doit apparaître comme `verified`. Chrome peut garder l'ancien résultat en
cache : désinstaller puis réinstaller l'appli.

## Vérifications sur téléphone

À cocher sur un vrai téléphone Android, avec Chrome à jour.

- [ ] **Ouverture sans barre d'adresse.** L'icône « PBP2027 » ouvre l'écran de
      démarrage bleu nuit, puis le site en plein écran, sans URL en haut.
- [ ] **Connexion.** Se connecter avec email et mot de passe, fermer l'appli
      (balayer), la rouvrir : la session est toujours ouverte. La déconnexion
      fonctionne.
- [ ] **Pointage hors réseau.** Ouvrir une fois son roadbook avec du réseau. Passer en
      mode avion, rouvrir l'appli : le roadbook s'affiche. « Pointer ma position »
      affiche la demande de localisation de l'appli (accepter « Pendant l'utilisation
      de l'appli »), puis le message « pas de réseau : pointage gardé dans le
      téléphone ». Couper le mode avion : le pointage part tout seul et apparaît sur
      la page de suivi. Tester aussi « Je suis à ce km » et « Pointé ✔ ».
- [ ] **Pas de GPS en continu.** Dans Paramètres → Localisation, l'appli n'apparaît
      pas comme utilisant la position en arrière-plan. L'icône GPS ne s'allume que
      pendant un pointage.
- [ ] **Connexion Strava.** Profil → onglet Strava → « Connecter » : la page Strava
      s'ouvre avec une barre d'adresse. Autoriser : retour dans l'appli sur
      `/profil#strava`, sans barre d'adresse, avec Strava connecté et la session
      toujours ouverte. Si l'appli Strava est installée, elle peut prendre la main
      pour l'autorisation : le retour doit fonctionner de la même façon.
- [ ] **Lien de suivi des proches.** Dans le roadbook, partager le lien de suivi
      (`/r/…`). La feuille de partage Android s'ouvre. Ouvrir le lien sur un autre
      téléphone, sans compte : la page de suivi s'affiche, avec les pointages.
      Sur le téléphone qui a l'appli, toucher le lien depuis WhatsApp ou SMS l'ouvre
      directement dans l'appli.
- [ ] **TalkBack.** Activer TalkBack (Paramètres → Accessibilité). Parcourir la
      connexion, le menu, la cloche de notifications et le bouton « Pointer ma
      position » : chaque élément est annoncé, et le message de résultat du pointage
      est lu automatiquement (zone `role="status"`). L'écran de démarrage ne bloque
      pas la navigation.
- [ ] **Liens externes** (Garmin LiveTrack, WhatsApp, activités Strava) : ils s'ouvrent
      dans l'appli concernée ou dans un onglet Chrome, et le bouton Retour ramène dans
      l'appli.
