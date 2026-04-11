import { useParams } from "react-router-dom";
import {
  Typography,
  Grid,
  Card,
  CardContent,
} from "@mui/material";
import { useEffect, useState } from "react";
import {
  getStudentSummary,
  getStudentQuizTrend,
  getStudentWeakConcepts,
} from "../../services/studentAnalytics.service";
import StudentQuizTrendChart from "../../components/charts/StudentQuizTrendChart";
import StudentWeakConceptsChart from "../../components/charts/StudentWeakConceptsChart";
import { type QuizTrendPoint } from "../../services/studentAnalytics.service";
import { type WeakConceptMetric } from "../../services/studentAnalytics.service";
export default function StudentDetailPage() {
  const { studentId } = useParams<{ studentId: string }>();

  const [summary, setSummary] = useState<any>(null);
  const [quizTrend, setQuizTrend] = useState<QuizTrendPoint[]>([]);
  const [weakConcepts, setWeakConcepts] = useState<WeakConceptMetric[]>([]);

  useEffect(() => {
    if (studentId) {
      getStudentSummary(studentId).then(setSummary);
      getStudentQuizTrend(studentId).then(setQuizTrend);
      getStudentWeakConcepts(studentId).then(setWeakConcepts);
    }
  }, [studentId]);

  return (
    <>
      <Typography variant="h5" gutterBottom>
        Student Profile
      </Typography>

      <Typography variant="body2" color="text.secondary">
        Student ID: {studentId}
      </Typography>

      <Grid container spacing={2} mt={2}>
        <Grid size = {{xs:12,md:3}}>
          <Card>
            <CardContent>
              <Typography variant="subtitle2">Name</Typography>
              <Typography variant="h6">{summary?.name}</Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid size = {{xs:12,md:3}}>
          <Card>
            <CardContent>
              <Typography variant="subtitle2">Quiz Attempts</Typography>
              <Typography variant="h5">
                {summary?.quizAttempts ?? "—"}
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid size  = {{xs:12,md:3}}>
          <Card>
            <CardContent>
              <Typography variant="subtitle2">Avg Quiz Score</Typography>
              <Typography variant="h5">
                {summary?.avgQuizScore ?? "—"}%
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid size = {{xs:12,md:3}}>
          <Card>
            <CardContent>
              <Typography variant="subtitle2">PBL Submissions</Typography>
              <Typography variant="h5">
                {summary?.pblSubmissions ?? "—"}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Grid container spacing={2} mt={3}>
        <Grid size = {{xs:12,md:6}}>
          <StudentQuizTrendChart data={quizTrend} />
        </Grid>

        <Grid size = {{xs:12,md:6}}>
          <StudentWeakConceptsChart data={weakConcepts} />
        </Grid>
      </Grid>
    </>
  );
}
