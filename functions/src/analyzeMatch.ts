import * as functions from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import OpenAI from "openai";
import { MODEL, MAX_FRAMES } from "./config";

const MAX_DAILY_MATCH_ANALYSES = 2;

function getOpenAI(): OpenAI {
  return new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
}

interface AnalyzeMatchRequest {
  userId: string;
  frames: string[];
  videoDuration: number;
}

interface Segment {
  startTime: number;
  endTime: number;
  shotType: string;
  isKeyMoment: boolean;
}

interface CategoryFeedback {
  score: number;
  tips: string[];
  timestamp: number;
}

interface AnalyzedSegment extends Segment {
  score: number;
  feedback: {
    categories: {
      positioning: CategoryFeedback;
      technique: CategoryFeedback;
      strategy: CategoryFeedback;
    };
    generalTips: string[];
  };
}

interface MatchReport {
  overallScore: number;
  strengths: string[];
  weaknesses: string[];
  keyMoments: string[];
  recommendations: string[];
}

const categoryFeedbackSchema = {
  type: "object",
  properties: {
    score: { type: "number" },
    tips: { type: "array", items: { type: "string" } },
    timestamp: { type: "number" },
  },
  required: ["score", "tips", "timestamp"],
  additionalProperties: false,
};

export const analyzeMatch = functions.onCall(
  { timeoutSeconds: 180, memory: "512MiB", secrets: ["OPENAI_API_KEY"] },
  async (request) => {
    const db = admin.firestore();
    const data = request.data as AnalyzeMatchRequest;
    const { userId, frames, videoDuration } = data;

    if (!frames || !Array.isArray(frames) || frames.length === 0) {
      throw new functions.HttpsError("invalid-argument", "No frames provided");
    }
    if (!userId) {
      throw new functions.HttpsError("invalid-argument", "userId is required");
    }
    if (!videoDuration || videoDuration <= 0) {
      throw new functions.HttpsError("invalid-argument", "Valid videoDuration is required");
    }

    // Rate limiting
    const userRef = db.collection("users").doc(userId);
    const userDoc = await userRef.get();
    if (!userDoc.exists) {
      throw new functions.HttpsError("not-found", "User not found");
    }

    const userData = userDoc.data()!;
    const today = new Date().toISOString().split("T")[0];
    const lastMatchAnalysisDate: string | null = userData.lastMatchAnalysisDate ?? null;
    let dailyMatchAnalysisCount: number =
      lastMatchAnalysisDate === today ? (userData.dailyMatchAnalysisCount ?? 0) : 0;

    if (dailyMatchAnalysisCount >= MAX_DAILY_MATCH_ANALYSES) {
      throw new functions.HttpsError(
        "resource-exhausted",
        `Daily match analysis limit of ${MAX_DAILY_MATCH_ANALYSES} reached. Try again tomorrow.`
      );
    }

    const framesToAnalyze = frames.slice(0, MAX_FRAMES);
    const imageContent: OpenAI.Chat.ChatCompletionContentPart[] = framesToAnalyze.map((frame) => ({
      type: "image_url" as const,
      image_url: {
        url: `data:image/jpeg;base64,${frame}`,
        detail: "low" as const,
      },
    }));

    const openai = getOpenAI();

    // First call: segment the match into distinct rallies/plays
    let segments: Segment[];
    try {
      const segmentResponse = await openai.chat.completions.create({
        model: MODEL,
        messages: [
          {
            role: "system",
            content:
              "You are an expert pickleball coach analyzing a full match video. Identify distinct rally/play segments. For each segment provide start/end timestamps (in seconds), the primary shot type observed (one of: dink, drive, drop, volley, serve, return, lob, overhead, general), and whether it is a key moment worth highlighting.",
          },
          {
            role: "user",
            content: [
              {
                type: "text",
                text: `Analyze this pickleball match video. Duration: ${videoDuration} seconds. ${framesToAnalyze.length} frames provided at ~0.5fps. Identify all distinct rally/play segments.`,
              },
              ...imageContent,
            ],
          },
        ],
        response_format: {
          type: "json_schema",
          json_schema: {
            name: "MatchSegmentation",
            strict: true,
            schema: {
              type: "object",
              properties: {
                segments: {
                  type: "array",
                  items: {
                    type: "object",
                    properties: {
                      startTime: { type: "number" },
                      endTime: { type: "number" },
                      shotType: { type: "string" },
                      isKeyMoment: { type: "boolean" },
                    },
                    required: ["startTime", "endTime", "shotType", "isKeyMoment"],
                    additionalProperties: false,
                  },
                },
              },
              required: ["segments"],
              additionalProperties: false,
            },
          },
        },
        max_tokens: 1500,
      });

      const content = segmentResponse.choices[0]?.message?.content;
      if (!content) throw new Error("Empty segmentation response from OpenAI");
      segments = (JSON.parse(content) as { segments: Segment[] }).segments;
    } catch (err) {
      console.error("OpenAI segmentation error:", err);
      throw new functions.HttpsError("internal", "Failed to segment match video. Please try again.");
    }

    if (!segments || segments.length === 0) {
      segments = [{ startTime: 0, endTime: videoDuration, shotType: "general", isKeyMoment: false }];
    }

    // Second call: analyze quality per segment and produce overall match report
    let analyzedSegments: AnalyzedSegment[];
    let matchReport: MatchReport;
    try {
      const analysisResponse = await openai.chat.completions.create({
        model: MODEL,
        messages: [
          {
            role: "system",
            content: `You are an expert pickleball coach. You have identified ${segments.length} segments in a match video. Provide quality scores (0-100) and coaching feedback for each segment, plus an overall match report.`,
          },
          {
            role: "user",
            content: [
              {
                type: "text",
                text: `Segments: ${JSON.stringify(segments)}. Video duration: ${videoDuration}s. Analyze quality for each segment and provide an overall match report.`,
              },
              ...imageContent,
            ],
          },
        ],
        response_format: {
          type: "json_schema",
          json_schema: {
            name: "MatchAnalysis",
            strict: true,
            schema: {
              type: "object",
              properties: {
                segments: {
                  type: "array",
                  items: {
                    type: "object",
                    properties: {
                      startTime: { type: "number" },
                      endTime: { type: "number" },
                      shotType: { type: "string" },
                      score: { type: "number" },
                      feedback: {
                        type: "object",
                        properties: {
                          categories: {
                            type: "object",
                            properties: {
                              positioning: categoryFeedbackSchema,
                              technique: categoryFeedbackSchema,
                              strategy: categoryFeedbackSchema,
                            },
                            required: ["positioning", "technique", "strategy"],
                            additionalProperties: false,
                          },
                          generalTips: { type: "array", items: { type: "string" } },
                        },
                        required: ["categories", "generalTips"],
                        additionalProperties: false,
                      },
                      isKeyMoment: { type: "boolean" },
                    },
                    required: ["startTime", "endTime", "shotType", "score", "feedback", "isKeyMoment"],
                    additionalProperties: false,
                  },
                },
                matchReport: {
                  type: "object",
                  properties: {
                    overallScore: { type: "number" },
                    strengths: { type: "array", items: { type: "string" } },
                    weaknesses: { type: "array", items: { type: "string" } },
                    keyMoments: { type: "array", items: { type: "string" } },
                    recommendations: { type: "array", items: { type: "string" } },
                  },
                  required: ["overallScore", "strengths", "weaknesses", "keyMoments", "recommendations"],
                  additionalProperties: false,
                },
              },
              required: ["segments", "matchReport"],
              additionalProperties: false,
            },
          },
        },
        max_tokens: 2500,
      });

      const content = analysisResponse.choices[0]?.message?.content;
      if (!content) throw new Error("Empty analysis response from OpenAI");
      const parsed = JSON.parse(content) as { segments: AnalyzedSegment[]; matchReport: MatchReport };
      analyzedSegments = parsed.segments;
      matchReport = parsed.matchReport;
    } catch (err) {
      console.error("OpenAI analysis error:", err);
      throw new functions.HttpsError("internal", "Failed to analyze match. Please try again.");
    }

    // Update usage counts
    await userRef.update({
      matchAnalysisCount: admin.firestore.FieldValue.increment(1),
      dailyMatchAnalysisCount: dailyMatchAnalysisCount + 1,
      lastMatchAnalysisDate: today,
    });

    // Save to Firestore
    await db.collection("users").doc(userId).collection("matchAnalyses").add({
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      segments: analyzedSegments,
      matchReport,
      videoDuration,
      frameCount: framesToAnalyze.length,
    });

    return { segments: analyzedSegments, matchReport };
  }
);
