import { createTheme } from "@mui/material/styles";

// Color Palette based on #0F1C3F
const colors = {
  primary: "#0F1C3F", // Deep Navy Blue
  secondary: "#1E3A8A", // Lighter Navy
  accent: "#60A5FA", // Sky Blue Accent
  background: "#0B1530", // Slightly darker than primary for void
  textPrimary: "#F8FAFC",
  textSecondary: "#94A3B8",
  glass: "rgba(15, 28, 63, 0.7)", // Glass base derived from primary
  glassBorder: "rgba(96, 165, 250, 0.2)",
};

export const theme = createTheme({
  palette: {
    mode: "dark",
    background: {
      default: colors.background,
      paper: colors.glass,
    },
    primary: {
      main: colors.accent, // Use accent as primary for buttons/highlights
      contrastText: "#000",
    },
    secondary: {
      main: colors.secondary,
    },
    text: {
      primary: colors.textPrimary,
      secondary: colors.textSecondary,
    },
  },
  typography: {
    fontFamily: '"Inter", "Roboto", "Helvetica", "Arial", sans-serif',
    h1: { fontWeight: 700, letterSpacing: "-0.01em" },
    h2: { fontWeight: 700, letterSpacing: "-0.005em" },
    h3: { fontWeight: 600 },
    h4: { fontWeight: 600, letterSpacing: "0.02em" }, // Added spacing
    h5: { fontWeight: 600 },
    h6: { fontWeight: 600 },
    subtitle1: { letterSpacing: "0.05em" },
    button: { fontWeight: 600, textTransform: "none" },
  },
  shape: {
    borderRadius: 16,
  },
  components: {
    MuiCssBaseline: {
      styleOverrides: {
        body: {
          background: `linear-gradient(145deg, ${colors.background} 0%, ${colors.primary} 100%)`,
          backgroundAttachment: "fixed",
          minHeight: "100vh",
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          backdropFilter: "blur(16px)",
          backgroundColor: colors.glass,
          border: `1px solid ${colors.glassBorder}`,
          boxShadow: "0 8px 32px 0 rgba(0, 0, 0, 0.4)",
          borderRadius: "20px", // More rounded
        },
      },
    },
    MuiButton: {
      styleOverrides: {
        root: {
            borderRadius: "12px",
            padding: "8px 24px", // More horizontal padding
            fontSize: "0.95rem",
        },
        contained: {
            boxShadow: "0 4px 14px 0 rgba(0,0,0,0.3)",
        },
      },
    },
    MuiTableCell: {
      styleOverrides: {
        root: {
          borderBottom: `1px solid rgba(255, 255, 255, 0.05)`,
          padding: "20px 24px", // Increased padding for tables
          fontSize: "0.95rem",
        },
        head: {
          fontWeight: 700,
          color: colors.accent,
          textTransform: "uppercase",
          letterSpacing: "0.1em",
          fontSize: "0.75rem",
        },
      },
    },
    MuiTableRow: {
      styleOverrides: {
        root: {
          "&:last-child td": { border: 0 },
          transition: "background-color 0.2s",
          "&:hover": {
            backgroundColor: "rgba(255, 255, 255, 0.03)", // Subtle hover effect
          },
        },
      },
    },
    MuiContainer: {
        styleOverrides: {
            root: {
                paddingTop: "24px",
                paddingBottom: "24px",
            }
        }
    }
  },
});
