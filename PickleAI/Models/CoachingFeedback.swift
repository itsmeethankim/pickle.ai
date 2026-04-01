import Foundation

struct CoachingFeedback: Codable {
    var categories: [String: CategoryFeedback]
    var generalTips: [String]

    var allCategories: [(name: String, feedback: CategoryFeedback)] {
        categories.map { key, feedback in
            (name: camelCaseToDisplayName(key), feedback: feedback)
        }.sorted { $0.name < $1.name }
    }

    init(categories: [String: CategoryFeedback], generalTips: [String]) {
        self.categories = categories
        self.generalTips = generalTips
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)

        // Try new format: {categories: {...}, generalTips: [...]}
        if let categoriesKey = DynamicCodingKeys(stringValue: "categories"),
           container.contains(categoriesKey) {
            categories = try container.decode([String: CategoryFeedback].self, forKey: categoriesKey)
        } else {
            // Backward compat: read old flat keys
            var cats: [String: CategoryFeedback] = [:]
            for key in ["grip", "stance", "swingPath", "followThrough", "footwork"] {
                if let codingKey = DynamicCodingKeys(stringValue: key),
                   container.contains(codingKey) {
                    cats[key] = try container.decode(CategoryFeedback.self, forKey: codingKey)
                }
            }
            categories = cats
        }

        if let generalTipsKey = DynamicCodingKeys(stringValue: "generalTips"),
           container.contains(generalTipsKey) {
            generalTips = try container.decode([String].self, forKey: generalTipsKey)
        } else {
            generalTips = []
        }
    }

    private func camelCaseToDisplayName(_ key: String) -> String {
        var result = ""
        for (i, char) in key.enumerated() {
            if char.isUppercase && i > 0 {
                result += " "
            }
            result += i == 0 ? String(char).uppercased() : String(char)
        }
        return result
    }
}

private struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { nil }
}

struct CategoryFeedback: Codable {
    var score: Int
    var tips: [String]
    var timestamp: Double
}
