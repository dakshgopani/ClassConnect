import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import { Card, CardContent, Typography } from "@mui/material";
import type { WeakConceptMetric } from "../../services/analytics.service";

import { CustomTooltip } from "./CustomTooltip";

export default function WeakConceptsChart({
  data,
}: {
  data: WeakConceptMetric[];
}) {
  return (
    <Card sx={{ height: 380 }}>
      <CardContent>
        <Typography variant="h6" gutterBottom>
          Top Weak Concepts (Institute-wide)
        </Typography>

        <ResponsiveContainer width="100%" height={300}>
          <BarChart
            data={data}
            layout="vertical"
            margin={{ left: 100 }}
          >
            <XAxis type="number" tick={{ fill: "#fff" }} />
            <YAxis
              dataKey="concept"
              type="category"
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
