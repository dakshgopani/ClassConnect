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

export default function StudentQuizTrendChart({ data }: any) {
  return (
    <Card sx={{ height: 360 }}>
      <CardContent>
        <Typography variant="h6">
          Quiz Performance Trend
        </Typography>

        <ResponsiveContainer width="100%" height={280}>
          <LineChart data={data}>
            <XAxis dataKey="date" tick={{ fill: "#fff" }} />
            <YAxis domain={[0, 100]} tick={{ fill: "#fff" }} />
            <Tooltip content={<CustomTooltip suffix="%" />} />
            <Line
              type="monotone"
              dataKey="score"
              stroke="#48cae4"
              strokeWidth={2}
            />
          </LineChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
}
