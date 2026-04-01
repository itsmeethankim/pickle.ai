import * as functions from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import OpenAI from "openai";
import { MAX_DAILY_ANALYSES, MODEL, MAX_FRAMES } from "./config";
import { getPromptForShotType } from "./prompts";

function getOpenAI(): OpenAI {
  return new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
}

interface AnalyzeSwingRequest {
  frames: string[];
  userId: string;
  videoDuration: number;
  shotType?: string;
}

interface CategoryFeedback {
  score: number;
  tips: string[];
  timestamp: number;
}

interface CoachingFeedback {
  isPickleball: boolean;
  overallScore: number;
  generalTips: string[];
  [category: string]: unknown;
}

export const analyzeSwing = functions.onCall(
  { timeoutSeconds: 120, memory: "512MiB", secrets: ["OPENAI_API_KEY"] },
  async (request) => {
    const db = admin.firestore();
    const data = request.data as AnalyzeSwingRequest;
    const { frames, userId, videoDuration, shotType } = data;

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

    const { systemPrompt, schema } = getPromptForShotType(shotType ?? null);

    let feedback: CoachingFeedback;
    try {
      const openai = getOpenAI();
      const response = await openai.chat.completions.create({
        model: MODEL,
        messages: [
          {
            role: "system",
            content: systemPrompt,
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
            schema: schema,
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
