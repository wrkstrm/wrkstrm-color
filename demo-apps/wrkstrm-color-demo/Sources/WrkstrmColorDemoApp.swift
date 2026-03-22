import SwiftUI

@main
struct WrkstrmColorDemoApp: App {
  init() { registerWrkstrmColorVariants() }
  var body: some Scene { WindowGroup { ColorDemoRootView() } }
}

