# Déploiement du backend Vide-Grenier sur un VPS (OVH)

Guide complet pour mettre le backend `Server/` en production proprement, avec
MongoDB (replica set), HTTPS, sauvegardes et sécurité. À faire le moment venu.

---

## 0. Prérequis

- VPS OVH **`vps-03f913ed.vps.ovh.net`** (IP `152.228.136.49`), Ubuntu 26.04,
  2 vCPU / 4 Go / 40 Go — Strasbourg 🇫🇷
- **Aucun domaine à acheter** : on utilise le **hostname OVH gratuit**
  `vps-03f913ed.vps.ovh.net` (déjà résolu vers l'IP). Caddy en tire un
  certificat Let's Encrypt gratuit → HTTPS sans rien payer.
- Accès SSH root/sudo

---

## 1. Préparer le serveur

```bash
ssh ubuntu@<IP_DU_VPS>

# Docker + Compose
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER && newgrp docker

# Pare-feu : n'ouvrir que SSH + HTTP + HTTPS (surtout PAS le port Mongo)
sudo ufw allow OpenSSH
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable
```

---

## 2. Déposer le code

```bash
# Option A : git
git clone <ton-repo> vide-grenier && cd vide-grenier/Server

# Option B : copie directe depuis ton Mac
#   rsync -av --exclude node_modules --exclude dist ./Server/ ubuntu@<IP>:~/vide-grenier/Server/
```

---

## 3. Configurer les secrets (`.env`)

```bash
cp .env.example .env
nano .env
```

Renseigner :

```ini
PORT=8080
MONGO_URL=mongodb://mongo:27017/videgrenier?replicaSet=rs0
JWT_SECRET=<colle ici 64 caractères aléatoires>      # openssl rand -hex 32
DATATOURISME_API_KEY=ta-cle-api-datatourisme
PHOTOS_DIR=/data/photos
CORS_ORIGIN=*
```

Générer un secret solide : `openssl rand -hex 32`.

> ⚠️ Ne **jamais** committer `.env`. Il est déjà dans `.gitignore`.

---

## 4. Lancer (MongoDB + API)

```bash
docker compose up -d --build
docker compose logs -f api        # vérifier "Server listening on ... 8080"
```

Le `docker-compose.yml` :
- démarre MongoDB en **replica set mono-nœud** (auto-initié par le healthcheck)
  — indispensable pour les **Change Streams** (temps réel)
- construit et lance l'API, redémarrage automatique (`restart: unless-stopped`)
- persiste les données dans les volumes `mongo_data` et `photos_data`

---

## 5. Premier import des événements (amorçage)

L'import tourne tous les jours à 4 h, mais pour amorcer immédiatement :

```bash
docker compose exec api node dist/scripts/runImport.js
# → Import terminé: {"fetched":14750,"upserted":12917}
```

---

## 6. HTTPS — déjà configuré (rien à acheter)

Le `Caddyfile` et le service `caddy` du `docker-compose.yml` sont **déjà prêts**
avec le hostname OVH `vps-03f913ed.vps.ovh.net`. Au premier `docker compose up`,
Caddy obtient automatiquement un certificat Let's Encrypt (il faut juste que les
ports 80/443 soient ouverts, cf. étape 1) et le renouvelle tout seul.

L'API n'est **pas** exposée publiquement (`expose` et non `ports`) : seul Caddy
y accède en interne, puis sert le tout en HTTPS.

> Si un jour tu prends un vrai domaine, remplace simplement la ligne du
> `Caddyfile` par `ton-domaine.fr { reverse_proxy api:8080 }`.

---

## 7. Pointer l'app iOS vers la prod

Dans Xcode (réglage de build / variable d'environnement du schéma) :

```
API_BASE_URL = https://vps-03f913ed.vps.ovh.net
```

(L'app vise la production par défaut ; ne définis `API_BASE_URL` que pour pointer
un backend local en dev, ex. `http://127.0.0.1:8080`.)
L'URL étant en HTTPS, l'exception `NSAllowsLocalNetworking` de l'Info.plist ne
sert qu'au dev local — ne pas relâcher davantage l'ATS en production.

---

## 8. Sauvegardes (à mettre en place)

```bash
# Dump quotidien de Mongo (cron)
echo '0 3 * * * docker compose -f ~/vide-grenier/Server/docker-compose.yml exec -T mongo \
  mongodump --archive=/data/db/backup-$(date +\%F).gz --gzip' | crontab -
```

Sauvegarder aussi le volume `photos_data` (rsync vers un stockage externe / OVH
Object Storage).

---

## 9. Sécurité — checklist

- [ ] Port MongoDB (27017) **non** exposé publiquement (vérifié par `ufw`)
- [ ] `JWT_SECRET` long et aléatoire (jamais la valeur d'exemple)
- [ ] HTTPS actif (Caddy) ; pas de HTTP en clair en prod
- [ ] `.env` hors du dépôt git
- [ ] Mises à jour : `docker compose pull && docker compose up -d`
- [ ] (Optionnel) limiter `CORS_ORIGIN` si une interface web est ajoutée
- [ ] (Optionnel) rate-limiting devant l'API (plugin Fastify ou Caddy)

---

## 10. Exploitation courante

```bash
docker compose ps                 # état des conteneurs
docker compose logs -f api        # logs API
docker compose restart api        # redémarrer l'API
docker compose exec api node dist/scripts/runImport.js   # réimport manuel
```
