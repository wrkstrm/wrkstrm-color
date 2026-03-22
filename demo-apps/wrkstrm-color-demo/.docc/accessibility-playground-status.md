# accessibility playground status

Current implementation note for the `Universal Accessibility` screen in `WrkstrmColorDemo`.

## files in play

- [RootView.swift](../Sources/RootView.swift)
- [AccessibilityWorkbench.swift](../Sources/AccessibilityWorkbench.swift)
- [WrkstrmColorDemoApp.swift](../Sources/WrkstrmColorDemoApp.swift)
- [XcodeGen.yml](../XcodeGen.yml)

## what was added

- the app now uses `WrkstrmSharedAppShell` for the sidebar, detail, and inspector layout
- `Universal Accessibility` is a first-class sidebar destination instead of a small inline control surface
- the inspector now includes working-group contrast presets and links to the WCAG source material
- `Light Start` and `Dark End` now use the native macOS system color selector through `NSColorWell`
- the XcodeGen app target now builds a real macOS `.app` bundle, with generated Info.plist support and a deployment target aligned with `WrkstrmColor`

## current model

- the user chooses:
  - a minimum light-side contrast floor
  - a dark-side contrast ceiling
  - light and dark reference colors
  - sample and output counts
- the analyzer evaluates the built-in palette families against those chosen reference colors
- qualifying samples are sorted from the light reference toward the dark reference before downsampling into a displayed ramp

## what is still broken

- the screen still feels conceptually wrong for the intended task
- the chosen `Light Start` and `Dark End` colors are currently used as contrast references and visual anchors, but the interior ramp is still selected from the fixed palette families
- that means the screen does **not** yet synthesize a true universal ramp whose first and last colors are meaningfully derived from the chosen endpoints
- the current `minimum light` and `dark ceiling` language is also too indirect for the actual design goal, which is closer to:
  - choose a light surface color
  - choose a dark surface color
  - choose an accessibility target
  - generate the valid shared interior ramp band between those two surfaces
- the ordering bug was improved, but the overall accessibility-workbench model still does not match the mental model the user expects

## known good pieces to keep

- keep the shell composition in `RootView.swift`
- keep the accessibility controls in the inspector instead of pushing them back into the detail header
- keep the native system color panel integration
- keep the working-group preset/source-link surface
- keep `WrkstrmColor` as the source of truth for contrast calculations

## next round

- redesign the accessibility workbench around endpoint-driven ramp construction instead of family-first filtering
- rename the controls to reflect the actual goal instead of the current floor/ceiling framing
- decide whether the result should:
  - generate a new ramp from the selected endpoints, or
  - search existing color families for the valid interior band and then clearly label that as a search result
- make the visual result explain why each step is included, excluded, or clipped

## launch note

The reliable launch path for this app is the generated Xcode build product, not only the raw SwiftPM executable:

```bash
xcodegen generate --spec XcodeGen.yml
xcodebuild \
  -project WrkstrmColorDemo.xcodeproj \
  -scheme WrkstrmColorDemoApp \
  -destination 'platform=macOS,arch=arm64' \
  build
open ~/Library/Developer/Xcode/DerivedData/WrkstrmColorDemo-*/Build/Products/Debug/WrkstrmColorDemoApp.app
```
