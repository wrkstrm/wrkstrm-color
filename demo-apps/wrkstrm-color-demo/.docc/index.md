# wrkstrm-color-demo
@Metadata {
  @PageKind(article)
  @TechnologyRoot
}

Mac app playground for `WrkstrmColor` and the shared `WrkstrmSharedAppShell` layout.

```text
<root>
├─ .docc/
│  ├─ index.md
│  └─ accessibility-playground-status.md
├─ Sources/
│  ├─ WrkstrmColorDemoApp.swift
│  ├─ RootView.swift
│  ├─ AccessibilityWorkbench.swift
│  ├─ PaletteShowcase.swift
│  └─ Variants.swift
├─ Package.swift
├─ XcodeGen.yml
└─ WrkstrmColorDemo.xcodeproj
```

## purpose

- exercise `WrkstrmColor` as a mac-native demo surface
- use `WrkstrmSharedAppShell` for sidebar, detail, and inspector composition
- pressure-test gradient tooling and accessibility-ramp ideas before moving them into broader component surfaces

## current shape

- `Sources/RootView.swift` owns the shell composition and navigation destinations
- `Sources/AccessibilityWorkbench.swift` owns the universal accessibility ramp experiment
- `Sources/PaletteShowcase.swift` and `Sources/Variants.swift` hold the study/demo variants
- `XcodeGen.yml` is the canonical app-bundle manifest for the generated macOS app target

## active note

- <doc:accessibility-playground-status>

## canon

- keep internal orientation here instead of `README.md`
- keep status and design notes in `.docc/`
- keep the SwiftPM executable and the XcodeGen app target aligned, but treat the generated `.app` path as the reliable launch surface
