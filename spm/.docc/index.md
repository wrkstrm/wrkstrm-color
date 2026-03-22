@Metadata {
  @PageKind(article)
  @TechnologyRoot
}

# WrkstrmColor Package Layout

The canonical `WrkstrmColor` Swift package implementation lives under `spm/`.

## Canon

- Keep package code in `spm/Sources/` and `spm/Tests/`.
- Keep the repo-root `Package.swift` as the remote SwiftPM wrapper manifest.
- Do not move demo apps into `spm/`.
