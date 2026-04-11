import {
	Table,
	TableHead,
	TableRow,
	TableCell,
	TableBody,
	Paper,
} from "@mui/material";
import { useNavigate } from "react-router-dom";
import type { ClassStudentRow } from "../../services/classAnalytics.service";

export default function ClassStudentsTable({
	students,
}: {
	students: ClassStudentRow[];
}) {
	const navigate = useNavigate();

	return (
		<Paper sx={{ mt: 3 }}>
			<Table>
				<TableHead>
					<TableRow>
						<TableCell>Student</TableCell>
						<TableCell align="right">Quiz Attempts</TableCell>
						<TableCell align="right">Avg Score (%)</TableCell>
					</TableRow>
				</TableHead>

				<TableBody>
					{students.map((s) => (
						<TableRow key={s.studentId}>
							<TableCell
								sx={{
									cursor: "pointer",
									color: "primary.main",
									fontWeight: 500,
								}}
								onClick={() => navigate(`/students/${s.studentId}`)}
							>
								{s.name}
							</TableCell>

							<TableCell align="right">{s.quizAttempts}</TableCell>

							<TableCell align="right">{s.avgQuizScore}</TableCell>
						</TableRow>
					))}
				</TableBody>
			</Table>
		</Paper>
	);
}
