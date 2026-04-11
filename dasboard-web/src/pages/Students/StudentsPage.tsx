import { useEffect, useState } from "react";
import {
  Box,
  Typography,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Button,
  CircularProgress,
  TextField,
} from "@mui/material";
import { useNavigate } from "react-router-dom";
import VisibilityIcon from "@mui/icons-material/Visibility";
import { getAllStudents, type StudentData } from "../../services/users.service";

export default function StudentsPage() {
  const [students, setStudents] = useState<StudentData[]>([]);
  const [loading, setLoading] = useState(true);
  const [department, setDepartment] = useState("");
  const navigate = useNavigate();

  useEffect(() => {
    const collegeName = localStorage.getItem("collegeName") || undefined;
    const deptFilter = department.trim() || undefined;

    getAllStudents(collegeName, deptFilter).then((data) => {
      setStudents(data);
      setLoading(false);
    });
  }, [department]);

  if (loading) {
    return (
      <Box sx={{ display: "flex", justifyContent: "center", mt: 4 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4" sx={{ color: "primary.main" }}>
            Student Roster
        </Typography>
        <TextField 
            label="Filter Dept" 
            size="small" 
            value={department}
            onChange={(e) => setDepartment(e.target.value)}
            placeholder="e.g. CSE"
            sx={{ width: 200 }}
        />
      </Box>
      <TableContainer component={Paper} sx={{ p: 1, borderRadius: "20px" }}>
        <Table sx={{ minWidth: 650 }} aria-label="students table">
          <TableHead>
            <TableRow>
              <TableCell>Name</TableCell>
              {/* <TableCell>Roll No</TableCell> */}
              <TableCell>Class</TableCell>
              <TableCell align="right">Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
             {students.length === 0 ? (
              <TableRow>
                 <TableCell colSpan={4} align="center">No students found.</TableCell>
              </TableRow>
            ) : (
                students.map((student) => (
                <TableRow
                    key={student.id}
                    sx={{ "&:last-child td, &:last-child th": { border: 0 } }}
                >
                    <TableCell component="th" scope="row" sx={{ fontWeight: 600 }}>
                    {student.name}
                    </TableCell>
                    {/* <TableCell>{student.rollNo}</TableCell> */}
                    <TableCell>{student.className || "N/A"}</TableCell>
                    <TableCell align="right">
                    <Button
                        variant="contained"
                        size="small"
                        startIcon={<VisibilityIcon />}
                        onClick={() => navigate(`/students/${student.id}`)}
                    >
                        View
                    </Button>
                    </TableCell>
                </TableRow>
                ))
            )}
          </TableBody>
        </Table>
      </TableContainer>
    </Box>
  );
}
