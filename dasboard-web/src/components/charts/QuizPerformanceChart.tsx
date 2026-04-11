import {
	BarChart,
	Bar,
	XAxis,
	YAxis,
	Tooltip,
	ResponsiveContainer,
} from "recharts";
import { Card, CardContent, Typography } from "@mui/material";
import PropTypes from "prop-types";
// import { QuizPerformanceMetric } from "../../services/analytics.service";

import { CustomTooltip } from "./CustomTooltip";

type QuizPerformanceChartProps = {
	data: {
		className: string;
		averageScore: number;
	}[];
};

export default function QuizPerformanceChart({ data }: QuizPerformanceChartProps) {
	return (
		<Card sx={{ height: 350 }}>
			<CardContent>
				<Typography variant="h6" gutterBottom>
					Average Quiz Score by Class (%)
				</Typography>

				<ResponsiveContainer width="100%" height={280}>
					<BarChart data={data}>
						<XAxis dataKey="className" tick={{ fill: "#fff" }} />
						<YAxis domain={[0, 100]} tick={{ fill: "#fff" }} />
						<Tooltip content={<CustomTooltip suffix="%" />} />
						<Bar dataKey="averageScore" fill="#48cae4" />
					</BarChart>
				</ResponsiveContainer>
			</CardContent>
		</Card>
	);
}

QuizPerformanceChart.propTypes = {
	data: PropTypes.arrayOf(
		PropTypes.shape({
			className: PropTypes.string.isRequired,
			averageScore: PropTypes.number.isRequired,
		}),
	).isRequired,
};
