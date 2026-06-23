import { connect, close } from "../db.js";
import { runImport } from "../datatourisme.js";
import { config } from "../config.js";

/// Import manuel : `npm run import` (utilise DATATOURISME_API_KEY de l'env).
async function main(): Promise<void> {
  await connect();
  try {
    const result = await runImport(config.dataTourismeApiKey);
    console.log("Import terminé:", JSON.stringify(result));
  } finally {
    await close();
  }
}

main().catch((e) => { console.error(e); process.exit(1); });
