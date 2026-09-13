import type { RequestHandler } from "express";
import sharp from "sharp";

// Non-Saudi flyer crops come out of the scraper heavily JPEG-compressed
// (~30KB for a 512x400 photo), which reads as blur in the UI. A CSS filter
// can't fix that — the browser can't even read the pixels to try, since the
// S3 bucket sends no CORS headers. This proxy fetches the image server-side
// (no CORS problem there) and runs a real unsharp mask + mild upscale on it.
//
// Only the flyer-image S3 bucket is allow-listed — this must never become an
// open image-fetching proxy (SSRF risk).
const ALLOWED_HOSTS = new Set(["flyer-image-storage.s3.ap-south-1.amazonaws.com"]);

export const handleImageProxy: RequestHandler = async (req, res) => {
  const raw = req.query.url;
  if (typeof raw !== "string") {
    res.status(400).json({ error: "Missing url" });
    return;
  }

  let target: URL;
  try {
    target = new URL(raw);
  } catch {
    res.status(400).json({ error: "Invalid url" });
    return;
  }
  if (target.protocol !== "https:" || !ALLOWED_HOSTS.has(target.hostname)) {
    res.status(400).json({ error: "Host not allowed" });
    return;
  }

  try {
    const upstream = await fetch(target);
    if (!upstream.ok) {
      res.status(upstream.status).end();
      return;
    }
    const bytes = Buffer.from(await upstream.arrayBuffer());
    const sharpened = await sharp(bytes)
      // Upscale before sharpening — sharpening a tiny source and letting the
      // browser upscale it afterwards re-introduces the blur.
      .resize({ width: 1000, withoutEnlargement: false, kernel: "lanczos3" })
      .sharpen({ sigma: 2, m1: 1.5, m2: 3 })
      .jpeg({ quality: 92 })
      .toBuffer();

    res.setHeader("Content-Type", "image/jpeg");
    res.setHeader("Cache-Control", "public, max-age=604800, immutable");
    res.setHeader("Access-Control-Allow-Origin", "*");
    res.send(sharpened);
  } catch (err) {
    console.error("image-proxy failed:", err);
    res.status(502).json({ error: "Failed to process image" });
  }
};
