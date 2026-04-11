import {
  collection,
  getDocs,
  doc,
  getDoc,
  query,
  where,
} from "firebase/firestore";
import { db } from "../firebase/firebase";

export interface StudentSummary {
  name: string;
  email: string;
  quizAttempts: number;
  avgQuizScore: number;
  pblSubmissions: number;
}

export interface QuizTrendPoint {
  date: string;
  score: number;
}

export interface WeakConceptMetric {
  concept: string;
  count: number;
}

export const getStudentSummary = async (
  studentId: string
): Promise<StudentSummary> => {
  // Student profile
  const studentSnap = await getDoc(
    doc(db, "students", studentId)
  );

  const student = studentSnap.data();

  // Quiz attempts
  const quizSnap = await getDocs(
    query(
      collection(db, "quiz_attempts"),
      where("studentId", "==", studentId)
    )
  );

  let totalScore = 0;
  let attempts = 0;

  quizSnap.forEach((doc) => {
    const q = doc.data();
    if (!q.total) return;
    totalScore += (q.score / q.total) * 100;
    attempts += 1;
  });

  // PBL submissions
  const pblSnap = await getDocs(
    collection(db, "students", studentId, "submittedPBL")
  );

  return {
    name: student?.name ?? "—",
    email: student?.email ?? "—",
    quizAttempts: attempts,
    avgQuizScore:
      attempts === 0
        ? 0
        : Math.round((totalScore / attempts) * 10) / 10,
    pblSubmissions: pblSnap.size,
  };
};

export const getStudentQuizTrend = async (
  studentId: string
): Promise<QuizTrendPoint[]> => {
  const snap = await getDocs(
    query(
      collection(db, "quiz_attempts"),
      where("studentId", "==", studentId)
    )
  );

  return snap.docs
    .map((doc) => {
      const q = doc.data();
      return {
        date: q.submittedAt
          ?.toDate()
          .toISOString()
          .slice(0, 10),
        score: Math.round((q.score / q.total) * 100),
      };
    })
    .filter((x) => x.date)
    .sort((a, b) => a.date.localeCompare(b.date));
};

export const getStudentWeakConcepts = async (
  studentId: string,
  limit = 8
): Promise<WeakConceptMetric[]> => {
  const snap = await getDocs(
    query(
      collection(db, "quiz_attempts"),
      where("studentId", "==", studentId)
    )
  );

  const countMap: Record<string, number> = {};

  snap.forEach((doc) => {
    const weak = doc.data().weakConcepts || [];
    weak.forEach((c: string) => {
      countMap[c] = (countMap[c] || 0) + 1;
    });
  });

  return Object.entries(countMap)
    .map(([concept, count]) => ({ concept, count }))
    .sort((a, b) => b.count - a.count)
    .slice(0, limit);
};
