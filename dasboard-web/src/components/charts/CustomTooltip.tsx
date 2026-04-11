import { Box, Typography } from "@mui/material";

interface CustomTooltipProps {
  active?: boolean;
  payload?: any[];
  label?: string | number;
  suffix?: string;
  valueFormatter?: (value: number) => string;
}

export const CustomTooltip = ({
  active,
  payload,
  label,
  suffix = "",
  valueFormatter,
}: CustomTooltipProps) => {
  if (active && payload && payload.length) {
    return (
      <Box
        sx={{
          backgroundColor: "rgba(15, 28, 63, 0.95)",
          border: "1px solid rgba(96, 165, 250, 0.2)",
          borderRadius: "12px",
          padding: "16px",
          backdropFilter: "blur(12px)",
          boxShadow: "0 8px 32px rgba(0, 0, 0, 0.4)",
          minWidth: 150,
        }}
      >
        <Typography
          variant="subtitle2"
          sx={{
            color: "#94A3B8",
            mb: 1.5,
            display: "block",
            fontSize: "0.85rem",
            fontWeight: 600,
            textTransform: "uppercase",
            letterSpacing: "0.05em",
            borderBottom: "1px solid rgba(255,255,255,0.1)",
            pb: 1,
          }}
        >
          {label}
        </Typography>
        <Box sx={{ display: "flex", flexDirection: "column", gap: 1 }}>
          {payload.map((entry: any, index: number) => {
            const displayValue = valueFormatter
              ? valueFormatter(entry.value)
              : `${entry.value}${suffix}`;

            return (
              <Box
                key={index}
                sx={{
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "space-between",
                  gap: 2,
                }}
              >
                <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
                  <Box
                    sx={{
                      width: 8,
                      height: 8,
                      borderRadius: "50%",
                      backgroundColor: entry.color, // Recharts passes the line/bar color here
                      boxShadow: `0 0 8px ${entry.color}`,
                    }}
                  />
                  <Typography
                    variant="body2"
                    sx={{ color: "#E2E8F0", fontWeight: 500 }}
                  >
                    {entry.name}:
                  </Typography>
                </Box>
                <Typography
                  variant="body2"
                  sx={{ color: "#60A5FA", fontWeight: 700 }}
                >
                  {displayValue}
                </Typography>
              </Box>
            );
          })}
        </Box>
      </Box>
    );
  }

  return null;
};
