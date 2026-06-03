//
//  Clean_TimesTests.swift
//  Clean TimesTests
//
//  Created by Pavel Arkharov on 1.6.2026.
//

import Testing
@testable import Clean_Times

@MainActor
struct Clean_TimesTests {

    @Test func samplePrincipleCollapsedLabelMatchesPlan() {
        let entry = PrincipleEntry.sample

        #expect("\(entry.displayDate) -- \(entry.keyword)" == "May 9 -- Love")
    }

}
