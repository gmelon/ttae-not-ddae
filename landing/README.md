# 떄가아니라때 랜딩 페이지

`ttae.gmelon.dev` 로 서빙되는 정적 사이트. Astro 6 기반.

## 로컬 개발

```bash
cd landing
npm install
npm run dev      # http://localhost:4321
npm run build    # dist/ 에 정적 빌드
npm run preview  # 빌드 결과를 로컬에서 확인
```

## 디렉터리

- `src/pages/index.astro` — 랜딩 페이지 본문 (Hero, 음운 설명, 매핑 표, 기능, 다운로드, FAQ)
- `src/layouts/Layout.astro` — `<head>` 메타·OG·Schema.org JSON-LD, 글로벌 스타일
- `public/` — 정적 자산 (`logo.png`, `logo_transparent.png`, `robots.txt`)
- `astro.config.mjs` — `site: https://ttae.gmelon.dev`, `@astrojs/sitemap` 통합

## 배포

루트의 `docs/LANDING_DEPLOY.md` 참고.
