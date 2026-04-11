import { collection, getDocs, query, where } from "firebase/firestore";
import { db } from "../firebase/firebase";

export interface ClassSizeMetric {
  classId: string;
  className: string;
  studentCount: number;
}

export const getClassSizeDistribution = async (collegeName?: string): Promise<ClassSizeMetric[]> => {
  // 1️⃣ Fetch classes
  let classesSnap;
  if (collegeName) {
      const q = query(collection(db, "classes"), where("collegeSchoolName", "==", collegeName));
      classesSnap = await getDocs(q);
  } else {
      classesSnap = await getDocs(collection(db, "classes"));
  }

  const classMap: Record<string, string> = {};
  classesSnap.forEach((doc) => {
    classMap[doc.id] = doc.data().class_name;
  });

  // 2️⃣ Count students per class (Fetch all for now, filter in memory)
  const classStudentSnap = await getDocs(collection(db, "class_students"));
  const countMap: Record<string, number> = {};

  classStudentSnap.forEach((doc) => {
    const classId = doc.data().classId;
    // Only count if class belongs to the filtered set
    if (classMap[classId]) {
        countMap[classId] = (countMap[classId] || 0) + 1;
    }
  });

  // 3️⃣ Build final chart data
  return Object.keys(countMap).map((classId) => ({
    classId,
    className: classMap[classId] ?? "Unknown",
    studentCount: countMap[classId],
  }));
};

export interface QuizPerformanceMetric {
  classId: string;
  className: string;
  averageScore: number; // percentage
}

export const getQuizPerformanceByClass = async (collegeName?: string): Promise<
  QuizPerformanceMetric[]
> => {
  // 1️⃣ Fetch class names
  let classesSnap;
  if (collegeName) {
      const q = query(collection(db, "classes"), where("collegeSchoolName", "==", collegeName));
      classesSnap = await getDocs(q);
  } else {
      classesSnap = await getDocs(collection(db, "classes"));
  }

  const classMap: Record<string, string> = {};

  classesSnap.forEach((doc) => {
    classMap[doc.id] = doc.data().class_name;
  });

  // 2️⃣ Fetch quiz attempts
  const quizSnap = await getDocs(collection(db, "quiz_attempts"));

  const scoreMap: Record<
    string,
    { totalPercentage: number; count: number }
  > = {};

  quizSnap.forEach((doc) => {
    const data = doc.data();
    const classId = data.classId;
    
    // Filter: Only process if class exists in our map
    if (!classId || !classMap[classId]) return;

    const score = data.score;
    const total = data.total;

    if (!classId || !total) return;

    const percentage = (score / total) * 100;

    if (!scoreMap[classId]) {
      scoreMap[classId] = { totalPercentage: 0, count: 0 };
    }

    scoreMap[classId].totalPercentage += percentage;
    scoreMap[classId].count += 1;
  });

  // 3️⃣ Build final metrics
  return Object.keys(scoreMap).map((classId) => ({
    classId,
    className: classMap[classId] ?? "Unknown",
    averageScore:
      Math.round(
        (scoreMap[classId].totalPercentage / scoreMap[classId].count) * 10
      ) / 10,
  }));
};

export interface WeakConceptMetric {
  concept: string;
  count: number;
}

export const getTopWeakConcepts = async (
  limit = 10,
  collegeName?: string,
  department?: string
): Promise<WeakConceptMetric[]> => {
  // If college/department filtered, fetch relevant class IDs AND/OR Student IDs
  let relevantClassIds: string[] | null = null;
  let validStudentIds: Set<string> | null = null;
  
  if (collegeName || department) {
      if (collegeName) {
         const q = query(collection(db, "classes"), where("collegeSchoolName", "==", collegeName));
         const classesSnap = await getDocs(q);
         relevantClassIds = classesSnap.docs.map(doc => doc.id);
      }

      if (department) {
           // We must find students in this department and only count their weak concepts
           const constraints = [];
           if (collegeName) constraints.push(where("collegeSchoolName", "==", collegeName));
           constraints.push(where("studentDepartment", "==", department));
           const qStudents = query(collection(db, "students"), ...constraints);
           const studentsSnap = await getDocs(qStudents);
           validStudentIds = new Set(studentsSnap.docs.map(doc => doc.id));
      }
  }

  const quizSnap = await getDocs(collection(db, "quiz_attempts"));

  const conceptCount: Record<string, number> = {};

  quizSnap.forEach((doc) => {
    const data = doc.data();
    
    // Filter by classId if restricted (College Level)
    if (relevantClassIds && (!data.classId || !relevantClassIds.includes(data.classId))) {
        return;
    }

    // Filter by Student ID (Department Level)
    if (validStudentIds && (!data.studentId || !validStudentIds.has(data.studentId))) {
        return;
    }

    const weakConcepts: string[] = data.weakConcepts || [];

    weakConcepts.forEach((concept) => {
      conceptCount[concept] = (conceptCount[concept] || 0) + 1;
    });
  });

  return Object.entries(conceptCount)
    .map(([concept, count]) => ({ concept, count }))
    .sort((a, b) => b.count - a.count)
    .slice(0, limit);
};

export interface TeacherWorkloadMetric {
  teacherId: string;
  teacherName: string;
  plannedMinutes: number;
  completedMinutes: number;
  completedTasks: number;
  totalTasks: number;
}

export const getTeacherWorkloadMetrics = async (collegeName?: string, department?: string): Promise<
  TeacherWorkloadMetric[]
> => {
  // 1️⃣ Fetch teachers
  let teachersSnap;
  const constraints = [];
    
  // Schema fix: Teachers use 'collegeName'
  if (collegeName) constraints.push(where("collegeName", "==", collegeName));
  if (department) constraints.push(where("teacherDepartment", "==", department));

  if (constraints.length > 0) {
      const q = query(collection(db, "teachers"), ...constraints);
      teachersSnap = await getDocs(q);
  } else {
      teachersSnap = await getDocs(collection(db, "teachers"));
  }

  const teacherMap: Record<string, string> = {};

  teachersSnap.forEach((doc) => {
    teacherMap[doc.id] = doc.data().name;
  });

  // 2️⃣ Count tasks/assignments per teacher
  // Note: If we filtered teachers, we only count for those teachers.
  const taskSnap = await getDocs(collection(db, "assignments"));
  const workloadMap: Record<string, TeacherWorkloadMetric> = {};

  taskSnap.forEach((doc) => {
    const t = doc.data();
    const teacherId = t.teacherId;
    if (!teacherId || !teacherMap[teacherId]) return;

    if (!workloadMap[teacherId]) {
      workloadMap[teacherId] = {
        teacherId: "unknown", 
        teacherName: teacherMap[teacherId],
        totalTasks: 0,
        plannedMinutes: 0,
        completedMinutes: 0,
        completedTasks: 0
      };
    }
    workloadMap[teacherId].totalTasks += 1;
  });

  return Object.values(workloadMap);
};

export interface CommunityMetric {
  date: string;
  questions: number;
  answers: number;
}

export interface CommunitySummary {
  totalQuestions: number;
  totalAnswers: number;
  avgAnswersPerQuestion: number;
}

export const getCommunityEngagementMetrics = async (): Promise<{
  trend: CommunityMetric[];
  summary: CommunitySummary;
}> => {
  const questionsSnap = await getDocs(collection(db, "community"));

  const dailyMap: Record<string, CommunityMetric> = {};
  let totalQuestions = 0;
  let totalAnswers = 0;

  for (const qDoc of questionsSnap.docs) {
    const q = qDoc.data();
    totalQuestions += 1;
    totalAnswers += q.answerCount || 0;

    const date = new Date(q.createdAt).toISOString().slice(0, 10);

    if (!dailyMap[date]) {
      dailyMap[date] = { date, questions: 0, answers: 0 };
    }

    dailyMap[date].questions += 1;
    dailyMap[date].answers += q.answerCount || 0;
  }

  const trend = Object.values(dailyMap).sort(
    (a, b) => a.date.localeCompare(b.date)
  );

  return {
    trend,
    summary: {
      totalQuestions,
      totalAnswers,
      avgAnswersPerQuestion:
        totalQuestions === 0
          ? 0
          : Math.round((totalAnswers / totalQuestions) * 10) / 10,
    },
  };
};
