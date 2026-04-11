import {
	Table,
	TableHead,
	TableRow,
	TableCell,
	TableBody,
	Paper,
} from "@mui/material";

export default function ClassAttendanceTable({ data }: { data: any[] }) {
	return (
		<Paper sx={{ mt: 3 }}>
			<Table>
				<TableHead>
					<TableRow>
						<TableCell>Class ID</TableCell>
						<TableCell align="right">Attendance %</TableCell>
						<TableCell align="right">Sessions</TableCell>
					</TableRow>
				</TableHead>

				<TableBody>
					{data.map((c) => (
						<TableRow key={c.classId}>
							<TableCell>{c.classId}</TableCell>
							<TableCell align="right">{c.attendancePercent}%</TableCell>
							<TableCell align="right">{c.sessions}</TableCell>
						</TableRow>
					))}
				</TableBody>
			</Table>
		</Paper>
	);
}
