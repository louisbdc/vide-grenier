# 🚀 Mise en ligne de Vide-Grenier sur l'App Store — guide pas à pas

Guide complet et ordonné. Suis les parties **dans l'ordre**. Tout ce qui est
spécifique à ton app est déjà rempli (Bundle ID, équipe, URLs).

**Infos clés de ton projet :**
- Bundle ID : `com.vide-grenier.app`
- Équipe de signature : **FAITES PART EN LIGNE** (`ZDJ57KYYH2`)
- Backend (déjà en ligne) : `https://vps-03f913ed.vps.ovh.net`
- Confidentialité : `https://vps-03f913ed.vps.ovh.net/privacy`
- CGU : `https://vps-03f913ed.vps.ovh.net/terms`
- Compte App Store Connect : Louis de Caumont

> ✅ **Déjà fait pour toi** : backend déployé (API + base + paiement Stripe),
> modération UGC (signaler/bloquer), pages légales, CI/CD. Il te reste la
> partie « compte Apple + soumission » décrite ici.

---

## ⚠️ Avant de commencer : 2 actions à faire une seule fois

1. **Adhésion Apple Developer Program** active (99 €/an). Si tu vois App Store
   Connect, c'est bon. Sinon : <https://developer.apple.com/programs/enroll/>
2. **E-mail de support** : les pages légales utilisent un e-mail provisoire
   (`contact@vide-grenier.app`). Donne-moi ton vrai e-mail public → je le
   remplace et redéploie. Apple exige un contact valide.

---

## Partie 1 — Enregistrer le Bundle ID

C'est l'étape qui te bloquait : sans ça, ton app n'apparaît pas dans App Store Connect.

1. Va sur <https://developer.apple.com/account/resources/identifiers/list>
2. Clique le bouton **＋** (à côté de « Identifiers »)
3. Sélectionne **App IDs** → **Continue**
4. Type : **App** → **Continue**
5. Remplis :
   - **Description** : `Vide-Grenier`
   - **Bundle ID** : choisis **Explicit**, puis tape exactement `com.vide-grenier.app`
6. **Capabilities** : ne coche **RIEN** (pas de Push, pas de Sign in with Apple,
   pas d'In-App Purchase — le paiement passe par Stripe en web).
7. Clique **Continue** → **Register**

✅ Le Bundle ID est créé.

---

## Partie 2 — Déclarer ton statut professionnel (UE / DSA)

Obligatoire, sinon l'app ne peut pas être distribuée en Europe.

1. Va sur <https://appstoreconnect.apple.com>
2. Menu **Business** (barre du haut)
3. Section **Trader Status** → renseigne les informations de la société
   **FAITES PART EN LIGNE** (raison sociale, adresse, e-mail, téléphone).
4. Enregistre. (La vérification peut prendre quelques heures.)

---

## Partie 3 — Créer l'app dans App Store Connect

1. <https://appstoreconnect.apple.com> → onglet **Apps** → bouton **＋** → **New App**
2. Remplis :
   - **Platforms** : ☑️ **iOS**
   - **Name** : `Vide-Grenier · Chine en direct` *(doit être unique sur l'App
     Store ; « Vide-Grenier » seul sera sûrement refusé. Max 30 caractères.)*
   - **Primary Language** : **French (France)**
   - **Bundle ID** : sélectionne `com.vide-grenier.app` *(visible grâce à la Partie 1)*
   - **SKU** : `videgrenier-ios-001` *(identifiant interne libre)*
   - **User Access** : **Full Access**
3. Clique **Create**.

---

## Partie 4 — Stratégie Stripe pour la revue (IMPORTANT)

Le problème : en mode **Live**, le testeur Apple paierait 5 € réels. La solution :

1. **Pendant la revue** : garde Stripe en **mode TEST** (déjà le cas
   actuellement). Le testeur utilisera la carte `4242 4242 4242 4242` sans débit
   réel. Tu indiqueras cette carte dans les notes de revue (Partie 9).
2. **Après l'approbation, AVANT de publier** : passe en Live (voir Partie 11).

> Le binaire de l'app ne change pas entre test et live (seule la clé serveur
> change) — pas besoin de re-soumettre.

---

## Partie 5 — Préparer et envoyer le build depuis Xcode

### 5.1 Générer le projet
```bash
cd /Users/louisdecaumont/code/projets_perso/vide_grenier
brew install xcodegen   # si pas déjà installé
xcodegen generate
open VideGrenier.xcodeproj
```

### 5.2 Régler la signature
1. Dans Xcode, sélectionne le projet **VideGrenier** (panneau de gauche) → target **VideGrenier**
2. Onglet **Signing & Capabilities**
3. ☑️ **Automatically manage signing**
4. **Team** : **FAITES PART EN LIGNE**
5. Vérifie que **Bundle Identifier** = `com.vide-grenier.app`

### 5.3 Régler la version
- Onglet **General** → **Version** : `1.0`, **Build** : `1`

### 5.4 Archiver
1. En haut, choisis la cible **Any iOS Device (arm64)** *(surtout pas un simulateur)*
2. Menu **Product → Archive**
3. Attends la fin (quelques minutes). La fenêtre **Organizer** s'ouvre.

### 5.5 Envoyer
1. Dans **Organizer**, sélectionne l'archive → **Distribute App**
2. **App Store Connect** → **Upload** → suis les écrans (laisse les options par défaut)
3. Clique **Upload**.

Le build apparaît dans App Store Connect sous **TestFlight / Build** après ~5–15 min
de traitement.

---

## Partie 6 — Remplir la fiche App Store

App Store Connect → ton app → **App Store** (onglet) → version **1.0**.

### Textes (prêts à coller)
- **Sous-titre** : `Vide-greniers en temps réel`
- **Texte promotionnel** :
  `Tous les vide-greniers et brocantes de France sur une carte. Sans pub. Signalements en direct, photos, et itinéraire de chine optimisé.`
- **Description** :
```
Chine sans friction. Vide-Grenier réunit tous les vide-greniers, brocantes et
marchés aux puces de France sur une carte fluide et lisible — sans aucune pub.

• Carte en temps réel autour de toi, recherche par rayon
• Signalements de la communauté : annulé, foule, stands vidés
• Tags d'inventaire : puériculture, vintage, livres, outils…
• Mon parcours : sélectionne plusieurs événements, itinéraire optimisé
• Photos des allées (visages et plaques floutés sur ton téléphone)
• Données officielles open data + contributions des chineurs

Gratuit pour les chineurs. Publier ta propre annonce : 5 €.
```
- **Mots-clés** :
  `vide-grenier,brocante,chine,puces,marché,seconde main,occasion,déballage,antiquité,troc`

### URLs
- **Privacy Policy URL** : `https://vps-03f913ed.vps.ovh.net/privacy`
- **Support URL** : `https://vps-03f913ed.vps.ovh.net/terms`

### Captures d'écran (obligatoire : iPhone 6.9")
Il faut au moins **1 capture en 6.9"** (iPhone 16/17 Pro Max). Pour en générer :
1. Dans Xcode, lance l'app sur le simulateur **iPhone 17 Pro Max**
2. Navigue sur les écrans (carte, fiche détail, parcours, onboarding)
3. `Cmd + S` dans le simulateur enregistre la capture sur le Bureau
4. Glisse-les dans App Store Connect (section Screenshots).

### Icône
Déjà incluse dans le build (icône terracotta à l'étiquette). Rien à faire.

---

## Partie 7 — Confidentialité de l'app (questionnaire App Privacy)

App Store Connect → ton app → **App Privacy** → **Get Started**. Réponds :

| Donnée | Collectée ? | Détails |
|---|---|---|
| **Localisation (approx./précise)** | Oui | Usage : *Fonctionnalité de l'app*. **Non liée à l'identité**. **Pas** pour le suivi. |
| **Photos / contenus utilisateur** | Oui | Usage : *Fonctionnalité de l'app*. Liée à l'utilisateur (compte anonyme). Pas pour le suivi. |
| **Identifiants** | Oui | Identifiant d'appareil anonyme. Fonctionnalité. Pas de suivi. |
| **Achats** | Oui | Via Stripe (publication d'annonce). Fonctionnalité. |
| **Suivi (tracking)** | **Non** | Aucun traceur publicitaire. |

---

## Partie 8 — Classification par âge

App Store Connect → ton app → **Age Rating** → **Edit**.
- Réponds **None/Aucun** à tout (violence, etc.) → classement **4+**.
- ⚠️ Une question porte sur le **contenu généré par les utilisateurs** : réponds
  **Oui**. C'est attendu — l'app dispose des mécanismes requis (signalement,
  blocage, CGU « tolérance zéro »), conformes à la règle App Store 1.2.

---

## Partie 9 — Informations pour la revue (App Review Information)

App Store Connect → version 1.0 → section **App Review Information**.

- **Coordonnées** : ton nom, téléphone, e-mail.
- **Notes** (copie-colle) :
```
Application gratuite de cartographie des vide-greniers (événements physiques
réels). 

PAIEMENT : publier une annonce coûte 5 €, traité par Stripe (Checkout web). Il
s'agit de frais de publication pour un événement/service DU MONDE RÉEL (vide-
grenier physique), comparable à une petite annonce — pas de contenu numérique ni
de déblocage in-app. Conforme aux directives 3.1.3(e) / 3.1.5(a).
Pour tester le paiement : carte 4242 4242 4242 4242, date future, CVC 123
(Stripe est en mode test pendant la revue).

CONTENU UTILISATEUR : photos et tags. Modération en place — bouton « Signaler »
sur chaque photo (masquage automatique au seuil) et « Bloquer cet utilisateur ».
CGU « tolérance zéro » : https://vps-03f913ed.vps.ovh.net/terms

LOCALISATION : utilisée pour centrer la carte et chercher les événements proches.
```
- **Compte de démonstration** : non requis (connexion anonyme automatique).

---

## Partie 10 — Tarification et disponibilité

- Onglet **Pricing and Availability** → **Price** : **Gratuit (0 €)**.
- **Disponibilité** : tous pays, ou limite à la France si tu préfères démarrer là.

---

## Partie 11 — Soumettre, puis passer Stripe en Live

1. Vérifie que tous les blocs ont une coche verte (build sélectionné, captures,
   confidentialité, âge, prix).
2. Bouton **Add for Review** → **Submit for Review**.
3. Choisis **« Release manually »** (publication manuelle) pour contrôler le moment.
4. Attends la revue (24–48 h en général).

### Dès que l'app est « Approved » (mais AVANT de cliquer « Release ») :
Passe Stripe en **Live** pour que les vrais paiements fonctionnent :
1. Dashboard Stripe → bascule en **mode Live** → **Développeurs → Clés API**
2. Crée une **clé restreinte** `rk_live_…` (scope **Checkout Sessions : Write**)
3. Dans ton terminal :
```bash
cd /Users/louisdecaumont/code/projets_perso/vide_grenier
nano /tmp/stripe.txt   # colle la rk_live_… puis Ctrl+O, Entrée, Ctrl+X
gh secret set STRIPE_SECRET_KEY -R louisbdc/vide-grenier < /tmp/stripe.txt
rm /tmp/stripe.txt
gh workflow run deploy.yml -R louisbdc/vide-grenier
```
4. Reviens sur App Store Connect → **Release** pour publier l'app. 🎉

---

## Récapitulatif des écueils déjà couverts

| Risque de rejet | Statut |
|---|---|
| Pas de politique de confidentialité | ✅ en ligne (`/privacy`) |
| UGC sans signalement/blocage (règle 1.2) | ✅ implémenté (app + serveur) |
| Paiement externe non justifié | ✅ note de revue fournie (Partie 9) |
| Localisation non justifiée | ✅ description d'usage dans l'app |
| HTTPS requis | ✅ backend en HTTPS |
| Statut trader UE | ⚠️ à faire (Partie 2) |
| E-mail de support réel | ⚠️ à me communiquer |

---

## Besoin d'aide ?
- Régénérer des captures d'écran propres : demande-moi.
- Changer l'e-mail de contact des pages légales : donne-le moi.
- Passer Stripe en Live : suis la Partie 11 (ou demande-moi).
