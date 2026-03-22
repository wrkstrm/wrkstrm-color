import SwiftUI
import VariantKit
import WrkstrmColor

@MainActor
func registerWrkstrmColorVariants() {
  VariantRegistry.set([
    PaletteGradientsVariant(),
    DescriptorGradientsVariant(),
    ContrastBlueVariant(),
    PaletteShowcaseVariant(),
    ContrastAuditVariant(),
  ])
}

// MARK: - Shared Views

struct GradientSwatch: View {
  let colors: [Color]
  @Environment(\.gradientOptions) private var opt
  var body: some View {
    GeometryReader { geo in
      let gradient = Gradient(colors: colors)
      ZStack {
        switch opt.kind {
        case .linear:
          LinearGradient(gradient: gradient, startPoint: .init(x: 0, y: 0), endPoint: endPoint(angle: opt.angle))
        case .radial:
          RadialGradient(gradient: gradient, center: .center, startRadius: 0, endRadius: max(geo.size.width, geo.size.height) / 1.6)
        case .angular:
          AngularGradient(gradient: gradient, center: .center, angle: .degrees(opt.angle))
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: 10))
      .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(.white.opacity(0.12)) }
    }
  }
  private func endPoint(angle: Double) -> UnitPoint {
    let radians = angle * .pi / 180
    let x = cos(radians)
    let y = sin(radians)
    return UnitPoint(x: 0.5 + x/2, y: 0.5 + y/2)
  }
}

// MARK: - Palette-based gradients

struct PaletteGradientsVariant: VisualVariant {
  let id = "palette"
  let displayName = "Palette"
  let abstract = "Palette.hsluvGradient across types"
  var iconSystemName: String? { "square.grid.2x2" }
  func makeView() -> AnyView { AnyView(Body()) }

  private struct Body: View {
    @Environment(\.gradientOptions) private var opt
    let types: [Palette.Gradient] = [.red, .green, .blue, .yellow, .black, .white]
    var body: some View {
      ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 16)], spacing: 16) {
          ForEach(Array(types.enumerated()), id: \.0) { (_, g) in
            VStack(alignment: .leading, spacing: 8) {
              GradientSwatch(colors: makeColors(for: g))
                .frame(height: 120)
              Text(String(describing: g).capitalized)
                .font(.headline)
            }
          }
        }
        .padding()
      }
    }
    private func makeColors(for g: Palette.Gradient) -> [Color] {
      (0..<opt.count).map { i in
        let h: HSLuv<Double> = Palette.hsluvGradient(for: g, index: i, count: opt.count, reversed: opt.reversed)
        return Color(hsluv: h, opacity: 1.0)
      }
    }
  }
}

// MARK: - Descriptor gradients (fixed sets)

struct DescriptorGradientsVariant: VisualVariant {
  let id = "descriptor"
  let displayName = "Descriptors"
  let abstract = "HSLuv.red/green/black/white gradient descriptors"
  var iconSystemName: String? { "square.stack.3d.up" }
  func makeView() -> AnyView { AnyView(Body()) }

  private struct Body: View {
    @Environment(\.gradientOptions) private var opt
    var body: some View {
      let blocks: [(title: String, items: [HSLuv<Double>])] = [
        ("Red", Array(HSLuv<Double>.redGradient.prefix(opt.count))),
        ("Green", Array(HSLuv<Double>.greenGradient.prefix(opt.count))),
        ("Black", Array(HSLuv<Double>.blackGradient.prefix(opt.count))),
        ("White", Array(HSLuv<Double>.whiteGradient.prefix(opt.count))),
      ]
      ScrollView { VStack(alignment: .leading, spacing: 16) {
        ForEach(Array(blocks.enumerated()), id: \.0) { (_, group) in
          VStack(alignment: .leading, spacing: 8) {
            Text(group.title).font(.headline)
            GradientSwatch(colors: group.items.map { Color(hsluv: $0, opacity: 1.0) })
              .frame(height: 100)
          }
        }
      }.padding() }
    }
  }
}

// MARK: - Contrast gradient (blue)

struct ContrastBlueVariant: VisualVariant {
  let id = "contrast"
  let displayName = "Contrast Blue"
  let abstract = "Auto-spaced colors above min contrast"
  var iconSystemName: String? { "bolt.horizontal.circle" }
  func makeView() -> AnyView { AnyView(Body()) }

  private struct Body: View {
    @Environment(\.gradientOptions) private var opt
    @State private var minContrast: Double = 1.3
    var body: some View {
      VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 12) {
          Text("Min Contrast").font(.caption)
          Slider(value: $minContrast, in: 1.0...3.0)
          Text(String(format: "%.2f", minContrast)).font(.caption).foregroundStyle(.secondary)
        }
        let hColors = Array(HSLuv<Double>.blueGradient(minContrast: minContrast).prefix(opt.count))
        GradientSwatch(colors: hColors.map { Color(hsluv: $0, opacity: 1.0) })
          .frame(height: 140)
        Spacer()
      }
      .padding()
    }
  }
}
