import {
	BarChart,
	Bar,
	XAxis,
	YAxis,
	Tooltip,
	ResponsiveContainer,
	Legend,
} from "recharts";
import { Card, CardContent, Typography } from "@mui/material";
import type { TeacherWorkloadMetric } from "../../services/analytics.service";
import { useNavigate } from "react-router-dom";

import { CustomTooltip } from "./CustomTooltip";

export default function TeacherWorkloadChart({
  data,
}: {
  data: TeacherWorkloadMetric[];
}) {
  const navigate = useNavigate();

  return (
    <Card sx={{ height: 380 }}>
      <CardContent>
        <Typography variant="h6" gutterBottom>
          Teacher Workload & Productivity
        </Typography>

        <ResponsiveContainer width="100%" height={300}>
          <BarChart data={data}>
            <XAxis dataKey="teacherName" tick={{ fill: "#fff" }} />
            <YAxis tick={{ fill: "#fff" }} />
            <Tooltip content={<CustomTooltip />} />
            <Legend wrapperStyle={{ color: "#fff" }} />

            <Bar
              dataKey="plannedMinutes"
              name="Planned Minutes"
              fill="#48cae4"
              onClick={(d) => {
                const teacherId = (d as any)?.payload?.teacherId;
                if (teacherId) {
                  navigate(`/teachers/${teacherId}`);
                }
              }}
            />

            <Bar
              dataKey="completedMinutes"
              name="Completed Minutes"
              fill="#0096c7"
              onClick={(d) => {
                const teacherId = (d as any)?.payload?.teacherId;
                if (teacherId) {
                  navigate(`/teachers/${teacherId}`);
                }
              }}
            />
          </BarChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
}
