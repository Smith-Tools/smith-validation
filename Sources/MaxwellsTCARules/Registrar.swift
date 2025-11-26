import Foundation
import SmithValidationCore

/// Registrar for Maxwells TCA rules (static-linked pack).
public func registerMaxwellsRules() -> [any ValidatableRule] {
    return [
        TCARule_1_1_MonolithicFeatures(),
        TCARule_1_2_ProperDependencyInjection(),
        TCARule_1_3_CodeDuplication(),
        TCARule_1_4_UnclearOrganization(),
        TCARule_1_5_TightlyCoupledState()
    ]
}
