import { collection, getDocs, query, where } from "firebase/firestore";
import { db } from "../firebase/firebase";

export interface AttendanceSummary {
	totalSessions: number;
	avgAttendancePercent: number;
}

export interface ClassAttendanceMetric {
	classId: string;
	attendancePercent: number;
	sessions: number;
}

export interface AttendanceTrendPoint {
	date: string;
	attendancePercent: number;
}

export const getOverallAttendanceSummary =
	async (collegeName?: string): Promise<AttendanceSummary> => {
		// If collegeName provided, we need to filter attendance by classes belonging to that college
		let relevantClassIds: string[] | null = null;
		
		if (collegeName) {
			const q = query(collection(db, "classes"), where("collegeSchoolName", "==", collegeName));
			const classesSnap = await getDocs(q);
			relevantClassIds = classesSnap.docs.map(doc => doc.id);
		}

		const snap = await getDocs(collection(db, "attendance"));

		let totalSessions = 0;
		let totalPercent = 0;

		snap.forEach((doc) => {
			const a = doc.data();
			
			// Filter by classId if we are restricting to a college
			if (relevantClassIds && (!a.classId || !relevantClassIds.includes(a.classId))) {
				return;
			}

			if (!a.totalStudents || a.totalStudents === 0) return;

			const percent = (a.presentCount / a.totalStudents) * 100;

			totalSessions += 1;
			totalPercent += percent;
		});

		return {
			totalSessions,
			avgAttendancePercent:
				totalSessions === 0 ? 0 : Math.round(totalPercent / totalSessions),
		};
	};

export const getClassAttendanceMetrics = async (collegeName?: string): Promise<
	ClassAttendanceMetric[]
> => {
	// Fetch all attendance
	const attendancePromise = getDocs(collection(db, "attendance"));
	
	// Fetch classes (filtered if collegeName present)
	let classesPromise;
	if (collegeName) {
		const q = query(collection(db, "classes"), where("collegeSchoolName", "==", collegeName));
		classesPromise = getDocs(q);
	} else {
		classesPromise = getDocs(collection(db, "classes"));
	}

	const [attendanceSnap, classesSnap] = await Promise.all([
		attendancePromise,
		classesPromise,
	]);

	const classNames: Record<string, string> = {};
	classesSnap.forEach((doc) => {
		classNames[doc.id] = doc.data().class_name;
	});

	const map: Record<string, { total: number; sessions: number }> = {};

	attendanceSnap.forEach((doc) => {
		const a = doc.data();
		if (!a.classId || !a.totalStudents) return;
		
		// If class is not in our fetched list (because of college filter), skip
		if (!classNames[a.classId] && !Object.keys(classNames).includes(a.classId)) {
			// Actually, classNames key check is safer. 
			// If we filtered classesSnap, classNames only contains valid classes.
			// So if a.classId is not key in classNames, it's not from this college.
			if (collegeName && !classNames[a.classId]) return;
		}

		const name = classNames[a.classId] || a.classId;

		if (!map[name]) {
			map[name] = { total: 0, sessions: 0 };
		}

		map[name].total += (a.presentCount / a.totalStudents) * 100;
		map[name].sessions += 1;
	});

	return Object.entries(map).map(([name, v]) => ({
		classId: name,
		sessions: v.sessions,
		attendancePercent: Math.round(v.total / v.sessions),
	}));
};

export const getAttendanceTrend = async (collegeName?: string): Promise<AttendanceTrendPoint[]> => {
	// Need relevant class IDs to filter attendance
	let relevantClassIds: string[] | null = null;
		
	if (collegeName) {
		const q = query(collection(db, "classes"), where("collegeSchoolName", "==", collegeName));
		const classesSnap = await getDocs(q);
		relevantClassIds = classesSnap.docs.map(doc => doc.id);
	}

	const snap = await getDocs(collection(db, "attendance"));

	const dailyMap: Record<string, number[]> = {};

	snap.forEach((doc) => {
		const a = doc.data();
		
		// Filter
		if (relevantClassIds && (!a.classId || !relevantClassIds.includes(a.classId))) {
			return;
		}

		if (!a.date || !a.totalStudents) return;

		const percent = (a.presentCount / a.totalStudents) * 100;

		if (!dailyMap[a.date]) {
			dailyMap[a.date] = [];
		}
		dailyMap[a.date].push(percent);
	});

	return Object.entries(dailyMap)
		.map(([date, values]) => ({
			date,
			attendancePercent: Math.round(
				values.reduce((a, b) => a + b, 0) / values.length,
			),
		}))
		.sort((a, b) => a.date.localeCompare(b.date));
};
