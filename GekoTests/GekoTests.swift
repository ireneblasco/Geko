//
//  GekoTests.swift
//  GekoTests
//
//  Created by Irenews on 9/19/25.
//

import SwiftUI
import Testing
import ViewInspector
@testable import Geko

struct GekoTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

    @Test @MainActor func viewInspectorInspectsText() throws {
        let view = Text("Hello, Geko!")
        let string = try view.inspect().implicitAnyView().text().string()
        #expect(string == "Hello, Geko!")
    }

}
