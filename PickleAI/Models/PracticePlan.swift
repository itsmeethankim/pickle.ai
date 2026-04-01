import Foundation
import FirebaseFirestore

struct Drill: Codable, Identifiable {
    var id: UUID
    var name: String
    var description: String
    var durationMinutes: Int
    var shotType: String?
    var reps: Int?
    var videoUrl: String?
    var videoTitle: String?
    var commonMistakes: [String]?
    var progressionTips: [String]?

    init(id: UUID = UUID(), name: String, description: String, durationMinutes: Int, shotType: String? = nil, reps: Int? = nil, videoUrl: String? = nil, videoTitle: String? = nil, commonMistakes: [String]? = nil, progressionTips: [String]? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.durationMinutes = durationMinutes
        self.shotType = shotType
        self.reps = reps
        self.videoUrl = videoUrl
        self.videoTitle = videoTitle
        self.commonMistakes = commonMistakes
        self.progressionTips = progressionTips
    }

    enum CodingKeys: String, CodingKey {
        case name, description, durationMinutes, shotType, reps
        case videoUrl, videoTitle, commonMistakes, progressionTips
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decode(String.self, forKey: .description)
        self.durationMinutes = try container.decode(Int.self, forKey: .durationMinutes)
        self.shotType = try container.decodeIfPresent(String.self, forKey: .shotType)
        self.reps = try container.decodeIfPresent(Int.self, forKey: .reps)
        self.videoUrl = try container.decodeIfPresent(String.self, forKey: .videoUrl)
        self.videoTitle = try container.decodeIfPresent(String.self, forKey: .videoTitle)
        self.commonMistakes = try container.decodeIfPresent([String].self, forKey: .commonMistakes)
        self.progressionTips = try container.decodeIfPresent([String].self, forKey: .progressionTips)
    }
}

struct PracticeDay: Codable, Identifiable {
    var id: UUID
    var dayName: String
    var drills: [Drill]
    var totalMinutes: Int

    init(id: UUID = UUID(), dayName: String, drills: [Drill], totalMinutes: Int) {
        self.id = id
        self.dayName = dayName
        self.drills = drills
        self.totalMinutes = totalMinutes
    }

    enum CodingKeys: String, CodingKey {
        case dayName, drills, totalMinutes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.dayName = try container.decode(String.self, forKey: .dayName)
        self.drills = try container.decode([Drill].self, forKey: .drills)
        self.totalMinutes = try container.decode(Int.self, forKey: .totalMinutes)
    }
}

struct PracticePlan: Codable, Identifiable {
    @DocumentID var id: String?
    var createdAt: Date
    var skillLevel: Double
    var weekOf: String
    var days: [PracticeDay]
    var focusAreas: [String]
    var summary: String
}
