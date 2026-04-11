import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import { Card, CardContent, Typography } from "@mui/material";
import type { ClassSizeMetric } from "../../services/analytics.service";
import { useNavigate } from "react-router-dom";

import { CustomTooltip } from "./CustomTooltip";

type BarClickPayload = {
  payload?: { classId?: string };
};

export default function ClassSizeChart({ data }: { data: ClassSizeMetric[] }) {
  const navigate = useNavigate();

  return (
    <Card sx={{ height: 350 }}>
      <CardContent>
        <Typography variant="h6" gutterBottom>
          Class Size Distribution
        </Typography>

        <ResponsiveContainer width="100%" height={280}>
          <BarChart data={data}>
            <XAxis dataKey="className" tick={{ fill: "#fff" }} />
            <YAxis tick={{ fill: "#fff" }} />
            <Tooltip content={<CustomTooltip />} />

            <Bar
              dataKey="studentCount"
              fill="#48cae4"
              onClick={(chartData: BarClickPayload) => {
                const classId = chartData.payload?.classId;
                if (classId) {
                  navigate(`/classes/${classId}`);
                }
              }}
            />
          </BarChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
}
