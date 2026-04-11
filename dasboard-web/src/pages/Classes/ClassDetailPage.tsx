import { useParams } from "react-router-dom";
import { Typography, Grid, Card, CardContent } from "@mui/material";
import { useEffect, useState } from "react";
import { getClassAnalytics } from "../../services/classAnalytics.service";
import { type ClassAnalytics } from "../../services/classAnalytics.service";
import {
	getClassQuizTrend,
	getClassWeakConcepts,
} from "../../services/classAnalytics.service";
import ClassQuizTrendChart from "../../components/charts/ClassQuizTrendChart";
import ClassWeakConceptsChart from "../../components/charts/ClassWeakConceptsChart";
import {
	getStudentsOfClass,
 type	ClassStudentRow,
} from "../../services/classAnalytics.service";
import ClassStudentsTable from "../../components/tables/ClassStudentsTable";

export default function ClassDetailPage() {
	const { classId } = useParams<{ classId: string }>();
	const [analytics, setAnalytics] = useState<ClassAnalytics | null>(null);
	const [quizTrend, setQuizTrend] = useState<
		Awaited<ReturnType<typeof getClassQuizTrend>>
	>([]);
	const [weakConcepts, setWeakConcepts] = useState<
		Awaited<ReturnType<typeof getClassWeakConcepts>>
	>([]);
	const [students, setStudents] = useState<ClassStudentRow[]>([]);

	useEffect(() => {
		if (classId) {
			getClassAnalytics(classId).then(setAnalytics);
			getClassQuizTrend(classId).then(setQuizTrend);
			getClassWeakConcepts(classId).then(setWeakConcepts);
			getStudentsOfClass(classId).then(setStudents);
		}
	}, [classId]);

	return (
		<>
			<Typography variant="h5" gutterBottom>
				Class Analytics
			</Typography>

			<Typography variant="body2" color="text.secondary" gutterBottom>
				Class ID: {classId}
			</Typography>

			<Grid container spacing={2} mt={2}>
				<Grid size={{ xs: 12, md: 4 }}>
					<Card>
						<CardContent>
							<Typography variant="subtitle2">Total Students</Typography>
							<Typography variant="h5">
								{analytics?.studentCount ?? "—"}
							</Typography>
						</CardContent>
					</Card>
				</Grid>

				<Grid size={{ xs: 12, md: 4 }}>
					<Card>
						<CardContent>
							<Typography variant="subtitle2">Avg Quiz Score</Typography>
							<Typography variant="h5">
								{analytics?.avgQuizScore ?? "—"}%
							</Typography>
						</CardContent>
					</Card>
				</Grid>
				<Grid size={{ xs: 12, md: 4 }}>
					<Card>
						<CardContent>
							<Typography variant="subtitle2">PBL Submission Rate</Typography>
							<Typography variant="h5">
								{analytics?.pblSubmissionRate ?? "—"}%
							</Typography>
						</CardContent>
					</Card>
				</Grid>
			</Grid>
			<Grid container spacing={2} mt={2}>
				<Grid size={{ xs: 12, md: 6 }}>
					<ClassQuizTrendChart data={quizTrend} />
				</Grid>

				<Grid size={{ xs: 12, md: 6 }}>
					<ClassWeakConceptsChart data={weakConcepts} />
				</Grid>
			</Grid>
			<Typography variant="h6" mt={4} gutterBottom>
				Students in this Class
			</Typography>

			<ClassStudentsTable students={students} />
		</>
	);
}
