import Foundation

// Override SPM's auto-generated Bundle.module to also check Contents/Resources/
// inside the .app bundle. The SPM accessor only looks at the bundle root and
// the hardcoded build path, which fails for distributed .app bundles.
extension Foundation.Bundle {
    static let klickResources: Bundle = {
        // 1. SPM development build path (next to executable)
        let mainPath = Bundle.main.bundleURL.appendingPathComponent("Klick_Klick.bundle").path
        if let bundle = Bundle(path: mainPath) {
            return bundle
        }

        // 2. Inside Contents/Resources/ (.app bundle)
        if let resourceURL = Bundle.main.resourceURL {
            let appPath = resourceURL.appendingPathComponent("Klick_Klick.bundle").path
            if let bundle = Bundle(path: appPath) {
                return bundle
            }
        }

        // 3. Fallback to main bundle itself
        return Bundle.main
    }()
}
