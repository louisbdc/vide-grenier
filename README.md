# Vide-Grenier — cartographie temps réel des vide-greniers

Application iOS (SwiftUI / iOS 26) + backend Node·MongoDB, fondée sur une étude
de marché. Promesse : **zéro pub**, **aucune connexion au premier lancement**,
carte fluide type navigation, et signalements collaboratifs en temps réel.

## Fonctionnalités

- 🗺️ Carte plein écran (MapKit) centrée sur l'utilisateur, **Liquid Glass** (iOS 26)
- 📍 Recherche par **rayon kilométrique** + « rechercher dans cette zone »
- 🧲 **Clustering** lisible en zone dense
- 🔴 **Signalements terrain** temps réel (annulé / foule / désert / vidé)
- 🏷️ **Tags d'inventaire** communautaires (puériculture, vintage, livres…)
- 📷 **Photos floutées on-device** (Vision) — visages & plaques anonymisés avant envoi (RGPD)
- 🧭 **Mon parcours de chine** : sélection multi-événements + itinéraire optimisé
- ➕ Création d'événement crowdsourcée
- 👀 Aperçu Look Around + distance + bouton Itinéraire

## Architecture

```
App/ + Sources/        App iOS SwiftUI (XcodeGen → project.yml)
Server/                API temps réel : Fastify + MongoDB + WebSocket
  src/                 routes, auth JWT anonyme, import DATAtourisme, agrégation
  docker-compose.yml   Mongo (replica set) + API + Caddy (HTTPS auto)
  DEPLOY.md            guide de déploiement VPS
```

- **Géo** : MongoDB 2dsphere (`$nearSphere` par rayon)
- **Temps réel** : MongoDB Change Streams → WebSocket
- **Données** : import open data **DATAtourisme** (anti-scraping) + crowdsourcing
- **Auth** : anonyme (deviceId → JWT), aucune identité collectée

## Lancer en local

### Backend
```bash
# MongoDB en replica set (requis pour les Change Streams) — ex. via Docker :
docker run -d -p 27017:27017 mongo:7 --replSet rs0
mongosh --eval "rs.initiate()"

cd Server
cp .env.example .env   # renseigner JWT_SECRET et DATATOURISME_API_KEY
npm install && npm run build
node --env-file=.env dist/scripts/runImport.js   # amorçage des événements
node --env-file=.env dist/server.js              # API sur :8080
```

### App iOS
```bash
brew install xcodegen
xcodegen generate
open VideGrenier.xcodeproj   # cible iOS 26, simulateur iPhone 17 Pro
```
Par défaut, l'app vise la **production** (`https://vps-03f913ed.vps.ovh.net`).
Pour viser un backend **local** en dev, définis la variable d'environnement du
schéma Xcode : `API_BASE_URL=http://127.0.0.1:8080`.

## Déploiement

Voir [`Server/DEPLOY.md`](Server/DEPLOY.md) : `docker compose up -d` lance Mongo +
API + Caddy (HTTPS Let's Encrypt automatique). CI/CD via GitHub Actions
(`.github/workflows/deploy.yml`) : chaque push sur `main` déploie sur le VPS.

## Conformité (issue de l'étude)

- **Anti-scraping** : source légale = DATAtourisme (licence ouverte), pas d'aspiration des concurrents
- **RGPD** : floutage local irréversible, données hébergées en France (VPS), auth anonyme
