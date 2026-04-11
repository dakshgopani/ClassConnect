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
} from "@mui/material";
import { useNavigate } from "react-router-dom";
import VisibilityIcon from "@mui/icons-material/Visibility";
import { getAllClasses, type ClassData } from "../../services/classes.service";

export default function ClassesPage() {
  const [classes, setClasses] = useState<ClassData[]>([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    const collegeName = localStorage.getItem("collegeName") || undefined;
    getAllClasses(collegeName).then((data) => {
      setClasses(data);
      setLoading(false);
    });
  }, []);

  if (loading) {
    return (
      <Box sx={{ display: "flex", justifyContent: "center", mt: 4 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      <Typography variant="h4" gutterBottom sx={{ color: "primary.main", mb: 3 }}>
        All Classes
      </Typography>
      <TableContainer component={Paper} sx={{ p: 1, borderRadius: "20px" }}>
        <Table sx={{ minWidth: 650 }} aria-label="classes table">
          <TableHead>
            <TableRow>
              <TableCell>Class Name</TableCell>
              {/* <TableCell align="center">Grade</TableCell> */}
              {/* <TableCell align="center">Section</TableCell> */}
              <TableCell align="center">Students</TableCell>
              <TableCell align="right">Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {classes.length === 0 ? (
              <TableRow>
                 <TableCell colSpan={5} align="center">No classes found.</TableCell>
              </TableRow>
            ) : (
                classes.map((cls) => (
                <TableRow
                    key={cls.id}
                    sx={{ "&:last-child td, &:last-child th": { border: 0 } }}
                >
                    <TableCell component="th" scope="row" sx={{ fontWeight: 600 }}>
                    {cls.name}
                    </TableCell>
                    {/* <TableCell align="center">{cls.grade}</TableCell> */}
                    {/* <TableCell align="center">{cls.section}</TableCell> */}
                    <TableCell align="center">{cls.studentCount}</TableCell>
                    <TableCell align="right">
                    <Button
                        variant="contained"
                        size="small"
                        startIcon={<VisibilityIcon />}
                        onClick={() => navigate(`/classes/${cls.id}`)}
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
