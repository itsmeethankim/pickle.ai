import * as functions from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import OpenAI from "openai";
import { MAX_DAILY_ANALYSES, MODEL, MAX_FRAMES } from "./config";

function getOpenAI(): OpenAI {
  return new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
}

interface AnalyzeSwingRequest {
  frames: string[];
  userId: string;
  videoDuration: number;
}

interface CategoryFeedback {
  score: number;
  tips: string[];
  timestamp: number;
}

interface CoachingFeedback {
  isPickleball: boolean;
  overallScore: number;
  grip: CategoryFeedback;
  stance: CategoryFeedback;
  swingPath: CategoryFeedback;
  followThrough: CategoryFeedback;
  footwork: CategoryFeedback;
  generalTips: string[];
}

const feedbackSchema = {
  type: "object",
  properties: {
    isPickleball: { type: "boolean" },
    overallScore: { type: "number" },
    grip: {
      type: "object",
      properties: {
        score: { type: "number" },
        tips: { type: "array", items: { type: "string" } },
        timestamp: { type: "number" },
      },
      required: ["score", "tips", "timestamp"],
      additionalProperties: false,
    },
    stance: {
      type: "object",
      properties: {
        score: { type: "number" },
        tips: { type: "array", items: { type: "string" } },
        timestamp: { type: "number" },
      },
      required: ["score", "tips", "timestamp"],
      additionalProperties: false,
    },
    swingPath: {
      type: "object",
      properties: {
        score: { type: "number" },
        tips: { type: "array", items: { type: "string" } },
        timestamp: { type: "number" },
      },
      required: ["score", "tips", "timestamp"],
      additionalProperties: false,
    },
    followThrough: {
      type: "object",
      properties: {
        score: { type: "number" },
        tips: { type: "array", items: { type: "string" } },
        timestamp: { type: "number" },
      },
      required: ["score", "tips", "timestamp"],
      additionalProperties: false,
    },
    footwork: {
      type: "object",
      properties: {
        score: { type: "number" },
        tips: { type: "array", items: { type: "string" } },
        timestamp: { type: "number" },
      },
      required: ["score", "tips", "timestamp"],
      additionalProperties: false,
    },
    generalTips: { type: "array", items: { type: "string" } },
  },
  required: [
    "isPickleball",
    "overallScore",
    "grip",
    "stance",
    "swingPath",
    "followThrough",
    "footwork",
    "generalTips",
  ],
  additionalProperties: false,
};

export const analyzeSwing = functions.onCall(
  { timeoutSeconds: 120, memory: "512MiB", secrets: ["OPENAI_API_KEY"] },
  async (request) => {
    const db = admin.firestore();
    const data = request.data as AnalyzeSwingRequest;
    const { frames, userId, videoDuration } = data;

    if (!frames || !Array.isArray(frames) || frames.length === 0) {
      throw new functions.HttpsError("invalid-argument", "No frames provided");
    }

    if (!userId) {
      throw new functions.HttpsError("invalid-argument", "userId is required");
    }

    // Rate limiting
    const userRef = db.collection("users").doc(userId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      throw new functions.HttpsError("not-found", "User not found");
    }

    const userData = userDoc.data()!;
    const today = new Date().toISOString().split("T")[0];
    const lastAnalysisDate: string | null = userData.lastAnalysisDate ?? null;

    let dailyAnalysisCount: number =
      lastAnalysisDate === today ? (userData.dailyAnalysisCount ?? 0) : 0;

    if (dailyAnalysisCount >= MAX_DAILY_ANALYSES) {
      throw new functions.HttpsError(
        "resource-exhausted",
        `Daily analysis limit of ${MAX_DAILY_ANALYSES} reached. Try again tomorrow.`
      );
    }

    // Cap frames
    const framesToAnalyze = frames.slice(0, MAX_FRAMES);

    // Build OpenAI content
    const imageContent: OpenAI.Chat.ChatCompletionContentPart[] =
      framesToAnalyze.map((frame) => ({
        type: "image_url" as const,
        image_url: {
          url: `data:image/jpeg;base64,${frame}`,
          detail: "low" as const,
        },
      }));

    let feedback: CoachingFeedback;
    try {
      const openai = getOpenAI();
      const response = await openai.chat.completions.create({
        model: MODEL,
        messages: [
          {
            role: "system",
            content:
              "You are an expert pickleball coach. Analyze the player's form across the provided video frames. " +
              "Evaluate grip, stance, swing path, follow-through, and footwork. " +
              "First determine if the content is actually a pickleball match or practice session. " +
              "If it is not pickleball, set isPickleball to false and provide zero scores with empty tips. " +
              "Otherwise, provide detailed coaching feedback with scores (0-100) and actionable tips for each category. " +
              "Set timestamp to the approximate frame number where the observation was made.",
          },
          {
            role: "user",
            content: [
              {
                type: "text",
                text: `Analyze this pickleball swing. Video duration: ${videoDuration} seconds. ${framesToAnalyze.length} frames provided.`,
              },
              ...imageContent,
            ],
          },
        ],
        response_format: {
          type: "json_schema",
          json_schema: {
            name: "CoachingFeedback",
            strict: true,
            schema: feedbackSchema,
          },
        },
        max_tokens: 1500,
      });

      const content = response.choices[0]?.message?.content;
      if (!content) {
        throw new Error("Empty response from OpenAI");
      }
      feedback = JSON.parse(content) as CoachingFeedback;
    } catch (err) {
      console.error("OpenAI error:", err);
      throw new functions.HttpsError(
        "internal",
        "Failed to analyze swing. Please try again."
      );
    }

    if (!feedback.isPickleball) {
      throw new functions.HttpsError(
        "invalid-argument",
        "The video does not appear to contain pickleball content."
      );
    }

    // Update usage counts
    await userRef.update({
      analysisCount: admin.firestore.FieldValue.increment(1),
      dailyAnalysisCount: dailyAnalysisCount + 1,
      lastAnalysisDate: today,
    });

    return feedback;
  }
);
