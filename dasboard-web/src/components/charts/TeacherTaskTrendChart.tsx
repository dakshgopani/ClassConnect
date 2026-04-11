import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import { Card, CardContent, Typography } from "@mui/material";

import { CustomTooltip } from "./CustomTooltip";

export default function TeacherTaskTrendChart({ data }: any) {
  return (
    <Card sx={{ height: 360 }}>
      <CardContent>
        <Typography variant="h6">
          Task Completion Trend
        </Typography>

        <ResponsiveContainer width="100%" height={280}>
          <LineChart data={data}>
            <XAxis dataKey="date" tick={{ fill: "#fff" }} />
            <YAxis tick={{ fill: "#fff" }} />
            <Tooltip content={<CustomTooltip />} />
            <Line
              type="monotone"
              dataKey="completedTasks"
              stroke="#0096c7"
              strokeWidth={2}
            />
          </LineChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
}
