import { getAppVersion } from "../lib/version";

export const prerender = true;

export async function GET() {
  return new Response(getAppVersion() + "\n", {
    headers: {
      "Content-Type": "text/plain; charset=utf-8",
      "Cache-Control": "public, max-age=300",
    },
  });
}
