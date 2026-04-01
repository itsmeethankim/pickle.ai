function categorySchema() {
  return {
    type: "object",
    properties: {
      score: { type: "number" },
      tips: { type: "array", items: { type: "string" } },
      timestamp: { type: "number" },
    },
    required: ["score", "tips", "timestamp"],
    additionalProperties: false,
  };
}

function buildSchema(categories: string[]): Record<string, unknown> {
  const properties: Record<string, unknown> = {
    isPickleball: { type: "boolean" },
    overallScore: { type: "number" },
    generalTips: { type: "array", items: { type: "string" } },
  };
  for (const cat of categories) {
    properties[cat] = categorySchema();
  }
  return {
    type: "object",
    properties,
    required: ["isPickleball", "overallScore", "generalTips", ...categories],
    additionalProperties: false,
  };
}

export function getPromptForShotType(
  shotType: string | null
): { systemPrompt: string; schema: Record<string, unknown> } {
  switch (shotType) {
    case "serve":
      return {
        systemPrompt:
          "You are an expert pickleball coach. Analyze the player's serve technique across the provided video frames. " +
          "Evaluate toss consistency, contact point, body rotation, placement, and overall consistency. " +
          "First determine if the content is actually a pickleball match or practice session. " +
          "If it is not pickleball, set isPickleball to false and provide zero scores with empty tips. " +
          "Otherwise, provide detailed coaching feedback with scores (0-100) and actionable tips for each category. " +
          "Set timestamp to the approximate frame number where the observation was made.",
        schema: buildSchema(["toss", "contactPoint", "bodyRotation", "placement", "consistency"]),
      };

    case "return":
      return {
        systemPrompt:
          "You are an expert pickleball coach. Analyze the player's return of serve across the provided video frames. " +
          "Evaluate court positioning, contact point, return depth, ready position, and split step timing. " +
          "First determine if the content is actually a pickleball match or practice session. " +
          "If it is not pickleball, set isPickleball to false and provide zero scores with empty tips. " +
          "Otherwise, provide detailed coaching feedback with scores (0-100) and actionable tips for each category. " +
          "Set timestamp to the approximate frame number where the observation was made.",
        schema: buildSchema(["positioning", "contactPoint", "depth", "readyPosition", "splitStep"]),
      };

    case "thirdShotDrop":
      return {
        systemPrompt:
          "You are an expert pickleball coach. Analyze the player's third shot drop across the provided video frames. " +
          "Evaluate arc control, soft hands, foot position, placement accuracy, and consistency. " +
          "First determine if the content is actually a pickleball match or practice session. " +
          "If it is not pickleball, set isPickleball to false and provide zero scores with empty tips. " +
          "Otherwise, provide detailed coaching feedback with scores (0-100) and actionable tips for each category. " +
          "Set timestamp to the approximate frame number where the observation was made.",
        schema: buildSchema(["arcControl", "softHands", "footPosition", "placement", "consistency"]),
      };

    case "dink":
      return {
        systemPrompt:
          "You are an expert pickleball coach. Analyze the player's dinking technique across the provided video frames. " +
          "Evaluate soft hands, paddle angle, compact motion, placement, and ready position between shots. " +
          "First determine if the content is actually a pickleball match or practice session. " +
          "If it is not pickleball, set isPickleball to false and provide zero scores with empty tips. " +
          "Otherwise, provide detailed coaching feedback with scores (0-100) and actionable tips for each category. " +
          "Set timestamp to the approximate frame number where the observation was made.",
        schema: buildSchema(["softHands", "paddleAngle", "compactMotion", "placement", "readyPosition"]),
      };

    case "drive":
      return {
        systemPrompt:
          "You are an expert pickleball coach. Analyze the player's drive shot across the provided video frames. " +
          "Evaluate preparation and backswing, contact point, hip rotation, follow-through, and target selection. " +
          "First determine if the content is actually a pickleball match or practice session. " +
          "If it is not pickleball, set isPickleball to false and provide zero scores with empty tips. " +
          "Otherwise, provide detailed coaching feedback with scores (0-100) and actionable tips for each category. " +
          "Set timestamp to the approximate frame number where the observation was made.",
        schema: buildSchema(["preparation", "contactPoint", "hipRotation", "followThrough", "targetSelection"]),
      };

    case "volley":
      return {
        systemPrompt:
          "You are an expert pickleball coach. Analyze the player's volley technique across the provided video frames. " +
          "Evaluate paddle position at ready, punch motion, footwork, placement, and recovery to ready position. " +
          "First determine if the content is actually a pickleball match or practice session. " +
          "If it is not pickleball, set isPickleball to false and provide zero scores with empty tips. " +
          "Otherwise, provide detailed coaching feedback with scores (0-100) and actionable tips for each category. " +
          "Set timestamp to the approximate frame number where the observation was made.",
        schema: buildSchema(["paddlePosition", "punchMotion", "footwork", "placement", "readyPosition"]),
      };

    case "lob":
      return {
        systemPrompt:
          "You are an expert pickleball coach. Analyze the player's lob shot across the provided video frames. " +
          "Evaluate disguise of intent, trajectory arc, placement, recovery after the shot, and timing. " +
          "First determine if the content is actually a pickleball match or practice session. " +
          "If it is not pickleball, set isPickleball to false and provide zero scores with empty tips. " +
          "Otherwise, provide detailed coaching feedback with scores (0-100) and actionable tips for each category. " +
          "Set timestamp to the approximate frame number where the observation was made.",
        schema: buildSchema(["disguise", "trajectory", "placement", "recovery", "timing"]),
      };

    case "reset":
      return {
        systemPrompt:
          "You are an expert pickleball coach. Analyze the player's reset shot across the provided video frames. " +
          "Evaluate soft hands, paddle angle, low contact point, placement into the kitchen, and balance. " +
          "First determine if the content is actually a pickleball match or practice session. " +
          "If it is not pickleball, set isPickleball to false and provide zero scores with empty tips. " +
          "Otherwise, provide detailed coaching feedback with scores (0-100) and actionable tips for each category. " +
          "Set timestamp to the approximate frame number where the observation was made.",
        schema: buildSchema(["softHands", "paddleAngle", "lowContact", "placement", "balance"]),
      };

    case "general":
    default:
      return {
        systemPrompt:
          "You are an expert pickleball coach. Analyze the player's form across the provided video frames. " +
          "Evaluate grip, stance, swing path, follow-through, and footwork. " +
          "First determine if the content is actually a pickleball match or practice session. " +
          "If it is not pickleball, set isPickleball to false and provide zero scores with empty tips. " +
          "Otherwise, provide detailed coaching feedback with scores (0-100) and actionable tips for each category. " +
          "Set timestamp to the approximate frame number where the observation was made.",
        schema: buildSchema(["grip", "stance", "swingPath", "followThrough", "footwork"]),
      };
  }
}
