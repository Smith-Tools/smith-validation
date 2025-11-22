import Foundation

// Test file with various violations for the new rule builder API

class UserViewController {  // Should end with "ViewController" - wait, it does! This is good
    let name: String
    let email: String
    let age: Int
    let address: String
    let phone: String
    let city: String
    let state: String
    let zip: String
    let country: String
    let avatar: String
    let bio: String
    let website: String
    let twitter: String
    let linkedin: String
    let github: String    // This should trigger "Too Many Properties" rule (16 > 15)
    let extra1: String    // This is 17 properties
    let extra2: String    // This is 18 properties
    
    // Complex function that should trigger complexity rule
    func processComplexUserUpdate(data: [String: Any]) -> Bool {
        var result = false
        
        if data["name"] != nil {
            if let name = data["name"] as? String {
                if name.count > 0 {
                    for char in name {
                        if char.isLetter {
                            switch char.lowercased() {
                            case "a", "e", "i", "o", "u":
                                continue
                            default:
                                if char.isNumber {
                                    return false
                                }
                            }
                        }
                    }
                    result = true
                }
            }
        }
        
        guard let email = data["email"] as? String else { return false }
        if email.contains("@") {
            for part in email.components(separatedBy: "@") {
                if part.isEmpty {
                    return false
                }
            }
        }
        
        return result
    }
    
    // Async function without error handling - should trigger async error handling rule
    func fetchUserData() {
        Task {
            let data = await loadFromNetwork()  // No error handling!
            processData(data)
        }
    }
    
    private func loadFromNetwork() async -> Data {
        return Data()
    }
    
    private func processData(_ data: Data) {
        // Process data
    }
}

class BadController {  // Missing "ViewController" suffix
    func doSomething() {
        print("doing something")
    }
}

struct UserState {  // TCA State with too many properties
    let isLoading: Bool
    let name: String
    let email: String
    let age: Int
    let address: String
    let phone: String
    let city: String
    let state: String
    let zip: String
    let country: String
    let avatar: String
    let bio: String
    let website: String
    let twitter: String
    let linkedin: String
    let github: String
    let extra1: String
    let extra2: String
}
