// @ts-check
import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://ttae.gmelon.dev',
  integrations: [sitemap()],
  build: {
    inlineStylesheets: 'auto',
  },
});
