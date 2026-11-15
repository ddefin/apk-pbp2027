#!/bin/sh
# Affiche l'empreinte SHA-256 de la clé de signature et le contenu attendu de
# web/public/.well-known/assetlinks.json (dépôt pbp2027-planner).
# Usage : sh scripts/empreinte.sh   (lit le mot de passe dans keystore.env)
set -eu
cd "$(dirname "$0")/.."
. ./keystore.env
FP=$(keytool -list -v -keystore android.keystore -alias pbp2027 -storepass "$BUBBLEWRAP_KEYSTORE_PASSWORD" 2>/dev/null \
  | sed -n 's/^[[:space:]]*SHA256: //p')
echo "Empreinte SHA-256 : $FP"
cat <<JSON
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "fr.lameteoducyclo.pbp2027",
      "sha256_cert_fingerprints": [
        "$FP"
      ]
    }
  }
]
JSON
