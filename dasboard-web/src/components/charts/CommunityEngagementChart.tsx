import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from "recharts";
import { Card, CardContent, Typography } from "@mui/material";


import { CustomTooltip } from "./CustomTooltip";

type CommunityEngagementDataPoint = {
  date: string;
  questions: number;
  answers: number;
};

export default function CommunityEngagementChart({
  data,
}: {
  data: CommunityEngagementDataPoint[];
}) {
  return (
    <Card sx={{ height: 380 }}>
      <CardContent>
        <Typography variant="h6" gutterBottom>
          Community Engagement Trend
        </Typography>

        <ResponsiveContainer width="100%" height={300}>
          <LineChart data={data}>
            <XAxis dataKey="date" tick={{ fill: "#fff" }} />
            <YAxis tick={{ fill: "#fff" }} />
            <Tooltip content={<CustomTooltip />} />
            <Legend wrapperStyle={{ color: "#fff" }} />
            <Line
              type="monotone"
              dataKey="questions"
              stroke="#48cae4"
              name="Questions"
            />
            <Line
              type="monotone"
              dataKey="answers"
              stroke="#0096c7"
              name="Answers"
            />
          </LineChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
}
