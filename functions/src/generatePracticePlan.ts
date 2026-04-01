import * as functions from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import OpenAI from "openai";
import { MODEL } from "./config";

function getOpenAI(): OpenAI {
  return new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
}

interface GeneratePracticePlanRequest {
  userId: string;
  skillLevel: number;
  focusAreas: string[];
}

interface DrillSchema {
  name: string;
  description: string;
  durationMinutes: number;
  shotType: string;
  reps: number;
}

interface PracticeDaySchema {
  dayName: string;
  drills: DrillSchema[];
  totalMinutes: number;
}

interface PracticePlanSchema {
  summary: string;
  days: PracticeDaySchema[];
}

const practicePlanSchema = {
  type: "object",
  properties: {
    summary: { type: "string" },
    days: {
      type: "array",
      items: {
        type: "object",
        properties: {
          dayName: { type: "string" },
          drills: {
            type: "array",
            items: {
              type: "object",
              properties: {
                name: { type: "string" },
                description: { type: "string" },
                durationMinutes: { type: "number" },
                shotType: { type: "string" },
                reps: { type: "number" },
              },
              required: ["name", "description", "durationMinutes", "shotType", "reps"],
              additionalProperties: false,
            },
          },
          totalMinutes: { type: "number" },
        },
        required: ["dayName", "drills", "totalMinutes"],
        additionalProperties: false,
      },
    },
  },
  required: ["summary", "days"],
  additionalProperties: false,
};

export const generatePracticePlan = functions.onCall(
  { timeoutSeconds: 120, memory: "512MiB", secrets: ["OPENAI_API_KEY"] },
  async (request) => {
    const db = admin.firestore();
    const data = request.data as GeneratePracticePlanRequest;
    const { userId, skillLevel, focusAreas } = data;

    // Validate inputs
    if (!userId) {
      throw new functions.HttpsError("invalid-argument", "userId is required");
    }
    if (skillLevel < 2.0 || skillLevel > 5.0) {
      throw new functions.HttpsError("invalid-argument", "skillLevel must be between 2.0 and 5.0");
    }
    if (!focusAreas || focusAreas.length === 0) {
      throw new functions.HttpsError("invalid-argument", "focusAreas must not be empty");
    }

    // Read last 10 analyses
    const analysesSnapshot = await db
      .collection("users")
      .doc(userId)
      .collection("analyses")
      .orderBy("createdAt", "desc")
      .limit(10)
      .get();

    // Extract weak areas (score < 60)
    const weakAreas: string[] = [];
    for (const doc of analysesSnapshot.docs) {
      const analysisData = doc.data();
      const feedback = analysisData.feedback;
      if (!feedback) continue;
      const categories = ["grip", "stance", "swingPath", "followThrough", "footwork"];
      for (const category of categories) {
        const categoryData = feedback[category];
        if (categoryData && typeof categoryData.score === "number" && categoryData.score < 60) {
          if (!weakAreas.includes(category)) {
            weakAreas.push(category);
          }
        }
      }
    }

    const weakAreasText = weakAreas.length > 0
      ? weakAreas.join(", ")
      : "no specific weak areas identified";

    const sport = "pickleball";
    const prompt =
      `Create a 5-day practice plan for a ${skillLevel}-rated ${sport} player. ` +
      `Focus areas: ${focusAreas.join(", ")}. ` +
      `Based on recent analysis, weak areas include: ${weakAreasText}. ` +
      `Each day should have 3-4 drills.`;

    let planData: PracticePlanSchema;
    try {
      const openai = getOpenAI();
      const response = await openai.chat.completions.create({
        model: MODEL,
        messages: [
          {
            role: "system",
            content:
              `You are an expert ${sport} coach. Create detailed, actionable practice plans. ` +
              "Each drill should have a clear name, description, duration in minutes, a shot type (e.g. 'Dink', 'Drive', 'Drop', 'Serve', 'Volley', or 'General'), and rep count.",
          },
          {
            role: "user",
            content: prompt,
          },
        ],
        response_format: {
          type: "json_schema",
          json_schema: {
            name: "PracticePlan",
            strict: true,
            schema: practicePlanSchema,
          },
        },
        max_tokens: 2000,
      });

      const content = response.choices[0]?.message?.content;
      if (!content) {
        throw new Error("Empty response from OpenAI");
      }
      planData = JSON.parse(content) as PracticePlanSchema;
    } catch (err) {
      console.error("OpenAI error:", err);
      throw new functions.HttpsError("internal", "Failed to generate practice plan. Please try again.");
    }

    const weekOf = new Date().toISOString().split("T")[0];
    const createdAt = admin.firestore.Timestamp.now();

    const plan = {
      ...planData,
      skillLevel,
      weekOf,
      focusAreas,
      createdAt,
    };

    // Save to Firestore
    const docRef = await db
      .collection("users")
      .doc(userId)
      .collection("plans")
      .add(plan);

    return { id: docRef.id, ...plan };
  }
);
