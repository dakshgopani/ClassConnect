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

export default function StudentWeakConceptsChart({ data }: any) {
  return (
    <Card sx={{ height: 360 }}>
      <CardContent>
        <Typography variant="h6">
          Weak Concepts
        </Typography>

        <ResponsiveContainer width="100%" height={280}>
          <BarChart
            data={data}
            layout="vertical"
            margin={{ left: 120 }}
          >
            <XAxis type="number" tick={{ fill: "#fff" }} />
            <YAxis
              type="category"
              dataKey="concept"
              width={180}
              tick={{ fill: "#fff" }}
            />
            <Tooltip content={<CustomTooltip />} />
            <Bar dataKey="count" fill="#023e8a" />
          </BarChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
}
