# Dependabot Triage

The following advisories are flagged on default branch. Prioritize highs first; update manifests where present and run lockfile refresh.

High severity:
- node-forge (GHSA-554w-wpv2-vw27, GHSA-5gfm-wpxj-wjgq)
- image-size (GHSA-m5qc-5hw7-8vg7)
- validator (GHSA-vghf-hv5q-vc2g)

Medium (representative):
- js-yaml (GHSA-mh29-5h37-fv8m)
- vite (GHSA-93m4-6634-74q7)
- esbuild (GHSA-67mh-4wv8-2f99)
- prismjs (GHSA-x7hr-w5r2-h6wg)

Low examples:
- vite (GHSA-g4jq-h2w9-997c, GHSA-jqfw-vq24-v9c3)
- brace-expansion (GHSA-v6h2-p8h4-qcjw)

Action plan:
1. Identify manifests owning these deps (package.json in karabiner.ts-upstream/docs, site, examples).
2. Bump minors/patches where available; otherwise replace or remove transitive dev deps.
3. Run `npm install` to update lockfiles; commit separately per area.
4. Verify build: `npm run build` in karabiner.ts and any upstream docs builds.
5. If transitive via upstream, consider excluding affected packages from mirrored docs builds or pin safe versions.

Automation:
- Enable weekly "npm audit" GH Action on repo.
- Opt-in Dependabot updates for "karabiner.ts-upstream/docs" package.json.

