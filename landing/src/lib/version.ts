import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const FALLBACK = "0.0.0";

let cached: string | null = null;

export function getAppVersion(): string {
  if (cached) return cached;
  try {
    const ymlPath = resolve(process.cwd(), "..", "app", "project.yml");
    const yml = readFileSync(ymlPath, "utf-8");
    const match = yml.match(/^\s*MARKETING_VERSION:\s*"?([^"\n]+?)"?\s*$/m);
    cached = match?.[1].trim() ?? FALLBACK;
  } catch {
    cached = FALLBACK;
  }
  return cached;
}

export function getDmgFileName(): string {
  return `Ttae-${getAppVersion()}.dmg`;
}

export function getDmgDownloadUrl(): string {
  return `https://github.com/gmelon/ttae-not-ddae/releases/latest/download/${getDmgFileName()}`;
}

export function getReleasesPageUrl(): string {
  return "https://github.com/gmelon/ttae-not-ddae/releases/latest";
}

export function getRepoUrl(): string {
  return "https://github.com/gmelon/ttae-not-ddae";
}
