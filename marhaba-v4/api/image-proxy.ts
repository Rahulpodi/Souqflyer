// Vercel serves the site as a static SPA, so /api/image-proxy needs its own
// serverless function. Vercel's req/res expose query/status/json/send, which
// is all the Express handler uses.
// The ".js" extension is required: Vercel runs this as native ESM (package.json
// "type": "module"), where Node refuses extensionless relative imports.
import { handleImageProxy } from "../server/routes/image-proxy.js";

export default handleImageProxy;
