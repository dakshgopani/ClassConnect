import { Button, CircularProgress } from "@mui/material";
import { useState } from "react";
import { exportExecutiveSummaryPdf } from "../services/pdfExport.service";
import PictureAsPdfIcon from "@mui/icons-material/PictureAsPdf";

export default function ExportPdfButton() {
	const [isExporting, setIsExporting] = useState(false);

	const handleExport = async () => {
		setIsExporting(true);
		try {
			await exportExecutiveSummaryPdf();
		} finally {
			setIsExporting(false);
		}
	};

	return (
		<Button
			variant="contained"
			color="secondary"
			onClick={handleExport}
			disabled={isExporting}
			startIcon={
				isExporting ? (
					<CircularProgress size={20} color="inherit" />
				) : (
					<PictureAsPdfIcon />
				)
			}
			sx={{
				fontWeight: 600,
				px: 3,
				py: 1,
			}}
		>
			{isExporting ? "Generating PDF..." : "Export Executive Report"}
		</Button>
	);
}
