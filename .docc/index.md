# WrkstrmColor Family
@Metadata {
  @PageKind(article)
  @TechnologyRoot
}

Reusable cross-platform color primitives owned by `wrkstrm-components`.

## Layout

- `Package.swift` at the repo root keeps the standalone package consumable by remote SwiftPM.
- `spm/` holds the canonical `WrkstrmColor` package sources and tests.
- `demo-apps/` holds focused validation apps for this primitive family.

## Canon

- Keep `WrkstrmColor` in `wrkstrm-components` as a reusable primitive family, not under the broader `wrkstrm` system package tree.
- Keep the standalone repo rooted at `private/primitives/wrkstrm-color/`.
- Keep the package implementation under `spm/`, but keep the manifest at the repo root for SwiftPM compatibility.
- Keep package-facing usage notes in the repo `README.md`, and keep family ownership and layout notes here.
