#!/bin/sh
# Construit l'APK et l'AAB signés (app-release-signed.apk, app-release-bundle.aab).
# Prérequis : Bubblewrap (npm i -g @bubblewrap/cli), android.keystore et keystore.env
# à la racine du dépôt (voir README).
set -eu
cd "$(dirname "$0")/.."
set -a; . ./keystore.env; set +a
bubblewrap build --skipPwaValidation
