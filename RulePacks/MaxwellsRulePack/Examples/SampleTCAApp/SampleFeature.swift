// Examples/SampleTCAApp/SampleFeature.swift
// Sample TCA feature demonstrating the compiler plugin in action

import Foundation
import MaxwellsTCARulesPlugin

// This will pass validation - 3 properties (< 15 threshold)
@TCAValidation
struct GoodFeatureState: ObservableState {
    var isLoading: Bool = false
    var userName: String = ""
    var itemCount: Int = 0
}

// This will trigger Rule 1.1 violation - 20 properties (> 15 threshold)
@TCAValidation
struct MonolithicFeatureState: ObservableState {
    var isLoading: Bool = false
    var userName: String = ""
    var userEmail: String = ""
    var userAge: Int = 0
    var userLocation: String = ""
    var userProfileURL: URL?
    var userPreferences: [String] = []
    var userSettings: [String: Any] = [:]
    var navigationPath: [String] = []
    var searchQuery: String = ""
    var searchResults: [String] = []
    var selectedCategory: String?
    var filterOptions: [String] = []
    var sortBy: String = "name"
    var sortOrder: String = "asc"
    var pageNumber: Int = 1
    var pageSize: Int = 20
    var totalCount: Int = 0
    var lastUpdated: Date = Date()
}
