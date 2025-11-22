import Testing
import Foundation

@Suite("Standalone Swift Testing Raw Output")
struct StandRawTests {

    @Test("Basic success test")
    func basicSuccess() async throws {
        #expect(1 + 1 == 2, "Math should work")
    }

    @Test("Basic failure test - demonstrates raw failure output")
    func basicFailure() async throws {
        #expect(1 + 1 == 3, "This will fail to show raw Swift Testing failure format")
    }

    @Test("TCA error handling analysis")
    func tcaErrorHandling() async throws {
        let tcaWithoutError = """
        @Reducer
        struct BadFeature {
            struct State { var items: [String] = [] }
            enum Action {
                case loadItems
                case itemsLoaded([String])
                // No error handling
            }
        }
        """

        let hasErrorHandling = tcaWithoutError.contains("error") || tcaWithoutError.contains("failure")
        #expect(hasErrorHandling == false, "TCA without error handling should be detected")
    }

    @Test("Monolithic feature detection")
    func monolithicFeature() async throws {
        let monolithicTCA = """
        @Reducer
        struct MonolithicFeature {
            struct State {
                var data1: String
                var data2: String
                var data3: String
                var data4: String
                var data5: String
                var data6: String
                var data7: String
                var data8: String
                var data9: String
                var data10: String
                var data11: String
                var data12: String
                var data13: String
                var data14: String
                var data15: String
                var data16: String  // Too many properties
            }
        }
        """

        let lines = monolithicTCA.components(separatedBy: .newlines)
        let propertyCount = lines.filter { $0.trimmingCharacters(in: .whitespaces).hasPrefix("var ") }.count
        #expect(propertyCount > 15, "Should detect monolithic feature with \(propertyCount) properties")
    }

    @Test("String validation test")
    func stringValidation() async throws {
        let testString = "This is a test"
        #expect(testString.contains("test"), "String should contain substring")
        #expect(testString.contains("notthere") == false, "String should not contain missing substring")
    }
}
