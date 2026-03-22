import AppKit
import SwiftUI
import WrkstrmColor

enum AccessibilityPreset: String, CaseIterable, Identifiable, Sendable {
  case custom
  case aaBodyText
  case aaLargeText
  case aaaBodyText
  case aaaLargeText
  case aaNonText

  var id: String { rawValue }

  var title: String {
    switch self {
    case .custom: "Custom"
    case .aaBodyText: "AA Body Text"
    case .aaLargeText: "AA Large Text"
    case .aaaBodyText: "AAA Body Text"
    case .aaaLargeText: "AAA Large Text"
    case .aaNonText: "AA Non-Text"
    }
  }

  var detail: String {
    switch self {
    case .custom:
      "Manual contrast window."
    case .aaBodyText:
      "WCAG 2.2 SC 1.4.3 minimum for normal-sized text."
    case .aaLargeText:
      "WCAG 2.2 SC 1.4.3 minimum for large-scale text."
    case .aaaBodyText:
      "WCAG 2.2 SC 1.4.6 enhanced requirement for normal-sized text."
    case .aaaLargeText:
      "WCAG 2.2 SC 1.4.6 enhanced requirement for large-scale text."
    case .aaNonText:
      "WCAG 2.2 SC 1.4.11 minimum for UI components and graphical objects."
    }
  }

  var minimumContrast: Double? {
    switch self {
    case .custom:
      nil
    case .aaBodyText, .aaaLargeText:
      4.5
    case .aaLargeText, .aaNonText:
      3.0
    case .aaaBodyText:
      7.0
    }
  }

  var sourceTitle: String {
    switch self {
    case .custom:
      "WCAG 2.2 Contrast Sources"
    case .aaBodyText, .aaLargeText:
      "WAI Understanding SC 1.4.3 Contrast (Minimum)"
    case .aaaBodyText, .aaaLargeText:
      "WAI Understanding SC 1.4.6 Contrast (Enhanced)"
    case .aaNonText:
      "WAI Understanding SC 1.4.11 Non-text Contrast"
    }
  }

  var sourceURL: URL? {
    switch self {
    case .custom:
      nil
    case .aaBodyText, .aaLargeText:
      URL(string: "https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum")
    case .aaaBodyText, .aaaLargeText:
      URL(string: "https://www.w3.org/WAI/WCAG22/Understanding/contrast-enhanced")
    case .aaNonText:
      URL(string: "https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast")
    }
  }

  func derivedMaximumDarkContrast(
    lightReference: AccessibilityReferenceColor,
    darkReference: AccessibilityReferenceColor
  ) -> Double? {
    guard let minimumContrast else { return nil }
    let lightLuminance = lightReference.rgb.luminance
    let darkLuminance = darkReference.rgb.luminance
    let upperCandidateLuminance = ((lightLuminance + 0.05) / minimumContrast) - 0.05
    let upperDarkContrast = (upperCandidateLuminance + 0.05) / (darkLuminance + 0.05)
    return max(upperDarkContrast, minimumContrast)
  }
}

struct AccessibilityContrastOptions: Sendable {
  var preset: AccessibilityPreset = .aaBodyText
  var minimumLightContrast: Double = 4.5
  var maximumDarkContrast: Double = 4.75
  var denseSampleCount: Int = 96
  var outputStepCount: Int = 10
  var lightReferenceHex: String = "#ffffff"
  var darkReferenceHex: String = "#000000"

  var lightReference: AccessibilityReferenceColor {
    AccessibilityReferenceColor(hexString: lightReferenceHex) ?? .white
  }

  var darkReference: AccessibilityReferenceColor {
    AccessibilityReferenceColor(hexString: darkReferenceHex) ?? .black
  }

  var minimumDarkContrast: Double { minimumLightContrast }

  mutating func applyPreset(_ preset: AccessibilityPreset) {
    self.preset = preset
    guard let minimumContrast = preset.minimumContrast else { return }
    minimumLightContrast = minimumContrast
    if let derivedMaximum = preset.derivedMaximumDarkContrast(
      lightReference: lightReference,
      darkReference: darkReference
    ) {
      maximumDarkContrast = derivedMaximum
    }
  }
}

struct AccessibilityRampEntry: Identifiable {
  let gradient: Palette.Gradient
  let representativeSteps: [GradientPreviewStep]
  let qualifyingSamples: Int
  let minimumObservedLightContrast: Double
  let maximumObservedDarkContrast: Double

  var id: Int { gradient.rawValue }
}

struct AccessibilityReferenceColor: Sendable {
  let hexString: String
  let rgb: RGB<Double>
  let color: Color

  static let white = AccessibilityReferenceColor(rgb: RGB(r: 1, g: 1, b: 1), hexString: "#ffffff")
  static let black = AccessibilityReferenceColor(rgb: RGB(r: 0, g: 0, b: 0), hexString: "#000000")

  init?(hexString: String) {
    let normalized = Self.normalize(hexString)
    guard Self.isValid(normalized) else { return nil }
    let rgb: RGB<Double> = Hex(normalized).toRgb()
    self.init(rgb: rgb, hexString: normalized)
  }

  init(rgb: RGB<Double>, hexString: String) {
    self.rgb = rgb
    self.hexString = hexString
    self.color = Color(red: rgb.r, green: rgb.g, blue: rgb.b)
  }

  init(nsColor: NSColor) {
    let rgbColor = nsColor.usingColorSpace(.sRGB) ?? .white
    let components = rgbColor.rgbaComponents().rgb
    let rgb = RGB<Double>(
      r: Double(components.r),
      g: Double(components.g),
      b: Double(components.b)
    )
    self.init(rgb: rgb, hexString: rgb.toHex.string)
  }

  private static func normalize(_ value: String) -> String {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.hasPrefix("#") {
      return trimmed.lowercased()
    }
    return "#\(trimmed.lowercased())"
  }

  private static func isValid(_ value: String) -> Bool {
    let pattern = /^#[0-9a-fA-F]{6}$/
    return value.wholeMatch(of: pattern) != nil
  }
}

enum AccessibilityRampAnalyzer {
  static func analyze(
    gradients: [Palette.Gradient],
    options: AccessibilityContrastOptions
  ) -> [AccessibilityRampEntry] {
    gradients.compactMap { gradient in
      entry(for: gradient, options: options)
    }
  }

  private static func entry(
    for gradient: Palette.Gradient,
    options: AccessibilityContrastOptions
  ) -> AccessibilityRampEntry? {
    let lightReference = options.lightReference.rgb
    let darkReference = options.darkReference.rgb
    let sampleCount = max(options.denseSampleCount, 2)
    let qualifying = (0..<sampleCount).compactMap { index -> GradientPreviewStep? in
      let hsluv: HSLuv<Double> = Palette.hsluvGradient(
        for: gradient,
        index: index,
        count: sampleCount,
        reversed: false
      )
      let rgb = hsluvToRgb(hsluv)
      let lightContrast = rgb.contrastRatio(to: lightReference)
      let darkContrast = rgb.contrastRatio(to: darkReference)
      guard
        lightContrast >= options.minimumLightContrast,
        darkContrast >= options.minimumDarkContrast,
        darkContrast <= options.maximumDarkContrast
      else {
        return nil
      }

      return GradientPreviewStep(
        index: index,
        hsluv: hsluv,
        color: Color(hsluv: hsluv, opacity: 1.0),
        lightContrast: lightContrast,
        darkContrast: darkContrast
      )
    }

    guard !qualifying.isEmpty else { return nil }
    let orderedQualifying = qualifying.sorted { lhs, rhs in
      let lhsLightContrast = lhs.lightContrast ?? .greatestFiniteMagnitude
      let rhsLightContrast = rhs.lightContrast ?? .greatestFiniteMagnitude
      if lhsLightContrast == rhsLightContrast {
        return lhs.index > rhs.index
      }
      return lhsLightContrast < rhsLightContrast
    }

    let representativeSteps = downsample(
      orderedQualifying,
      targetCount: min(options.outputStepCount, orderedQualifying.count)
    )

    return AccessibilityRampEntry(
      gradient: gradient,
      representativeSteps: representativeSteps,
      qualifyingSamples: orderedQualifying.count,
      minimumObservedLightContrast: orderedQualifying.compactMap(\.lightContrast).min() ?? 0,
      maximumObservedDarkContrast: orderedQualifying.compactMap(\.darkContrast).max() ?? 0
    )
  }

  private static func downsample(
    _ steps: [GradientPreviewStep],
    targetCount: Int
  ) -> [GradientPreviewStep] {
    guard !steps.isEmpty else { return [] }
    guard targetCount > 0, steps.count > targetCount else { return steps }

    let denominator = max(targetCount - 1, 1)
    return (0..<targetCount).map { outputIndex in
      let ratio = Double(outputIndex) / Double(denominator)
      let sourceIndex = Int((ratio * Double(steps.count - 1)).rounded())
      return steps[sourceIndex]
    }
  }
}

struct AccessibilityWorkbenchView: View {
  let entries: [AccessibilityRampEntry]
  let options: AccessibilityContrastOptions

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Universal Accessibility Ramps")
            .font(.largeTitle.weight(.semibold))
          Text("Ramps that stay above the light-surface contrast floor while staying below the dark-surface contrast ceiling.")
            .font(.title3)
            .foregroundStyle(.secondary)
        }

        HStack(spacing: 14) {
          AccessibilityMetricChip(
            title: "Min Light",
            value: String(format: "%.2f:1", options.minimumLightContrast),
            systemImage: "sun.max"
          )
          AccessibilityMetricChip(
            title: "Dark Ceiling",
            value: String(format: "%.2f:1", options.maximumDarkContrast),
            systemImage: "moon"
          )
          AccessibilityMetricChip(
            title: "Samples",
            value: "\(options.denseSampleCount)",
            systemImage: "point.3.filled.connected.trianglepath.dotted"
          )
          AccessibilityMetricChip(
            title: "Stops",
            value: "\(options.outputStepCount)",
            systemImage: "square.stack.3d.up"
          )
        }

        HStack(spacing: 12) {
          AccessibilityReferenceChip(
            title: "Light Start",
            reference: options.lightReference,
            systemImage: "sun.max.fill"
          )
          AccessibilityReferenceChip(
            title: "Dark End",
            reference: options.darkReference,
            systemImage: "moon.fill"
          )
        }

        if entries.isEmpty {
          ContentUnavailableView(
            "No Universal Ramps",
            systemImage: "exclamationmark.triangle",
            description: Text("Widen the contrast window in the inspector to admit at least one family.")
          )
          .frame(maxWidth: .infinity, minHeight: 280)
        } else {
          VStack(alignment: .leading, spacing: 18) {
            ForEach(entries) { entry in
              AccessibilityRampCard(entry: entry, options: options)
            }
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(28)
    }
  }
}

struct AccessibilityInspectorView: View {
  @Binding var options: AccessibilityContrastOptions
  let entryCount: Int
  @State private var isApplyingPreset = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        VStack(alignment: .leading, spacing: 6) {
          Text("Accessibility Inspector")
            .font(.headline)
          Text("Define the shared light and dark contrast window that a ramp must fit inside.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Divider()

        VStack(alignment: .leading, spacing: 10) {
          Text("Working Group Presets")
            .font(.headline)

          Picker("Preset", selection: $options.preset) {
            ForEach(AccessibilityPreset.allCases) { preset in
              Text(preset.title).tag(preset)
            }
          }
          .pickerStyle(.menu)

          Text(options.preset.detail)
            .font(.caption)
            .foregroundStyle(.secondary)

          if let sourceURL = options.preset.sourceURL {
            Link(options.preset.sourceTitle, destination: sourceURL)
              .font(.caption)
          }
        }

        Divider()

        VStack(alignment: .leading, spacing: 10) {
          Text("Reference Colors")
            .font(.headline)
          AccessibilityReferenceField(
            title: "Light Start",
            text: $options.lightReferenceHex,
            fallback: .white
          )
          AccessibilityReferenceField(
            title: "Dark End",
            text: $options.darkReferenceHex,
            fallback: .black
          )
          Text("These colors become the visual start and end anchors of each universal ramp.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Divider()

        VStack(alignment: .leading, spacing: 8) {
          LabeledContent("Min Light Contrast", value: String(format: "%.2f:1", options.minimumLightContrast))
            .font(.caption)
            .foregroundStyle(.secondary)
          Slider(
            value: $options.minimumLightContrast,
            in: 1.0...7.0,
            step: 0.05
          )
        }

        VStack(alignment: .leading, spacing: 8) {
          LabeledContent("Dark Ceiling", value: String(format: "%.2f:1", options.maximumDarkContrast))
            .font(.caption)
            .foregroundStyle(.secondary)
          Slider(
            value: $options.maximumDarkContrast,
            in: max(options.minimumLightContrast, 1.0)...10.0,
            step: 0.05
          )
        }

        VStack(alignment: .leading, spacing: 8) {
          Stepper(value: $options.denseSampleCount, in: 24...192, step: 8) {
            LabeledContent("Dense Samples", value: "\(options.denseSampleCount)")
          }
          Stepper(value: $options.outputStepCount, in: 3...18) {
            LabeledContent("Output Stops", value: "\(options.outputStepCount)")
          }
        }

        Divider()

        VStack(alignment: .leading, spacing: 8) {
          Text("Result")
            .font(.headline)
          Text("\(entryCount) gradient families currently qualify.")
            .font(.subheadline)
          Text("The screen keeps only colors whose contrast against both chosen surfaces stays above the selected WCAG floor, while also respecting the dark-side ceiling that defines the shared universal band.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        VStack(alignment: .leading, spacing: 8) {
          Text("Sources")
            .font(.headline)
          Link(
            "WAI Understanding SC 1.4.3 Contrast (Minimum)",
            destination: URL(string: "https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum")!
          )
          .font(.caption)
          Link(
            "WAI Understanding SC 1.4.6 Contrast (Enhanced)",
            destination: URL(string: "https://www.w3.org/WAI/WCAG22/Understanding/contrast-enhanced")!
          )
          .font(.caption)
          Link(
            "WAI Understanding SC 1.4.11 Non-text Contrast",
            destination: URL(string: "https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast")!
          )
          .font(.caption)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(16)
    }
    .onAppear {
      if options.preset != .custom {
        applyPreset(options.preset)
      }
    }
    .onChange(of: options.preset) { _, newValue in
      applyPreset(newValue)
    }
    .onChange(of: options.lightReferenceHex) { _, _ in
      if options.preset != .custom {
        applyPreset(options.preset)
      }
    }
    .onChange(of: options.darkReferenceHex) { _, _ in
      if options.preset != .custom {
        applyPreset(options.preset)
      }
    }
    .onChange(of: options.minimumLightContrast) { _, _ in
      markCustomIfNeeded()
    }
    .onChange(of: options.maximumDarkContrast) { _, _ in
      markCustomIfNeeded()
    }
  }

  private func applyPreset(_ preset: AccessibilityPreset) {
    guard !isApplyingPreset else { return }
    isApplyingPreset = true
    options.applyPreset(preset)
    isApplyingPreset = false
  }

  private func markCustomIfNeeded() {
    guard !isApplyingPreset, options.preset != .custom else { return }
    guard
      let minimumContrast = options.preset.minimumContrast,
      let derivedMaximum = options.preset.derivedMaximumDarkContrast(
        lightReference: options.lightReference,
        darkReference: options.darkReference
      )
    else {
      return
    }

    let epsilon = 0.001
    let minimumDrifted = abs(options.minimumLightContrast - minimumContrast) > epsilon
    let maximumDrifted = abs(options.maximumDarkContrast - derivedMaximum) > epsilon
    if minimumDrifted || maximumDrifted {
      options.preset = .custom
    }
  }
}

private struct AccessibilityRampCard: View {
  let entry: AccessibilityRampEntry
  let options: AccessibilityContrastOptions

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(alignment: .firstTextBaseline) {
        Text(gradientName(for: entry.gradient))
          .font(.title3.weight(.semibold))
        Spacer()
        Text("\(entry.qualifyingSamples) qualifying samples")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      GradientRampStrip(
        colors: [options.lightReference.color] + entry.representativeSteps.map(\.color) + [options.darkReference.color],
        height: 64,
        cornerRadius: 14
      )

      HStack(spacing: 12) {
        Text("Light ≥ \(String(format: "%.2f:1", entry.minimumObservedLightContrast))")
        Text("Dark ≤ \(String(format: "%.2f:1", entry.maximumObservedDarkContrast))")
      }
      .font(.caption)
      .foregroundStyle(.secondary)

      GradientWorkbenchGrid(
        steps: entry.representativeSteps,
        tileHeight: 64,
        columnCount: 5,
        showMetrics: true
      )
    }
    .padding(18)
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
  }

  private func gradientName(for gradient: Palette.Gradient) -> String {
    switch gradient {
    case .red: "Red"
    case .green: "Green"
    case .blue: "Blue"
    case .yellow: "Yellow"
    case .black: "Black"
    case .white: "White"
    }
  }
}

private struct AccessibilityMetricChip: View {
  let title: String
  let value: String
  let systemImage: String

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: systemImage)
        .foregroundStyle(.secondary)
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.caption)
          .foregroundStyle(.secondary)
        Text(value)
          .font(.subheadline.weight(.semibold))
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .background(.thinMaterial, in: Capsule())
  }
}

private struct AccessibilityReferenceChip: View {
  let title: String
  let reference: AccessibilityReferenceColor
  let systemImage: String

  var body: some View {
    HStack(spacing: 10) {
      RoundedRectangle(cornerRadius: 8)
        .fill(reference.color)
        .frame(width: 28, height: 28)
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
        )
      VStack(alignment: .leading, spacing: 2) {
        Label(title, systemImage: systemImage)
          .font(.caption)
          .foregroundStyle(.secondary)
        Text(reference.hexString)
          .font(.subheadline.monospaced())
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .background(.thinMaterial, in: Capsule())
  }
}

private struct AccessibilityReferenceField: View {
  let title: String
  @Binding var text: String
  let fallback: AccessibilityReferenceColor

  private var resolvedReference: AccessibilityReferenceColor {
    AccessibilityReferenceColor(hexString: text) ?? fallback
  }

  private var colorSelection: Binding<Color> {
    Binding(
      get: { resolvedReference.color },
      set: { selectedColor in
        text = AccessibilityReferenceColor(nsColor: NSColor(selectedColor)).hexString
      }
    )
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.caption)
        .foregroundStyle(.secondary)
      HStack(spacing: 10) {
        RoundedRectangle(cornerRadius: 8)
          .fill(resolvedReference.color)
          .frame(width: 28, height: 28)
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
          )
        AccessibilitySystemColorWell(color: colorSelection)
          .frame(width: 44, height: 28)
        TextField("#ffffff", text: $text)
          .textFieldStyle(.roundedBorder)
          .font(.body.monospaced())
      }
    }
  }
}

private struct AccessibilitySystemColorWell: NSViewRepresentable {
  @Binding var color: Color

  func makeCoordinator() -> Coordinator {
    Coordinator(color: $color)
  }

  func makeNSView(context: Context) -> NSColorWell {
    let colorWell = NSColorWell()
    colorWell.color = NSColor(color)
    colorWell.isBordered = true
    colorWell.action = #selector(Coordinator.colorDidChange(_:))
    colorWell.target = context.coordinator
    return colorWell
  }

  func updateNSView(_ nsView: NSColorWell, context: Context) {
    let targetColor = NSColor(color).usingColorSpace(.sRGB) ?? .white
    let currentColor = nsView.color.usingColorSpace(.sRGB) ?? .white
    guard currentColor != targetColor else { return }
    nsView.color = targetColor
  }

  @MainActor
  final class Coordinator: NSObject {
    @Binding private var color: Color

    init(color: Binding<Color>) {
      _color = color
    }

    @objc func colorDidChange(_ sender: NSColorWell) {
      color = Color(sender.color)
    }
  }
}
