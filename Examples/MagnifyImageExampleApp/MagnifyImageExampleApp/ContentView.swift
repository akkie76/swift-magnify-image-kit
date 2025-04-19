//
//  ContentView.swift
//  MagnifyImageExampleApp
//
//  Created by Akihiko Sato on 2025/04/19.
//

import SwiftUI
import MagnifyImageKit

struct ContentView: View {
  var body: some View {
    VStack {
      if let image = UIImage(named: "CherryBlossoms") {
        MagnifyImageView(image: image)
          .ignoresSafeArea()
      }
    }
  }
}

#Preview {
  ContentView()
}
