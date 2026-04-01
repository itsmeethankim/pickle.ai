import Foundation
import FirebaseFirestore

struct Drill: Codable, Identifiable {
    var id: UUID
    var name: String
    var description: String
    var durationMinutes: Int
    var shotType: String?
    var reps: Int?

    init(id: UUID = UUID(), name: String, description: String, durationMinutes: Int, shotType: String? = nil, reps: Int? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.durationMinutes = durationMinutes
        self.shotType = shotType
        self.reps = reps
    }

    enum CodingKeys: String, CodingKey {
        case name, description, durationMinutes, shotType, reps
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decode(String.self, forKey: .description)
        self.durationMinutes = try container.decode(Int.self, forKey: .durationMinutes)
        self.shotType = try container.decodeIfPresent(String.self, forKey: .shotType)
        self.reps = try container.decodeIfPresent(Int.self, forKey: .reps)
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
