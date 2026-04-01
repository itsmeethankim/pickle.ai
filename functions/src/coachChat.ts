import * as functions from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import OpenAI from "openai";
import { MODEL } from "./config";

const MAX_DAILY_CHATS = 20;

function getOpenAI(): OpenAI {
  return new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
}

interface CoachChatRequest {
  conversationId: string;
  message: string;
  userId: string;
}

export const coachChat = functions.onCall(
  { timeoutSeconds: 60, memory: "256MiB", secrets: ["OPENAI_API_KEY"] },
  async (request) => {
    const db = admin.firestore();
    const data = request.data as CoachChatRequest;
    const { message, userId } = data;
    let { conversationId } = data;

    if (!message || typeof message !== "string" || message.trim() === "") {
      throw new functions.HttpsError("invalid-argument", "message is required");
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
    const lastChatDate: string | null = userData.lastChatDate ?? null;

    let dailyChatCount: number =
      lastChatDate === today ? (userData.dailyChatCount ?? 0) : 0;

    if (dailyChatCount >= MAX_DAILY_CHATS) {
      throw new functions.HttpsError(
        "resource-exhausted",
        `Daily chat limit of ${MAX_DAILY_CHATS} reached. Try again tomorrow.`
      );
    }

    const now = admin.firestore.Timestamp.now();

    // Create conversation if none provided
    if (!conversationId) {
      const title = message.trim().slice(0, 50);
      const convRef = await db
        .collection("users")
        .doc(userId)
        .collection("conversations")
        .add({ title, createdAt: now, lastMessageAt: now });
      conversationId = convRef.id;
    }

    const messagesRef = db
      .collection("users")
      .doc(userId)
      .collection("conversations")
      .doc(conversationId)
      .collection("messages");

    // Save user message
    await messagesRef.add({ role: "user", content: message.trim(), createdAt: now });

    // Load last 20 messages for context
    const historySnap = await messagesRef
      .orderBy("createdAt")
      .limitToLast(20)
      .get();

    const history: OpenAI.Chat.ChatCompletionMessageParam[] = historySnap.docs.map(
      (doc) => {
        const d = doc.data();
        return {
          role: d.role as "user" | "assistant",
          content: d.content as string,
        };
      }
    );

    // Call OpenAI
    let responseText: string;
    try {
      const openai = getOpenAI();
      const response = await openai.chat.completions.create({
        model: MODEL,
        messages: [
          {
            role: "system",
            content:
              "You are an expert pickleball coach. You are knowledgeable about strategy, technique, rules, drills, and equipment. " +
              "Give practical, actionable advice. Be encouraging but honest.",
          },
          ...history,
        ],
        max_tokens: 800,
      });

      responseText = response.choices[0]?.message?.content ?? "";
      if (!responseText) {
        throw new Error("Empty response from OpenAI");
      }
    } catch (err) {
      console.error("OpenAI error:", err);
      throw new functions.HttpsError(
        "internal",
        "Failed to get coaching response. Please try again."
      );
    }

    // Save assistant message
    const assistantTimestamp = admin.firestore.Timestamp.now();
    const assistantRef = await messagesRef.add({
      role: "assistant",
      content: responseText,
      createdAt: assistantTimestamp,
    });

    // Update conversation lastMessageAt
    await db
      .collection("users")
      .doc(userId)
      .collection("conversations")
      .doc(conversationId)
      .update({ lastMessageAt: assistantTimestamp });

    // Update user usage counts
    await userRef.update({
      dailyChatCount: dailyChatCount + 1,
      lastChatDate: today,
    });

    return {
      id: assistantRef.id,
      role: "assistant",
      content: responseText,
      createdAt: assistantTimestamp,
      conversationId,
    };
  }
);
