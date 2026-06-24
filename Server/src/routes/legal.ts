import type { FastifyInstance } from "fastify";

const CONTACT = "contact@vide-grenier.app"; // ← remplace par ton e-mail de support réel

function page(title: string, body: string): string {
  return `<!doctype html><html lang="fr"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>${title}</title>
<style>body{font-family:-apple-system,system-ui,sans-serif;max-width:720px;margin:40px auto;
padding:0 20px;color:#2a221e;line-height:1.6}h1{color:#c9543d}h2{margin-top:28px}
small{color:#888}</style></head><body>${body}
<hr><small>Vide-Grenier — édité par Louis de Caumont. Contact : ${CONTACT}</small>
</body></html>`;
}

export default async function legalRoutes(fastify: FastifyInstance): Promise<void> {
  fastify.get("/privacy", async (_req, reply) => {
    reply.type("text/html").send(page("Politique de confidentialité", `
<h1>Politique de confidentialité</h1>
<p>L'application Vide-Grenier (éditée par <strong>Louis de Caumont</strong>) respecte ta vie privée. Voici les données traitées et pourquoi.</p>
<h2>Données traitées</h2>
<ul>
<li><strong>Localisation</strong> : utilisée pour centrer la carte et rechercher les événements autour de toi. Elle n'est pas conservée sur nos serveurs au-delà de la requête.</li>
<li><strong>Photos</strong> : les visages et plaques d'immatriculation sont <strong>floutés sur ton téléphone</strong>, de façon irréversible, <strong>avant tout envoi</strong>. Seule l'image anonymisée est stockée.</li>
<li><strong>Identifiant d'appareil anonyme</strong> : un identifiant aléatoire est généré au premier lancement pour rattacher tes contributions. Aucun nom, e-mail ou numéro n'est demandé.</li>
<li><strong>Paiement</strong> : la publication d'une annonce (5 €) est traitée par <strong>Stripe</strong>. Nous ne voyons ni ne stockons jamais tes données de carte.</li>
</ul>
<h2>Ce que nous ne faisons pas</h2>
<p>Aucun traçage publicitaire, aucune revente de données, aucune publicité.</p>
<h2>Hébergement</h2>
<p>Les données sont hébergées en France (Strasbourg).</p>
<h2>Tes droits (RGPD)</h2>
<p>Tu peux demander l'accès ou la suppression de tes données à <strong>${CONTACT}</strong>.</p>
`));
  });

  fastify.get("/terms", async (_req, reply) => {
    reply.type("text/html").send(page("Conditions d'utilisation", `
<h1>Conditions d'utilisation</h1>
<h2>Contenus publiés par les utilisateurs</h2>
<p><strong>Tolérance zéro</strong> envers les contenus répréhensibles, offensants, illégaux ou portant atteinte à autrui. En publiant une photo, un tag ou une annonce, tu garantis disposer des droits nécessaires et t'engages à ne rien publier de tel.</p>
<h2>Signalement et blocage</h2>
<p>Chaque photo peut être <strong>signalée</strong> ; les contenus signalés sont masqués automatiquement et examinés sous 24 h. Tu peux aussi <strong>bloquer</strong> un utilisateur pour ne plus voir ses contributions.</p>
<h2>Sanctions</h2>
<p>Tout contenu enfreignant ces règles est retiré, et les comptes abusifs peuvent être bloqués.</p>
<h2>Contact</h2>
<p>Pour tout signalement urgent : <strong>${CONTACT}</strong>.</p>
`));
  });
}
