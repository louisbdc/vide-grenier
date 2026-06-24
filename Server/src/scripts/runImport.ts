import { connect, close } from "../db.js";
import { runImport } from "../datatourisme.js";
import { runOpenAgendaImport } from "../openagenda.js";
import { config } from "../config.js";

/// Import manuel : `npm run import` (DATAtourisme via DATATOURISME_API_KEY,
/// + OpenAgenda sans clé pour les vide-greniers de villages).
async function main(): Promise<void> {
  await connect();
  try {
    if (config.dataTourismeApiKey) {
      const dt = await runImport(config.dataTourismeApiKey);
      console.log("Import DATAtourisme:", JSON.stringify(dt));
    } else {
      console.warn("DATATOURISME_API_KEY absente — import DATAtourisme ignoré.");
    }
    const oa = await runOpenAgendaImport();
    console.log("Import OpenAgenda:", JSON.stringify(oa));
  } finally {
    await close();
  }
}

main().catch((e) => { console.error(e); process.exit(1); });
