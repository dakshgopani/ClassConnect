import { Card, CardContent, Typography } from "@mui/material";

export default function MetricCard({
  title,
  value,
}: {
  title: string;
  value: number;
}) {
  return (
    <Card>
      <CardContent>
        <Typography variant="subtitle2">{title}</Typography>
        <Typography variant="h4">{value}</Typography>
      </CardContent>
    </Card>
  );
}
