import html2canvas from "html2canvas";
import jsPDF from "jspdf";

export const exportExecutiveSummaryPdf = async () => {
	const element = document.getElementById("executive-summary");
	if (!element) {
		console.error("Executive summary element not found");
		return;
	}

	// Show loading state (optional)
	const originalCursor = document.body.style.cursor;
	document.body.style.cursor = "wait";

	try {
		// Get all pages (children of the main container)
		const pages = element.children;
		const pdf = new jsPDF("p", "mm", "a4");
		const pdfWidth = 210; // A4 width in mm
		const pdfHeight = 297; // A4 height in mm

		for (let i = 0; i < pages.length; i++) {
			const page = pages[i] as HTMLElement;

			// Capture the page as canvas with high quality
			const canvas = await html2canvas(page, {
				backgroundColor: "#ffffff",
				scale: 2, // Higher scale for better quality
				useCORS: true,
				logging: false,
				windowWidth: 794, // A4 width in pixels (210mm * 96dpi / 25.4)
				windowHeight: 1123, // A4 height in pixels (297mm * 96dpi / 25.4)
			});

			const imgData = canvas.toDataURL("image/jpeg", 0.95);

			// Add new page if not the first page
			if (i > 0) {
				pdf.addPage();
			}

			// Calculate dimensions to fit A4
			const imgWidth = pdfWidth;
			const imgHeight = (canvas.height * pdfWidth) / canvas.width;

			// If image is taller than A4, scale it down to fit
			if (imgHeight > pdfHeight) {
				const scaledWidth = (canvas.width * pdfHeight) / canvas.height;
				pdf.addImage(imgData, "JPEG", 0, 0, scaledWidth, pdfHeight);
			} else {
				pdf.addImage(imgData, "JPEG", 0, 0, imgWidth, imgHeight);
			}
		}

		// Generate filename with timestamp
		const timestamp = new Date().toISOString().split("T")[0];
		const filename = `Institute_Executive_Report_${timestamp}.pdf`;

		// Save the PDF
		pdf.save(filename);
	} catch (error) {
		console.error("Error generating PDF:", error);
		alert("Failed to generate PDF. Please try again.");
	} finally {
		// Restore cursor
		document.body.style.cursor = originalCursor;
	}
};
