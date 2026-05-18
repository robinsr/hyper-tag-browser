// Created on 2025-08-13 by robinsr

import Foundation

enum HelperLocationError: Error { case notFound }

/// Resolves the bundled ml-helper path (supports a few common locations).
func resolveHelperURL() throws -> URL {
    let bundle = Bundle.main.bundleURL

    // Preferred tidy location
    let helpers = bundle
        .appendingPathComponent("Contents")
        .appendingPathComponent("Library")
        .appendingPathComponent("Helpers")
        .appendingPathComponent("ml-helper")
    if FileManager.default.isExecutableFile(atPath: helpers.path) { return helpers }

    // Alongside main executable
    let macos = bundle
        .appendingPathComponent("Contents")
        .appendingPathComponent("MacOS")
        .appendingPathComponent("ml-helper")
    if FileManager.default.isExecutableFile(atPath: macos.path) { return macos }

    // Resources/Helpers
    if let res = Bundle.main.resourceURL?
        .appendingPathComponent("Helpers/ml-helper"),
       FileManager.default.isExecutableFile(atPath: res.path) { return res }

    throw HelperLocationError.notFound
}
