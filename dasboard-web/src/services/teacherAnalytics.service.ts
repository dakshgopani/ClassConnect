import {
  collection,
  getDocs,
  query,
  where,
} from "firebase/firestore";
import { db } from "../firebase/firebase";

export interface TeacherSummary {
  totalTasks: number;
  completedTasks: number;
  completionRate: number;
  plannedMinutes: number;
  completedMinutes: number;
}

export interface TaskTrendPoint {
  date: string;
  completedTasks: number;
}

export const getTeacherSummary = async (
  teacherId: string
): Promise<TeacherSummary> => {
  const snap = await getDocs(
    query(
      collection(db, "teacher_tasks"),
      where("teacherId", "==", teacherId)
    )
  );

  let totalTasks = 0;
  let completedTasks = 0;
  let plannedMinutes = 0;
  let completedMinutes = 0;

  snap.forEach((doc) => {
    const t = doc.data();
    totalTasks += 1;
    plannedMinutes += t.estimatedMinutes || 0;

    if (t.status === "completed") {
      completedTasks += 1;
      completedMinutes +=
        t.actualMinutes || t.estimatedMinutes || 0;
    }
  });

  return {
    totalTasks,
    completedTasks,
    completionRate:
      totalTasks === 0
        ? 0
        : Math.round((completedTasks / totalTasks) * 100),
    plannedMinutes,
    completedMinutes,
  };
};

export const getTeacherTaskTrend = async (
  teacherId: string
): Promise<TaskTrendPoint[]> => {
  const snap = await getDocs(
    query(
      collection(db, "teacher_tasks"),
      where("teacherId", "==", teacherId)
    )
  );

  const dailyMap: Record<string, number> = {};

  snap.forEach((doc) => {
    const t = doc.data();
    if (t.status !== "completed" || !t.completedAt) return;

    const date = t.completedAt
      .toDate()
      .toISOString()
      .slice(0, 10);

    dailyMap[date] = (dailyMap[date] || 0) + 1;
  });

  return Object.entries(dailyMap)
    .map(([date, completedTasks]) => ({
      date,
      completedTasks,
    }))
    .sort((a, b) => a.date.localeCompare(b.date));
};
