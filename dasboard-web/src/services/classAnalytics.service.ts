import { collection, getDocs, query, where } from "firebase/firestore";
import { db } from "../firebase/firebase";
import { doc, getDoc } from "firebase/firestore";

export interface ClassAnalytics {
	studentCount: number;
	avgQuizScore: number;
	pblSubmissionRate: number; // percentage
}

export const getClassAnalytics = async (
	classId: string,
): Promise<ClassAnalytics> => {
	// 1️⃣ Students in class
	const studentsSnap = await getDocs(
		query(collection(db, "class_students"), where("classId", "==", classId)),
	);

	const studentIds = studentsSnap.docs.map((d) => d.data().studentId);

	// 2️⃣ Quiz performance
	const quizSnap = await getDocs(
		query(collection(db, "quiz_attempts"), where("classId", "==", classId)),
	);

	let totalScore = 0;
	let totalAttempts = 0;

	quizSnap.forEach((doc) => {
		const q = doc.data();
		if (!q.total) return;
		totalScore += (q.score / q.total) * 100;
		totalAttempts += 1;
	});

	const avgQuizScore =
		totalAttempts === 0
			? 0
			: Math.round((totalScore / totalAttempts) * 10) / 10;

	// 3️⃣ PBL submissions
	let submittedStudentSet = new Set<string>();

	for (const studentId of studentIds) {
		const pblSnap = await getDocs(
			query(
				collection(db, "students", studentId, "submittedPBL"),
				where("classId", "==", classId),
			),
		);

		if (!pblSnap.empty) {
			submittedStudentSet.add(studentId);
		}
	}

	const pblSubmissionRate =
		studentIds.length === 0
			? 0
			: Math.round((submittedStudentSet.size / studentIds.length) * 100);

	return {
		studentCount: studentIds.length,
		avgQuizScore,
		pblSubmissionRate,
	};
};

export interface QuizTrendPoint {
	date: string;
	avgScore: number;
}

export interface WeakConceptMetric {
	concept: string;
	count: number;
}

export const getClassQuizTrend = async (
	classId: string,
): Promise<QuizTrendPoint[]> => {
	const snap = await getDocs(
		query(collection(db, "quiz_attempts"), where("classId", "==", classId)),
	);

	const dailyMap: Record<string, { total: number; count: number }> = {};

	snap.forEach((doc) => {
		const q = doc.data();
		if (!q.total || !q.submittedAt) return;

		const date = q.submittedAt.toDate().toISOString().slice(0, 10);

		if (!dailyMap[date]) {
			dailyMap[date] = { total: 0, count: 0 };
		}

		dailyMap[date].total += (q.score / q.total) * 100;
		dailyMap[date].count += 1;
	});

	return Object.entries(dailyMap)
		.map(([date, v]) => ({
			date,
			avgScore: Math.round((v.total / v.count) * 10) / 10,
		}))
		.sort((a, b) => a.date.localeCompare(b.date));
};

export const getClassWeakConcepts = async (
	classId: string,
	limit = 8,
): Promise<WeakConceptMetric[]> => {
	const snap = await getDocs(
		query(collection(db, "quiz_attempts"), where("classId", "==", classId)),
	);

	const countMap: Record<string, number> = {};

	snap.forEach((doc) => {
		const weakConcepts = doc.data().weakConcepts || [];
		weakConcepts.forEach((c: string) => {
			countMap[c] = (countMap[c] || 0) + 1;
		});
	});

	return Object.entries(countMap)
		.map(([concept, count]) => ({ concept, count }))
		.sort((a, b) => b.count - a.count)
		.slice(0, limit);
};

export interface ClassStudentRow {
	studentId: string;
	name: string;
	avgQuizScore: number;
	quizAttempts: number;
}

export const getStudentsOfClass = async (
	classId: string,
): Promise<ClassStudentRow[]> => {
	// 1️⃣ Get student IDs in class
	const classStudentsSnap = await getDocs(
		query(collection(db, "class_students"), where("classId", "==", classId)),
	);

	const studentIds = classStudentsSnap.docs.map((d) => d.data().studentId);

	const results: ClassStudentRow[] = [];

	// 2️⃣ For each student → compute summary
	for (const studentId of studentIds) {
		const studentSnap = await getDoc(doc(db, "students", studentId));

		const student = studentSnap.exists() ? studentSnap.data() : null;

		const quizSnap = await getDocs(
			query(
				collection(db, "quiz_attempts"),
				where("studentId", "==", studentId),
				where("classId", "==", classId),
			),
		);

		let totalScore = 0;
		let attempts = 0;

		quizSnap.forEach((q) => {
			const d = q.data();
			if (!d.total) return;
			totalScore += (d.score / d.total) * 100;
			attempts += 1;
		});

		results.push({
			studentId,
			name: student?.name ?? "—",
			quizAttempts: attempts,
			avgQuizScore:
				attempts === 0 ? 0 : Math.round((totalScore / attempts) * 10) / 10,
		});
	}

	return results;
};
