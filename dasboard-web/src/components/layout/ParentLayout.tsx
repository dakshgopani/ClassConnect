import { Box, Container } from "@mui/material";
import { Outlet } from "react-router-dom";
import ParentSidebar from "./ParentSidebar";

export default function ParentLayout() {
  return (
    <Box sx={{ display: "flex", minHeight: "100vh" }}>
      <ParentSidebar />
      <Box
        component="main"
        sx={{
          flexGrow: 1,
          p: 3,
          width: { sm: `calc(100% - 280px)` },
          mt: 2,
          overflowX: "hidden"
        }}
      >
        <Container maxWidth="xl">
            <Outlet />
        </Container>
      </Box>
    </Box>
  );
}
