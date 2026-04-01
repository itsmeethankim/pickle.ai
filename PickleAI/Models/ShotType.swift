import Foundation

enum ShotType: String, Codable, CaseIterable {
    case general
    case serve
    case `return`
    case thirdShotDrop
    case dink
    case drive
    case volley
    case lob
    case reset

    var displayName: String {
        switch self {
        case .general: return "General"
        case .serve: return "Serve"
        case .return: return "Return"
        case .thirdShotDrop: return "3rd Shot Drop"
        case .dink: return "Dink"
        case .drive: return "Drive"
        case .volley: return "Volley"
        case .lob: return "Lob"
        case .reset: return "Reset"
        }
    }

    var iconName: String {
        switch self {
        case .general: return "figure.stand"
        case .serve: return "arrow.up.forward.circle"
        case .return: return "arrow.uturn.backward.circle"
        case .thirdShotDrop: return "arrow.down.to.line"
        case .dink: return "hand.point.right"
        case .drive: return "bolt.fill"
        case .volley: return "hand.raised.fill"
        case .lob: return "arrow.up.circle"
        case .reset: return "arrow.counterclockwise.circle"
        }
    }

    var categories: [String] {
        switch self {
        case .general:
            return ["grip", "stance", "swingPath", "followThrough", "footwork"]
        case .serve:
            return ["toss", "contactPoint", "bodyRotation", "placement", "consistency"]
        case .return:
            return ["positioning", "contactPoint", "depth", "readyPosition", "splitStep"]
        case .thirdShotDrop:
            return ["arcControl", "softHands", "footPosition", "placement", "consistency"]
        case .dink:
            return ["softHands", "paddleAngle", "compactMotion", "placement", "readyPosition"]
        case .drive:
            return ["preparation", "contactPoint", "hipRotation", "followThrough", "targetSelection"]
        case .volley:
            return ["paddlePosition", "punchMotion", "footwork", "placement", "readyPosition"]
        case .lob:
            return ["disguise", "trajectory", "placement", "recovery", "timing"]
        case .reset:
            return ["softHands", "paddleAngle", "lowContact", "placement", "balance"]
        }
    }
}
