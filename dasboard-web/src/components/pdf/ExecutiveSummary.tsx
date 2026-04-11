import {
	Box,
	Typography,
	Grid,
	Card,
	CardContent,
	Divider,
	Table,
	TableBody,
	TableCell,
	TableContainer,
	TableHead,
	TableRow,
	Chip,
} from "@mui/material";
import PdfChartWrapper from "./PdfChartWrapper";
import AdminAttendanceTrendChart from "../charts/AdminAttendanceTrendChart";
import ClassSizeChart from "../charts/ClassSizeChart";
import QuizPerformanceChart from "../charts/QuizPerformanceChart";
import WeakConceptsChart from "../charts/WeakConceptsChart";
import TeacherWorkloadChart from "../charts/TeacherWorkloadChart";
import CommunityEngagementChart from "../charts/CommunityEngagementChart";
import TrendingUpIcon from "@mui/icons-material/TrendingUp";
import TrendingDownIcon from "@mui/icons-material/TrendingDown";
import SchoolIcon from "@mui/icons-material/School";
import PeopleIcon from "@mui/icons-material/People";
import PersonIcon from "@mui/icons-material/Person";
import QuizIcon from "@mui/icons-material/Quiz";

interface AttendanceData {
	avgAttendancePercent: number;
	totalSessions: number;
	trend: AttendanceTrendPoint[];
}

interface AttendanceTrendPoint {
	date: string;
	attendancePercent: number;
}

interface ClassSizeMetric {
	classId: string;
	className: string;
	studentCount: number;
}

interface QuizPerformanceMetric {
	classId: string;
	className: string;
	averageScore: number;
}

interface WeakConceptMetric {
	concept: string;
	count: number;
}

interface TeacherWorkloadMetric {
	teacherId: string;
	teacherName: string;
	plannedMinutes: number;
	completedMinutes: number;
	completedTasks: number;
	totalTasks: number;
}

interface CommunityMetric {
	date: string;
	questions: number;
	answers: number;
}

interface CommunitySummary {
	totalQuestions: number;
	totalAnswers: number;
	avgAnswersPerQuestion: number;
}

interface Metrics {
	totalClasses: number;
	totalStudents: number;
	totalTeachers: number;
}

export default function ExecutiveSummary({
	attendance,
	classes,
	quizPerformance,
	weakConcepts,
	teacherWorkload,
	communityData,
	metrics,
}: {
	attendance: AttendanceData;
	classes: ClassSizeMetric[];
	quizPerformance: QuizPerformanceMetric[];
	weakConcepts: WeakConceptMetric[];
	teacherWorkload: TeacherWorkloadMetric[];
	communityData: { trend: CommunityMetric[]; summary: CommunitySummary };
	metrics: Metrics;
}) {
	// Calculate insights
	const avgQuizScore =
		quizPerformance.length > 0
			? Math.round(
					quizPerformance.reduce((sum, q) => sum + q.averageScore, 0) /
						quizPerformance.length
			  )
			: 0;
	const topWeakConcept = weakConcepts[0]?.concept || "N/A";
	const overloadedTeachers = teacherWorkload.filter(
		(t) => t.plannedMinutes > 500
	).length;

	return (
		<Box
			id="executive-summary"
			sx={{
				backgroundColor: "#fff",
				width: "210mm", // A4 width
				minHeight: "297mm", // A4 height
			}}
		>
			{/* ========== PAGE 1 ========== */}
			<Box
				sx={{
					padding: 4,
					height: "297mm",
					display: "flex",
					flexDirection: "column",
				}}
			>
				{/* HEADER */}
				<Box
					sx={{
						background: "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
						color: "#fff",
						padding: 3,
						borderRadius: 2,
						mb: 3,
					}}
				>
					<Typography variant="h3" gutterBottom fontWeight="bold">
						Institute Executive Report
					</Typography>
					<Typography variant="h6">
						Comprehensive Analytics & Performance Insights
					</Typography>
					<Typography variant="body2" sx={{ mt: 1, opacity: 0.9 }}>
						Generated on {new Date().toLocaleDateString("en-US", {
							weekday: "long",
							year: "numeric",
							month: "long",
							day: "numeric",
						})}
					</Typography>
				</Box>

				{/* KEY METRICS DASHBOARD */}
				<Typography variant="h5" gutterBottom fontWeight="bold" color="primary">
					📊 Key Performance Indicators
				</Typography>
				<Grid container spacing={2} mb={3}>
					<Grid size={{ xs: 3 }}>
						<Card
							sx={{
								background: "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
								color: "#fff",
							}}
						>
							<CardContent>
								<Box display="flex" alignItems="center" gap={1}>
									<SchoolIcon />
									<Typography variant="subtitle2">Total Classes</Typography>
								</Box>
								<Typography variant="h4" fontWeight="bold">
									{metrics.totalClasses}
								</Typography>
							</CardContent>
						</Card>
					</Grid>

					<Grid size={{ xs: 3 }}>
						<Card
							sx={{
								background: "linear-gradient(135deg, #f093fb 0%, #f5576c 100%)",
								color: "#fff",
							}}
						>
							<CardContent>
								<Box display="flex" alignItems="center" gap={1}>
									<PeopleIcon />
									<Typography variant="subtitle2">Total Students</Typography>
								</Box>
								<Typography variant="h4" fontWeight="bold">
									{metrics.totalStudents}
								</Typography>
							</CardContent>
						</Card>
					</Grid>

					<Grid size={{ xs: 3 }}>
						<Card
							sx={{
								background: "linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)",
								color: "#fff",
							}}
						>
							<CardContent>
								<Box display="flex" alignItems="center" gap={1}>
									<PersonIcon />
									<Typography variant="subtitle2">Total Teachers</Typography>
								</Box>
								<Typography variant="h4" fontWeight="bold">
									{metrics.totalTeachers}
								</Typography>
							</CardContent>
						</Card>
					</Grid>

					<Grid size={{ xs: 3 }}>
						<Card
							sx={{
								background: "linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)",
								color: "#fff",
							}}
						>
							<CardContent>
								<Box display="flex" alignItems="center" gap={1}>
									<QuizIcon />
									<Typography variant="subtitle2">Avg Quiz Score</Typography>
								</Box>
								<Typography variant="h4" fontWeight="bold">
									{avgQuizScore}%
								</Typography>
							</CardContent>
						</Card>
					</Grid>
				</Grid>

				{/* ATTENDANCE METRICS */}
				<Grid container spacing={2} mb={3}>
					<Grid size={{ xs: 4 }}>
						<Card elevation={3}>
							<CardContent>
								<Typography variant="subtitle2" color="textSecondary">
									Average Attendance
								</Typography>
								<Box display="flex" alignItems="center" gap={1}>
									<Typography variant="h4" fontWeight="bold" color="primary">
										{attendance.avgAttendancePercent}%
									</Typography>
									{attendance.avgAttendancePercent >= 80 ? (
										<TrendingUpIcon color="success" />
									) : (
										<TrendingDownIcon color="error" />
									)}
								</Box>
							</CardContent>
						</Card>
					</Grid>

					<Grid size={{ xs: 4 }}>
						<Card elevation={3}>
							<CardContent>
								<Typography variant="subtitle2" color="textSecondary">
									Total Sessions
								</Typography>
								<Typography variant="h4" fontWeight="bold" color="primary">
									{attendance.totalSessions}
								</Typography>
							</CardContent>
						</Card>
					</Grid>

					<Grid size={{ xs: 4 }}>
						<Card elevation={3}>
							<CardContent>
								<Typography variant="subtitle2" color="textSecondary">
									Community Engagement
								</Typography>
								<Typography variant="h4" fontWeight="bold" color="primary">
									{communityData.summary.totalQuestions}
								</Typography>
								<Typography variant="caption" color="textSecondary">
									Questions asked
								</Typography>
							</CardContent>
						</Card>
					</Grid>
				</Grid>

				<Divider sx={{ my: 2 }} />

				{/* CHARTS SECTION - PAGE 1 */}
				<Typography variant="h5" gutterBottom fontWeight="bold" color="primary">
					📈 Attendance & Class Analytics
				</Typography>

				<Grid container spacing={2}>
					<Grid size={{ xs: 12 }}>
						<PdfChartWrapper title="Attendance Trend Over Time">
							<AdminAttendanceTrendChart data={attendance.trend} />
						</PdfChartWrapper>
					</Grid>

					<Grid size={{ xs: 12 }}>
						<PdfChartWrapper title="Class Size Distribution">
							<ClassSizeChart data={classes} />
						</PdfChartWrapper>
					</Grid>
				</Grid>
			</Box>

			{/* ========== PAGE 2 ========== */}
			<Box
				sx={{
					padding: 4,
					height: "297mm",
					display: "flex",
					flexDirection: "column",
					pageBreakBefore: "always",
				}}
			>
				{/* PAGE HEADER */}
				<Box
					sx={{
						borderBottom: "3px solid #667eea",
						pb: 1,
						mb: 3,
					}}
				>
					<Typography variant="h5" fontWeight="bold" color="primary">
						Academic Performance & Learning Analytics
					</Typography>
				</Box>

				{/* QUIZ PERFORMANCE */}
				<Grid container spacing={2} mb={3}>
					<Grid size={{ xs: 12 }}>
						<PdfChartWrapper title="Quiz Performance by Class">
							<QuizPerformanceChart data={quizPerformance} />
						</PdfChartWrapper>
					</Grid>

					<Grid size={{ xs: 12 }}>
						<PdfChartWrapper title="Top Weak Concepts Across Institute">
							<WeakConceptsChart data={weakConcepts} />
						</PdfChartWrapper>
					</Grid>
				</Grid>

				<Divider sx={{ my: 2 }} />

				{/* TEACHER WORKLOAD */}
				<Typography variant="h5" gutterBottom fontWeight="bold" color="primary">
					👨‍🏫 Teacher Workload & Task Management
				</Typography>
				<Grid container spacing={2}>
					<Grid size={{ xs: 12 }}>
						<PdfChartWrapper title="Teacher Workload Distribution">
							<TeacherWorkloadChart data={teacherWorkload} />
						</PdfChartWrapper>
					</Grid>

					<Grid size={{ xs: 12 }}>
						<PdfChartWrapper title="Community Engagement Trend">
							<CommunityEngagementChart data={communityData.trend} />
						</PdfChartWrapper>
					</Grid>
				</Grid>
			</Box>

			{/* ========== PAGE 3 ========== */}
			<Box
				sx={{
					padding: 4,
					height: "297mm",
					display: "flex",
					flexDirection: "column",
					pageBreakBefore: "always",
				}}
			>
				{/* PAGE HEADER */}
				<Box
					sx={{
						borderBottom: "3px solid #667eea",
						pb: 1,
						mb: 3,
					}}
				>
					<Typography variant="h5" fontWeight="bold" color="primary">
						Insights & Recommendations
					</Typography>
				</Box>

				{/* KEY INSIGHTS */}
				<Card
					elevation={3}
					sx={{
						mb: 3,
						background:
							"linear-gradient(135deg, #fff5f5 0%, #ffe5e5 100%)",
						border: "2px solid #ff6b6b",
					}}
				>
					<CardContent>
						<Typography
							variant="h6"
							gutterBottom
							fontWeight="bold"
							sx={{ color: "#c92a2a", mb: 2 }}
						>
							🎯 Key Insights
						</Typography>
						<Box component="ul" sx={{ pl: 2, "& li": { mb: 1.5 } }}>
							<li>
								<Typography variant="body1" paragraph sx={{ lineHeight: 1.8 }}>
									<strong style={{ color: "#2f9e44" }}>📊 Attendance Status:</strong>{" "}
									{attendance.avgAttendancePercent >= 80 ? (
										<Chip
											label="Excellent"
											color="success"
											size="small"
											sx={{ ml: 1, fontWeight: "bold" }}
										/>
									) : attendance.avgAttendancePercent >= 70 ? (
										<Chip
											label="Good"
											color="primary"
											size="small"
											sx={{ ml: 1, fontWeight: "bold" }}
										/>
									) : (
										<Chip
											label="Needs Improvement"
											color="error"
											size="small"
											sx={{ ml: 1, fontWeight: "bold" }}
										/>
									)}
									<br />
									Average attendance is at{" "}
									<strong style={{ color: "#1971c2" }}>
										{attendance.avgAttendancePercent}%
									</strong>{" "}
									across {attendance.totalSessions} sessions.
								</Typography>
							</li>
							<li>
								<Typography variant="body1" paragraph sx={{ lineHeight: 1.8 }}>
									<strong style={{ color: "#7048e8" }}>🎓 Academic Performance:</strong>{" "}
									Average quiz score across all classes is{" "}
									<strong
										style={{
											color: avgQuizScore >= 70 ? "#2f9e44" : "#e03131",
										}}
									>
										{avgQuizScore}%
									</strong>
									.{" "}
									{avgQuizScore < 70 ? (
										<span style={{ color: "#e03131", fontWeight: "bold" }}>
											This indicates need for academic intervention.
										</span>
									) : (
										<span style={{ color: "#2f9e44", fontWeight: "bold" }}>
											Performance is satisfactory.
										</span>
									)}
								</Typography>
							</li>
							<li>
								<Typography variant="body1" paragraph sx={{ lineHeight: 1.8 }}>
									<strong style={{ color: "#f76707" }}>📚 Learning Gaps:</strong> The
									most challenging concept is{" "}
									<strong style={{ color: "#e03131" }}>"{topWeakConcept}"</strong> with{" "}
									<strong style={{ color: "#1971c2" }}>
										{weakConcepts[0]?.count || 0}
									</strong>{" "}
									students struggling. Focus remedial teaching on top 3 weak
									concepts.
								</Typography>
							</li>
							<li>
								<Typography variant="body1" paragraph sx={{ lineHeight: 1.8 }}>
									<strong style={{ color: "#d6336c" }}>👨‍🏫 Teacher Workload:</strong>{" "}
									<strong
										style={{
											color: overloadedTeachers > 0 ? "#e03131" : "#2f9e44",
										}}
									>
										{overloadedTeachers}
									</strong>{" "}
									teacher(s) have high workload ({">"}500 minutes planned tasks).
									Consider workload balancing.
								</Typography>
							</li>
							<li>
								<Typography variant="body1" paragraph sx={{ lineHeight: 1.8 }}>
									<strong style={{ color: "#0ca678" }}>💬 Community Engagement:</strong>{" "}
									<strong style={{ color: "#1971c2" }}>
										{communityData.summary.totalQuestions}
									</strong>{" "}
									questions with{" "}
									<strong style={{ color: "#1971c2" }}>
										{communityData.summary.totalAnswers}
									</strong>{" "}
									answers (avg: {communityData.summary.avgAnswersPerQuestion}{" "}
									answers/question) shows{" "}
									<strong
										style={{
											color:
												communityData.summary.avgAnswersPerQuestion >= 2
													? "#2f9e44"
													: "#f59f00",
										}}
									>
										{communityData.summary.avgAnswersPerQuestion >= 2
											? "strong"
											: "moderate"}
									</strong>{" "}
									peer learning culture.
								</Typography>
							</li>
						</Box>
					</CardContent>
				</Card>

				{/* RECOMMENDATIONS */}
				<Card
					elevation={3}
					sx={{
						mb: 3,
						background:
							"linear-gradient(135deg, #e7f5ff 0%, #d0ebff 100%)",
						border: "2px solid #339af0",
					}}
				>
					<CardContent>
						<Typography
							variant="h6"
							gutterBottom
							fontWeight="bold"
							sx={{ color: "#1971c2", mb: 2 }}
						>
							💡 Recommended Actions
						</Typography>
						<TableContainer>
							<Table size="small">
								<TableHead>
									<TableRow sx={{ backgroundColor: "#228be6" }}>
										<TableCell sx={{ color: "#fff", fontWeight: "bold" }}>
											AREA
										</TableCell>
										<TableCell sx={{ color: "#fff", fontWeight: "bold" }}>
											PRIORITY
										</TableCell>
										<TableCell sx={{ color: "#fff", fontWeight: "bold" }}>
											ACTION ITEM
										</TableCell>
									</TableRow>
								</TableHead>
								<TableBody>
									{attendance.avgAttendancePercent < 75 && (
										<TableRow sx={{ "&:hover": { backgroundColor: "#f1f3f5" } }}>
											<TableCell sx={{ fontWeight: 600, color: "#495057" }}>
												Attendance
											</TableCell>
											<TableCell>
												<Chip
													label="HIGH"
													color="error"
													size="small"
													sx={{ fontWeight: "bold" }}
												/>
											</TableCell>
											<TableCell>
												Implement attendance improvement program for low
												performing classes
											</TableCell>
										</TableRow>
									)}
									{avgQuizScore < 70 && (
										<TableRow sx={{ "&:hover": { backgroundColor: "#f1f3f5" } }}>
											<TableCell sx={{ fontWeight: 600, color: "#495057" }}>
												Academic
											</TableCell>
											<TableCell>
												<Chip
													label="HIGH"
													color="error"
													size="small"
													sx={{ fontWeight: "bold" }}
												/>
											</TableCell>
											<TableCell>
												Conduct remedial classes focusing on weak concepts
											</TableCell>
										</TableRow>
									)}
									{weakConcepts.length > 0 && (
										<TableRow sx={{ "&:hover": { backgroundColor: "#f1f3f5" } }}>
											<TableCell sx={{ fontWeight: 600, color: "#495057" }}>
												Learning Gaps
											</TableCell>
											<TableCell>
												<Chip
													label="MEDIUM"
													color="warning"
													size="small"
													sx={{ fontWeight: "bold" }}
												/>
											</TableCell>
											<TableCell>
												Create targeted learning modules for top 5 weak concepts
											</TableCell>
										</TableRow>
									)}
									{overloadedTeachers > 0 && (
										<TableRow sx={{ "&:hover": { backgroundColor: "#f1f3f5" } }}>
											<TableCell sx={{ fontWeight: 600, color: "#495057" }}>
												Workload
											</TableCell>
											<TableCell>
												<Chip
													label="MEDIUM"
													color="warning"
													size="small"
													sx={{ fontWeight: "bold" }}
												/>
											</TableCell>
											<TableCell>
												Redistribute tasks among teachers for better balance
											</TableCell>
										</TableRow>
									)}
									<TableRow sx={{ "&:hover": { backgroundColor: "#f1f3f5" } }}>
										<TableCell sx={{ fontWeight: 600, color: "#495057" }}>
											Engagement
										</TableCell>
										<TableCell>
											<Chip
												label="LOW"
												color="success"
												size="small"
												sx={{ fontWeight: "bold" }}
											/>
										</TableCell>
										<TableCell>
											Encourage more peer-to-peer learning through community
											platform
										</TableCell>
									</TableRow>
								</TableBody>
							</Table>
						</TableContainer>
					</CardContent>
				</Card>

				{/* SUMMARY STATISTICS */}
				<Card elevation={3}>
					<CardContent>
						<Typography variant="h6" gutterBottom fontWeight="bold">
							📋 Summary Statistics
						</Typography>
						<Grid container spacing={2}>
							<Grid size={{ xs: 6 }}>
								<Typography variant="body2" color="textSecondary">
									Report Period
								</Typography>
								<Typography variant="body1" fontWeight="bold">
									{new Date(
										Math.min(
										...attendance.trend.map((t) =>
												new Date(t.date).getTime()
											)
										)
									).toLocaleDateString()}{" "}
									-{" "}
									{new Date(
										Math.max(
										...attendance.trend.map((t) =>
												new Date(t.date).getTime()
											)
										)
									).toLocaleDateString()}
								</Typography>
							</Grid>
							<Grid size={{ xs: 6 }}>
								<Typography variant="body2" color="textSecondary">
									Data Points Analyzed
								</Typography>
								<Typography variant="body1" fontWeight="bold">
									{attendance.totalSessions} sessions, {quizPerformance.length}{" "}
									classes, {teacherWorkload.length} teachers
								</Typography>
							</Grid>
						</Grid>
					</CardContent>
				</Card>

				{/* FOOTER */}
				<Box sx={{ mt: "auto", pt: 3, borderTop: "1px solid #ddd" }}>
					<Typography variant="caption" color="textSecondary" align="center">
						This report is confidential and intended for internal use only. •
						Generated by Institute Analytics System
					</Typography>
				</Box>
			</Box>
		</Box>
	);
}
