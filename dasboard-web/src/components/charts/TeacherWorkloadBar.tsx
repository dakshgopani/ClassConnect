import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import { Card, CardContent, Typography } from "@mui/material";

import { CustomTooltip } from "./CustomTooltip";

export default function TeacherWorkloadBar({ summary }: any) {
  if (!summary) return null;

  const data = [
    {
      label: "Workload",
      Planned: summary.plannedMinutes,
      Completed: summary.completedMinutes,
    },
  ];

  return (
    <Card sx={{ height: 360 }}>
      <CardContent>
        <Typography variant="h6">
          Planned vs Completed Work
        </Typography>

        <ResponsiveContainer width="100%" height={280}>
          <BarChart data={data}>
            <XAxis dataKey="label" tick={{ fill: "#fff" }} />
            <YAxis tick={{ fill: "#fff" }} />
            <Tooltip content={<CustomTooltip />} />
            <Bar dataKey="Planned" fill="#48cae4" />
            <Bar dataKey="Completed" fill="#0096c7" />
          </BarChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
}
