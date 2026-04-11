import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import { Card, CardContent, Typography } from "@mui/material";
import type { QuizTrendPoint } from "../../services/classAnalytics.service";
import { CustomTooltip } from "./CustomTooltip";

export default function ClassQuizTrendChart({
  data,
}: {
  data: QuizTrendPoint[];
}) {
  return (
    <Card sx={{ height: 360 }}>
      <CardContent>
        <Typography variant="h6" gutterBottom>
          Quiz Performance Trend
        </Typography>

        <ResponsiveContainer width="100%" height={280}>
          <LineChart data={data}>
            <XAxis dataKey="date" tick={{ fill: "#fff" }} />
            <YAxis domain={[0, 100]} tick={{ fill: "#fff" }} />
						<Tooltip content={<CustomTooltip suffix="%" />} />
            <Line
              type="monotone"
              dataKey="avgScore"
              stroke="#48cae4"
              strokeWidth={2}
            />
          </LineChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
}
