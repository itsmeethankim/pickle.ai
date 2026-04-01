import * as admin from "firebase-admin";

admin.initializeApp();

export { analyzeSwing } from "./analyzeSwing";
export { coachChat } from "./coachChat";
export { generatePracticePlan } from "./generatePracticePlan";
