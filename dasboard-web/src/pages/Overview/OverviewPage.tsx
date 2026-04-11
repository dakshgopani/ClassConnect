import { useEffect, useState } from "react";
import Grid from "@mui/material/Grid";
import { Box, Card, CardContent, Typography, TextField } from "@mui/material";
import MetricCard from "../../components/MetricCard";
import { getAdminOverviewMetrics } from "../../services/adminMetrics.service";
import ClassSizeChart from "../../components/charts/ClassSizeChart";
import {
	getClassSizeDistribution,
	type ClassSizeMetric,
} from "../../services/analytics.service";
import {
	getQuizPerformanceByClass,
	type QuizPerformanceMetric,
} from "../../services/analytics.service";
import QuizPerformanceChart from "../../components/charts/QuizPerformanceChart";
import WeakConceptsChart from "../../components/charts/WeakConceptsChart";
import {
	getTopWeakConcepts,
	type WeakConceptMetric,
} from "../../services/analytics.service";
import TeacherWorkloadChart from "../../components/charts/TeacherWorkloadChart";
import {
	getTeacherWorkloadMetrics,
	type TeacherWorkloadMetric,
} from "../../services/analytics.service";
import CommunityEngagementChart from "../../components/charts/CommunityEngagementChart";
import {
	getCommunityEngagementMetrics,
	type CommunityMetric,
} from "../../services/analytics.service";
import {
	getOverallAttendanceSummary,
	getClassAttendanceMetrics,
	getAttendanceTrend,
} from "../../services/adminAttendance.service";
import AdminAttendanceTrendChart from "../../components/charts/AdminAttendanceTrendChart";
import ClassAttendanceTable from "../../components/tables/ClassAttendanceTable";
import ExecutiveSummary from "../../components/pdf/ExecutiveSummary";
import ExportPdfButton from "../../components/ExportPdfButton";

type OverviewMetrics = {
	totalClasses: number;
	totalStudents: number;
	totalTeachers: number;
};

type CommunityEngagementResponse = Awaited<
	ReturnType<typeof getCommunityEngagementMetrics>
>;

export default function OverviewPage() {
	const [metrics, setMetrics] = useState<OverviewMetrics | null>(null);
	const [classSizes, setClassSizes] = useState<ClassSizeMetric[]>([]);
	const [quizPerformance, setQuizPerformance] = useState<
		QuizPerformanceMetric[]
	>([]);
	const [weakConcepts, setWeakConcepts] = useState<WeakConceptMetric[]>([]);
	const [teacherWorkload, setTeacherWorkload] = useState<
		TeacherWorkloadMetric[]
	>([]);
	const [communityTrend, setCommunityTrend] = useState<CommunityMetric[]>([]);
	const [communitySummary, setCommunitySummary] = useState<
		CommunityEngagementResponse["summary"] | null
	>(null);
	const [attendanceSummary, setAttendanceSummary] = useState<any>(null);
	const [attendanceTrend, setAttendanceTrend] = useState<any[]>([]);
	const [classAttendance, setClassAttendance] = useState<any[]>([]);
	const [department, setDepartment] = useState("");
	
	const fetchData = () => {
		const collegeName = localStorage.getItem("collegeName") || undefined;
		const deptFilter = department.trim() || undefined;

		getAdminOverviewMetrics(collegeName, deptFilter).then(setMetrics);
		getClassSizeDistribution(collegeName).then(setClassSizes); // Class metrics kept to college level for now
		getQuizPerformanceByClass(collegeName).then(setQuizPerformance);
		getTopWeakConcepts(10, collegeName, deptFilter).then(setWeakConcepts);
		getTeacherWorkloadMetrics(collegeName, deptFilter).then(setTeacherWorkload);
		getCommunityEngagementMetrics().then((res) => {
			setCommunityTrend(res.trend);
			setCommunitySummary(res.summary);
		});
		getOverallAttendanceSummary(collegeName).then(setAttendanceSummary);
		getAttendanceTrend(collegeName).then(setAttendanceTrend);
		getClassAttendanceMetrics(collegeName).then(setClassAttendance);
	};

	useEffect(() => {
		fetchData();
	}, [department]); // Re-fetch when department changes

	if (!metrics) return <div>Loading...</div>;

	return (
		<>
			<Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
				<Typography variant="h5">
					Institute Overview
				</Typography>
				<Box display="flex" gap={2}>
					<TextField 
						label="Filter by Department" 
						size="small" 
						value={department}
						onChange={(e) => setDepartment(e.target.value)}
						placeholder="e.g. CSE"
					/>
					<ExportPdfButton />
				</Box>
			</Box>

			<br />
			<Grid container spacing={2}>
				<Grid size={{ xs: 4 }}>
					<MetricCard title="Total Classes" value={metrics.totalClasses} />
				</Grid>
				<Grid size={{ xs: 4 }}>
					<MetricCard title="Total Students" value={metrics.totalStudents} />
				</Grid>
				<Grid size={{ xs: 4 }}>
					<MetricCard title="Total Teachers" value={metrics.totalTeachers} />
				</Grid>
			</Grid>
			<br />

			<Grid container spacing={2} mt={1}>
				<Grid size={{ xs: 12 }}>
					<ClassSizeChart data={classSizes} />
				</Grid>

				<Grid size={{ xs: 12 }}>
					<QuizPerformanceChart data={quizPerformance} />
				</Grid>

				<Grid size={{ xs: 12 }}>
					<WeakConceptsChart data={weakConcepts} />
				</Grid>

				<Grid size={{ xs: 12 }}>
					<TeacherWorkloadChart data={teacherWorkload} />
				</Grid>

				<Grid size={{ xs: 12 }}>
					<CommunityEngagementChart data={communityTrend} />
				</Grid>
			</Grid>
			<br />
			<Grid size={{ xs: 12, md: 4 }}>
				<Card>
					<CardContent>
						<Typography variant="subtitle2">Avg Attendance</Typography>
						<Typography variant="h4">
							{attendanceSummary?.avgAttendancePercent ?? "—"}%
						</Typography>
					</CardContent>
				</Card>
			</Grid>
			<br />
			<Grid size={{ xs: 12, md: 4 }}>
				<AdminAttendanceTrendChart data={attendanceTrend} />
			</Grid>
			<br />
			<Grid size={{ xs: 12, md: 4 }}>
				<ClassAttendanceTable data={classAttendance} />
			</Grid>
			<Box
				sx={{
					position: "absolute",
					top: "-9999px",
					left: "-9999px",
				}}
			>
				<ExecutiveSummary
					attendance={{
						avgAttendancePercent: attendanceSummary?.avgAttendancePercent ?? 0,
						totalSessions: attendanceSummary?.totalSessions ?? 0,
						trend: attendanceTrend,
					}}
					classes={classSizes}
					quizPerformance={quizPerformance}
					weakConcepts={weakConcepts}
					teacherWorkload={teacherWorkload}
					communityData={{
						trend: communityTrend,
						summary: communitySummary ?? {
							totalQuestions: 0,
							totalAnswers: 0,
							avgAnswersPerQuestion: 0,
						},
					}}
					metrics={{
						totalClasses: metrics.totalClasses,
						totalStudents: metrics.totalStudents,
						totalTeachers: metrics.totalTeachers,
					}}
				/>
			</Box>
		</>
	);
}
