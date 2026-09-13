// Vercel serves the site as a static SPA, so /api/image-proxy needs its own
// serverless function. Vercel's req/res expose query/status/json/send, which
// is all the Express handler uses.
import { handleImageProxy } from "../server/routes/image-proxy";

export default handleImageProxy;
