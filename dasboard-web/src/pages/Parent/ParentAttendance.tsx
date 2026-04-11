import { useEffect, useState } from "react";
import { 
  Box, 
  Typography, 
  CircularProgress,
  Card,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip
} from "@mui/material";
import { parentService } from "../../services/parent.service";

export default function ParentAttendance() {
  const [loading, setLoading] = useState(true);
  const [attendance, setAttendance] = useState<any[]>([]);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const studentId = localStorage.getItem("studentId");
        if (studentId) {
          const stats = await parentService.getStudentStats(studentId);
          if (stats.classIds && stats.classIds.length > 0) {
              const data = await parentService.getStudentAttendance(studentId, stats.classIds);
              setAttendance(data);
          }
        }
      } catch (error) {
        console.error("error", error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  if (loading) {
    return <Box p={4} display="flex" justifyContent="center"><CircularProgress /></Box>;
  }

  return (
    <Box>
      <Typography variant="h4" sx={{ fontWeight: 800, color: "text.primary", mb: 4 }}>
        Detailed Attendance
      </Typography>

      <Card sx={{ borderRadius: "20px", overflow: "hidden" }}>
        <TableContainer>
          <Table>
            <TableHead sx={{ backgroundColor: "rgba(255,255,255,0.05)" }}>
              <TableRow>
                <TableCell sx={{ fontWeight: 600, color: "text.secondary" }}>Date</TableCell>
                <TableCell sx={{ fontWeight: 600, color: "text.secondary" }}>Class</TableCell>
                <TableCell sx={{ fontWeight: 600, color: "text.secondary" }}>Teacher</TableCell>
                <TableCell sx={{ fontWeight: 600, color: "text.secondary" }}>Status</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {attendance.length === 0 ? (
                 <TableRow>
                     <TableCell colSpan={4} align="center" sx={{ py: 6, color: 'text.secondary' }}>
                         No attendance records found.
                     </TableCell>
                 </TableRow>
              ) : (
                attendance.map((record) => (
                    <TableRow key={record.id} hover sx={{ '&:hover': { backgroundColor: 'rgba(255,255,255,0.05)' } }}>
                    <TableCell sx={{ fontWeight: 500, color: 'text.primary' }}>
                        {record.date}
                    </TableCell>
                    <TableCell sx={{ color: 'text.secondary' }}>
                        {record.className || "N/A"}
                    </TableCell>
                    <TableCell sx={{ color: 'text.secondary' }}>
                        {record.teacherName || "N/A"}
                    </TableCell>
                    <TableCell>
                        <Chip 
                            label={record.status} 
                            size="small"
                            sx={{
                                fontWeight: 700,
                                borderRadius: '8px',
                                backgroundColor: record.status === 'Present' ? 'rgba(16, 185, 129, 0.1)' : 'rgba(239, 68, 68, 0.1)',
                                color: record.status === 'Present' ? '#10B981' : '#EF4444'
                            }} 
                        />
                    </TableCell>
                    </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </TableContainer>
      </Card>
    </Box>
  );
}
