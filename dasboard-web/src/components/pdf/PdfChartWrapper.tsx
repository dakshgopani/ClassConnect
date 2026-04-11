import { Box, Typography, Card, CardContent } from "@mui/material";

export default function PdfChartWrapper({
	children,
	title,
}: {
	children: React.ReactNode;
	title?: string;
}) {
	return (
		<Card elevation={2} sx={{ mb: 2 }}>
			<CardContent>
				{title && (
					<Typography
						variant="h6"
						gutterBottom
						sx={{ fontWeight: 600, color: "#333", mb: 2 }}
					>
						{title}
					</Typography>
				)}
				<Box
					sx={{
						width: "100%",
						height: 280,
						overflow: "hidden",
						backgroundColor: "#fff",
						"& .recharts-wrapper": {
							margin: "0 auto",
						},
					}}
				>
					{children}
				</Box>
			</CardContent>
		</Card>
	);
}
