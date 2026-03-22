import SwiftUI
import AppKit
import VariantKit

// MARK: - Utilities

private extension Color {
  init(hex: String) {
    var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    if s.hasPrefix("#") { s.removeFirst() }
    var value: UInt64 = 0
    Scanner(string: s).scanHexInt64(&value)
    let r, g, b: Double
    switch s.count {
    case 6:
      r = Double((value & 0xFF0000) >> 16) / 255
      g = Double((value & 0x00FF00) >> 8) / 255
      b = Double(value & 0x0000FF) / 255
    default:
      r = 1; g = 1; b = 1
    }
    self = Color(red: r, green: g, blue: b)
  }
}

private extension Color {
  var luminance: Double {
    // sRGB relative luminance
    let comps = NSColor(self).usingColorSpace(.sRGB) ?? NSColor.white
    func toLinear(_ c: CGFloat) -> Double {
      let v = Double(c)
      return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
    }
    let r = toLinear(comps.redComponent)
    let g = toLinear(comps.greenComponent)
    let b = toLinear(comps.blueComponent)
    return 0.2126*r + 0.7152*g + 0.0722*b
  }
  func contrastRatio(against other: Color) -> Double {
    let L1 = max(luminance, other.luminance) + 0.05
    let L2 = min(luminance, other.luminance) + 0.05
    return L1 / L2
  }
}

// MARK: - Families

private struct Family {
  let name: String
  let bg: Color
  let surface: Color
  let surfaceAlt: Color
  let text: Color
  let textSecondary: Color
  let stroke: Color
  let accent1: Color
  let accent2: Color
  let grid: Color
}

private enum Families {
  static let hyperspace = Family(
    name: "Hyperspace",
    bg: Color(hex: "#05060A"),
    surface: Color(hex: "#121426"),
    surfaceAlt: Color(hex: "#1A1E34"),
    text: Color(hex: "#EAF2FF"),
    textSecondary: Color(hex: "#8EA1C7"),
    stroke: Color(hex: "#4D5F9A"),
    accent1: Color(hex: "#00FFD1"),
    accent2: Color(hex: "#FF4D97"),
    grid: Color(hex: "#C6CFEB").opacity(0.12)
  )
  static let nebula = Family(
    name: "Nebula",
    bg: Color(hex: "#0A0712"),
    surface: Color(hex: "#161326"),
    surfaceAlt: Color(hex: "#221B3A"),
    text: Color(hex: "#F3ECFF"),
    textSecondary: Color(hex: "#B8A7E6"),
    stroke: Color(hex: "#5A4F86"),
    accent1: Color(hex: "#A674FF"),
    accent2: Color(hex: "#FF4DB6"),
    grid: Color(hex: "#B7A8E9").opacity(0.12)
  )
  static let beskar = Family(
    name: "Beskar",
    bg: Color(hex: "#0C0D10"),
    surface: Color(hex: "#1C2030"),
    surfaceAlt: Color(hex: "#262C3F"),
    text: Color(hex: "#ECEEF5"),
    textSecondary: Color(hex: "#A3ABBD"),
    stroke: Color(hex: "#4F596F"),
    accent1: Color(hex: "#FFC14D"),
    accent2: Color(hex: "#FF5A3C"),
    grid: Color(hex: "#BEC8DC").opacity(0.12)
  )
}

// MARK: - Variants

struct PaletteShowcaseVariant: VisualVariant {
  let id = "showcase"
  let displayName = "Palette Showcase"
  let abstract = "Tokens + components for ADA's SPACE design language"
  var iconSystemName: String? { "sparkles" }
  func makeView() -> AnyView { AnyView(Body()) }

  private struct Body: View {
    @State private var familyIndex = 0
    private let families: [Family] = [Families.hyperspace, Families.nebula, Families.beskar]

    var body: some View {
      let fam = families[familyIndex]
      VStack(spacing: 16) {
        header(fam)
        tokens(fam)
        components(fam)
      }
      .padding()
      .background(fam.bg)
    }

    private func header(_ f: Family) -> some View {
      HStack {
        Picker("Family", selection: $familyIndex) {
          ForEach(Array(families.enumerated()), id: \.0) { (i, f) in Text(f.name).tag(i) }
        }
        .pickerStyle(.segmented)
        Spacer()
      }
    }

    private func tokenTile(_ name: String, _ color: Color, _ border: Color? = nil) -> some View {
      VStack(alignment: .leading, spacing: 6) {
        Rectangle().fill(color)
          .overlay { if let b = border { Rectangle().stroke(b.opacity(0.6), lineWidth: 1) } }
          .clipShape(RoundedRectangle(cornerRadius: 8))
          .frame(height: 52)
        Text(name).font(.caption).foregroundStyle(.secondary)
      }
    }

    private func tokens(_ f: Family) -> some View {
      VStack(alignment: .leading, spacing: 8) {
        Text("Tokens").font(.headline).foregroundStyle(f.text)
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], spacing: 12) {
          tokenTile("bg", f.bg)
          tokenTile("surface", f.surface, f.stroke)
          tokenTile("surface-alt", f.surfaceAlt, f.stroke)
          tokenTile("text", f.text)
          tokenTile("text-secondary", f.textSecondary)
          tokenTile("stroke", f.stroke)
          tokenTile("accent1", f.accent1)
          tokenTile("accent2", f.accent2)
        }
      }
    }

    private func components(_ f: Family) -> some View {
      VStack(alignment: .leading, spacing: 12) {
        Text("Components").font(.headline).foregroundStyle(f.text)
        HStack(spacing: 16) {
          // HUD line
          Rectangle().fill(Color.clear)
            .overlay(Rectangle().stroke(f.stroke, lineWidth: 1))
            .shadow(color: f.accent1.opacity(0.28), radius: 8)
            .frame(width: 200, height: 36)
            .background(f.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
          // Accent button
          Button("Engage") {}
            .buttonStyle(AccentButtonStyle(f))
        }
        // Chart sample (bar)
        HStack(spacing: 6) {
          ForEach(0..<8, id: \.self) { i in
            RoundedRectangle(cornerRadius: 3)
              .fill(f.accent1.opacity(0.7 - Double(i) * 0.06))
              .frame(width: 16, height: CGFloat(20 + i*10))
          }
        }
        .padding(12)
        .background(f.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(f.stroke.opacity(0.6)))
      }
      .foregroundStyle(f.text)
    }
  }
}

private struct AccentButtonStyle: ButtonStyle {
  let f: Family
  init(_ f: Family) { self.f = f }
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding(.horizontal, 16).padding(.vertical, 10)
      .background(
        LinearGradient(colors: [
          f.accent1.opacity(configuration.isPressed ? 0.75 : 0.95),
          Color.white.opacity(configuration.isPressed ? 0.05 : 0.15)
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
      )
      .overlay(RoundedRectangle(cornerRadius: 12).stroke(f.stroke, lineWidth: 1))
      .cornerRadius(12)
      .shadow(color: f.accent1.opacity(0.28), radius: 10, y: 1)
      .foregroundStyle(f.text)
  }
}

// MARK: - Contrast audit

struct ContrastAuditVariant: VisualVariant {
  let id = "contrast-audit"
  let displayName = "Contrast Audit"
  let abstract = "Check text vs surface tokens (AA target)"
  var iconSystemName: String? { "eye" }
  func makeView() -> AnyView { AnyView(Body()) }

  private struct Body: View {
    private let fam = Families.hyperspace
    private let pairs: [(String, Color, Color)]
    init() {
      pairs = [
        ("text/surface", fam.text, fam.surface),
        ("text/surface-alt", fam.text, fam.surfaceAlt),
        ("text-secondary/surface", fam.textSecondary, fam.surface),
        ("accent1/surface", fam.accent1, fam.surface),
        ("accent2/surface", fam.accent2, fam.surface)
      ]
    }
    var body: some View {
      VStack(alignment: .leading, spacing: 12) {
        ForEach(Array(pairs.enumerated()), id: \.0) { (_, p) in
          let ratio = p.1.contrastRatio(against: p.2)
          HStack {
            RoundedRectangle(cornerRadius: 8)
              .fill(p.2)
              .frame(width: 220, height: 40)
              .overlay(Text("Aa Sample").foregroundStyle(p.1))
            Text(String(format: "%.2f:1", ratio))
              .foregroundStyle(ratio >= 4.5 ? Color.green : Color.yellow)
          }
        }
        Spacer()
      }
      .padding()
      .background(fam.bg)
    }
  }
}
