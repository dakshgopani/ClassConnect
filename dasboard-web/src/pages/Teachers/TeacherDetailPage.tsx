import { useParams } from "react-router-dom";
import {
  Typography,
  Grid,
  Card,
  CardContent,
} from "@mui/material";
import { useEffect, useState } from "react";
import {
  getTeacherSummary,
  getTeacherTaskTrend,
} from "../../services/teacherAnalytics.service";
import TeacherTaskTrendChart from "../../components/charts/TeacherTaskTrendChart";
import TeacherWorkloadBar from "../../components/charts/TeacherWorkloadBar";

export default function TeacherDetailPage() {
  const { teacherId } = useParams<{ teacherId: string }>();

  const [summary, setSummary] = useState<any>(null);
  const [trend, setTrend] = useState([]);

  useEffect(() => {
    if (teacherId) {
      getTeacherSummary(teacherId).then(setSummary);
      getTeacherTaskTrend(teacherId).then(setTrend);
    }
  }, [teacherId]);

  return (
    <>
      <Typography variant="h5" gutterBottom>
        Teacher Productivity
      </Typography>

      <Typography variant="body2" color="text.secondary">
        Teacher ID: {teacherId}
      </Typography>

      <Grid container spacing={2} mt={2}>
        <Grid size = {{xs:12,md:3}}>
          <Card>
            <CardContent>
              <Typography variant="subtitle2">
                Total Tasks
              </Typography>
              <Typography variant="h5">
                {summary?.totalTasks ?? "—"}
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid size = {{xs:12,md:3}}>
          <Card>
            <CardContent>
              <Typography variant="subtitle2">
                Completed Tasks
              </Typography>
              <Typography variant="h5">
                {summary?.completedTasks ?? "—"}
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid size = {{xs:12,md:3}}>
          <Card>
            <CardContent>
              <Typography variant="subtitle2">
                Completion Rate
              </Typography>
              <Typography variant="h5">
                {summary?.completionRate ?? "—"}%
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid size = {{xs:12,md:3}}>
          <Card>
            <CardContent>
              <Typography variant="subtitle2">
                Workload (min)
              </Typography>
              <Typography variant="h5">
                {summary?.completedMinutes}/
                {summary?.plannedMinutes}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Grid container spacing={2} mt={3}>
        <Grid size = {{xs:12,md:6}}>
          <TeacherTaskTrendChart data={trend} />
        </Grid>

        <Grid size = {{xs:12,md:6}}>
          <TeacherWorkloadBar summary={summary} />
        </Grid>
      </Grid>
    </>
  );
}
