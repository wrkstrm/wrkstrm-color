import SwiftUI
import VariantKit
import WrkstrmColor
import WrkstrmSharedAppShell

// Shared environment for gradient options
struct GradientOptions: Sendable {
  enum Kind: String, CaseIterable, Identifiable, Sendable { case linear, radial, angular; var id: String { rawValue } }
  var kind: Kind = .linear
  var count: Int = 10
  var reversed: Bool = false
  var angle: Double = 45
}
private struct GradientOptionsKey: EnvironmentKey { static let defaultValue = GradientOptions() }
extension EnvironmentValues {
  var gradientOptions: GradientOptions {
    get { self[GradientOptionsKey.self] }
    set { self[GradientOptionsKey.self] = newValue }
  }
}

private enum ColorDemoDestination: Hashable {
  case accessibility
  case gradient(Palette.Gradient)
  case variant(String)
}

struct ColorDemoRootView: View {
  @State private var options: GradientOptions = .init()
  @State private var accessibilityOptions: AccessibilityContrastOptions = .init()
  @State private var selectedDestination: ColorDemoDestination = .gradient(.blue)
  @State private var columnVisibility: NavigationSplitViewVisibility = .all
  @State private var inspectorPresented: Bool = true

  private var variants: [any VisualVariant] { VariantRegistry.all() }
  private var selectedVariant: (any VisualVariant)? {
    guard case .variant(let id) = selectedDestination else { return nil }
    return variants.first { $0.id == id }
  }
  private var selectedGradient: Palette.Gradient {
    guard case .gradient(let gradient) = selectedDestination else { return .blue }
    return gradient
  }
  private let previewGradients: [Palette.Gradient] = [.red, .green, .blue, .yellow, .black, .white]
  private var previewSteps: [GradientPreviewStep] {
    (0..<options.count).map { index in
      let hsluv: HSLuv<Double> = Palette.hsluvGradient(
        for: selectedGradient,
        index: index,
        count: max(options.count, 1),
        reversed: options.reversed
      )
      return GradientPreviewStep(
        index: index,
        hsluv: hsluv,
        color: Color(hsluv: hsluv, opacity: 1.0),
        lightContrast: nil,
        darkContrast: nil
      )
    }
  }
  private var accessibilityEntries: [AccessibilityRampEntry] {
    AccessibilityRampAnalyzer.analyze(
      gradients: previewGradients,
      options: accessibilityOptions
    )
  }

  var body: some View {
    WrkstrmSharedAppShell(
      columnVisibility: $columnVisibility,
      inspectorPresented: $inspectorPresented,
      inspectorMinWidth: 280
    ) {
      sidebarContent
    } detail: {
      detailContent
    } inspector: {
      inspectorContent
    }
    .frame(minWidth: 820, minHeight: 520)
    .navigationSplitViewStyle(.balanced)
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          inspectorPresented.toggle()
        } label: {
          Label("Toggle Inspector", systemImage: "sidebar.right")
        }
      }
    }
  }

  private var sidebarContent: some View {
    List(selection: $selectedDestination) {
      Section("Accessibility") {
        sidebarRow(
          title: "Universal Ramps",
          subtitle: "Shared light and dark accessible gradients",
          systemImage: "circle.lefthalf.filled.righthalf.striped.horizontal",
          tag: .accessibility
        )
      }

      Section("Gradients") {
        ForEach(previewGradients, id: \.rawValue) { gradient in
          gradientSidebarRow(for: gradient)
        }
      }

      Section("Studies") {
        ForEach(variants, id: \.id) { variant in
          sidebarRow(
            title: variant.displayName,
            subtitle: variant.abstract,
            systemImage: variant.iconSystemName ?? "square.grid.2x2",
            tag: .variant(variant.id)
          )
        }
      }

      Section("Notes") {
        Text("Choose a gradient on the left, then tune it from the inspector.")
          .font(.caption)
          .foregroundStyle(.secondary)
          .padding(.vertical, 4)
      }
    }
    .listStyle(.sidebar)
    .navigationTitle("WrkstrmColor")
  }

  @ViewBuilder
  private var detailContent: some View {
    Group {
      if selectedDestination == .accessibility {
        AccessibilityWorkbenchView(
          entries: accessibilityEntries,
          options: accessibilityOptions
        )
      } else if case .gradient(let gradient) = selectedDestination {
        GradientWorkbenchView(
          gradient: gradient,
          options: options,
          steps: previewSteps
        )
      } else if let variant = selectedVariant {
        VStack(spacing: 0) {
          detailHeader(for: variant)
          Divider()
          variant.makeView()
            .environment(\.gradientOptions, options)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      } else {
        ContentUnavailableView(
          "No Variant Selected",
          systemImage: "swatchpalette",
          description: Text("Choose a color study from the sidebar.")
        )
      }
    }
    .navigationTitle(navigationTitle)
  }

  @ViewBuilder
  private var inspectorContent: some View {
    if selectedDestination == .accessibility {
      AccessibilityInspectorView(
        options: $accessibilityOptions,
        entryCount: accessibilityEntries.count
      )
    } else {
      ColorDemoInspectorView(
        gradient: selectedGradient,
        options: $options,
        steps: previewSteps,
        gradientName: gradientName(for: selectedGradient)
      )
    }
  }

  @ViewBuilder
  private func detailHeader(for variant: any VisualVariant) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .firstTextBaseline, spacing: 10) {
        if let icon = variant.iconSystemName {
          Image(systemName: icon)
            .font(.title3)
            .foregroundStyle(.secondary)
        }
        VStack(alignment: .leading, spacing: 4) {
          Text(variant.displayName)
            .font(.title2.weight(.semibold))
          Text(variant.abstract)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        Spacer()
      }

      HStack(spacing: 10) {
        Label(gradientName(for: selectedGradient), systemImage: "wand.and.stars")
        Text("\(options.count) stops")
        if options.reversed {
          Text("Reversed")
        }
        if options.kind != .radial {
          Text("\(Int(options.angle))°")
        }
      }
      .font(.caption)
      .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(20)
    .background(.thinMaterial)
  }

  private var navigationTitle: String {
    switch selectedDestination {
    case .accessibility:
      return "Universal Accessibility"
    case .gradient(let gradient):
      return "\(gradientName(for: gradient)) Workbench"
    case .variant(let id):
      return variants.first(where: { $0.id == id })?.displayName ?? "WrkstrmColor Demo"
    }
  }

  @ViewBuilder
  private func sidebarRow(
    title: String,
    subtitle: String,
    systemImage: String,
    tag: ColorDemoDestination
  ) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(spacing: 8) {
        Image(systemName: systemImage)
          .foregroundStyle(.secondary)
        Text(title)
          .font(.headline)
      }
      Text(subtitle)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(2)
    }
    .padding(.vertical, 4)
    .tag(tag)
  }

  @ViewBuilder
  private func gradientSidebarRow(for gradient: Palette.Gradient) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        Image(systemName: "square.3.layers.3d.top.filled")
          .foregroundStyle(.secondary)
        Text(gradientName(for: gradient))
          .font(.headline)
      }
      GradientRampStrip(colors: previewColors(for: gradient), height: 16, cornerRadius: 4)
      Text("Open this ramp in the workbench and tune the sequence live.")
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(2)
    }
    .padding(.vertical, 4)
    .tag(ColorDemoDestination.gradient(gradient))
  }

  private func previewColors(for gradient: Palette.Gradient) -> [Color] {
    (0..<6).map { index in
      let hsluv: HSLuv<Double> = Palette.hsluvGradient(
        for: gradient,
        index: index,
        count: 6,
        reversed: false
      )
      return Color(hsluv: hsluv, opacity: 1.0)
    }
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

private struct ColorDemoInspectorView: View {
  let gradient: Palette.Gradient
  @Binding var options: GradientOptions
  let steps: [GradientPreviewStep]
  let gradientName: String

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        VStack(alignment: .leading, spacing: 6) {
          Text("Gradient Inspector")
            .font(.headline)
          Text("\(gradientName) ramp controls and live stop preview.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Divider()

        VStack(alignment: .leading, spacing: 10) {
          Text("Gradient Type")
            .font(.caption)
            .foregroundStyle(.secondary)
          Picker("Type", selection: $options.kind) {
            ForEach(GradientOptions.Kind.allCases) { kind in
              Text(kind.rawValue.capitalized).tag(kind)
            }
          }
          .pickerStyle(.segmented)
        }

        VStack(alignment: .leading, spacing: 10) {
          Stepper(value: $options.count, in: 3...24) {
            LabeledContent("Stops", value: "\(options.count)")
          }
          Toggle("Reverse", isOn: $options.reversed)
        }

        if options.kind != .radial {
          VStack(alignment: .leading, spacing: 8) {
            LabeledContent("Angle", value: "\(Int(options.angle))°")
              .font(.caption)
              .foregroundStyle(.secondary)
            Slider(value: $options.angle, in: 0...360)
          }
        }

        Divider()

        VStack(alignment: .leading, spacing: 10) {
          Text("Live Ramp")
            .font(.headline)
          GradientRampStrip(colors: steps.map(\.color), height: 42, cornerRadius: 10)
        }

        VStack(alignment: .leading, spacing: 10) {
          Text("Stops")
            .font(.headline)
          GradientWorkbenchGrid(steps: steps, tileHeight: 44, columnCount: 2, showMetrics: false)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(16)
    }
  }
}

struct GradientPreviewStep: Identifiable {
  let index: Int
  let hsluv: HSLuv<Double>
  let color: Color
  let lightContrast: Double?
  let darkContrast: Double?

  var id: Int { index }
}

private struct GradientWorkbenchView: View {
  let gradient: Palette.Gradient
  let options: GradientOptions
  let steps: [GradientPreviewStep]

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        VStack(alignment: .leading, spacing: 8) {
          Text("\(gradientName(for: gradient)) Ramp")
            .font(.largeTitle.weight(.semibold))
          Text("A full-screen view of the active gradient sequence, with every stop surfaced as its own visual step.")
            .font(.title3)
            .foregroundStyle(.secondary)
        }

        VStack(alignment: .leading, spacing: 12) {
          Text("Continuous Ramp")
            .font(.headline)
          GradientRampStrip(colors: steps.map(\.color), height: 96, cornerRadius: 18)
          HStack(spacing: 12) {
            Label(options.kind.rawValue.capitalized, systemImage: "wand.and.stars")
            Text("\(options.count) stops")
            if options.reversed {
              Text("Reversed")
            }
            if options.kind != .radial {
              Text("\(Int(options.angle))°")
            }
          }
          .font(.caption)
          .foregroundStyle(.secondary)
        }

        VStack(alignment: .leading, spacing: 12) {
          Text("Step Sequence")
            .font(.headline)
          GradientWorkbenchGrid(steps: steps)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(28)
    }
    .background(
      LinearGradient(
        colors: [steps.first?.color.opacity(0.12) ?? .clear, Color.clear],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    )
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

struct GradientRampStrip: View {
  let colors: [Color]
  var height: CGFloat = 18
  var cornerRadius: CGFloat = 5

  var body: some View {
    HStack(spacing: 3) {
      ForEach(Array(colors.enumerated()), id: \.offset) { _, color in
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(color)
          .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
          .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
              .strokeBorder(.white.opacity(0.14), lineWidth: 0.5)
          )
      }
    }
  }
}

struct GradientWorkbenchGrid: View {
  let steps: [GradientPreviewStep]
  var tileHeight: CGFloat = 88
  var columnCount: Int = 4
  var showMetrics: Bool = true

  private var columns: [GridItem] {
    Array(repeating: GridItem(.flexible(), spacing: 6), count: max(columnCount, 1))
  }

  var body: some View {
    LazyVGrid(columns: columns, spacing: 6) {
      ForEach(steps) { step in
        VStack(alignment: .leading, spacing: 4) {
          RoundedRectangle(cornerRadius: 7)
            .fill(step.color)
            .frame(height: tileHeight)
            .overlay(
              RoundedRectangle(cornerRadius: 7)
                .strokeBorder(.white.opacity(0.14), lineWidth: 0.5)
            )
          Text("Step \(step.index)")
            .font(.caption.weight(.semibold))
          if showMetrics {
            VStack(alignment: .leading, spacing: 2) {
              Text(
                "H \(Int(step.hsluv.h.rounded()))  S \(Int(step.hsluv.s.rounded()))  L \(Int(step.hsluv.l.rounded()))"
              )
              .font(.caption2.monospacedDigit())
              .foregroundStyle(.secondary)

              if let lightContrast = step.lightContrast, let darkContrast = step.darkContrast {
                Text(
                  "L \(String(format: "%.2f", lightContrast))  D \(String(format: "%.2f", darkContrast))"
                )
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
              }
            }
          }
        }
      }
    }
    .padding(.vertical, 2)
  }
}
