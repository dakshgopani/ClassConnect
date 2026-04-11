import {
  Drawer,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Box,
  Typography,
  Divider,
} from "@mui/material";
import DashboardIcon from "@mui/icons-material/Dashboard";
import SchoolIcon from "@mui/icons-material/School";
import PersonIcon from "@mui/icons-material/Person";
import GroupIcon from "@mui/icons-material/Group";

import LogoutIcon from "@mui/icons-material/Logout";
import { useLocation, useNavigate } from "react-router-dom";

const drawerWidth = 280;

export default function Sidebar() {
  const navigate = useNavigate();
  const location = useLocation();

  const menuItems = [
    { text: "Overview", icon: <DashboardIcon />, path: "/" },
    { text: "Classes", icon: <SchoolIcon />, path: "/classes" },
    { text: "Teachers", icon: <PersonIcon />, path: "/teachers" },
    { text: "Students", icon: <GroupIcon />, path: "/students" },
  ];

  return (
    <Drawer
      variant="permanent"
      sx={{
        width: drawerWidth,
        flexShrink: 0,
        "& .MuiDrawer-paper": {
          width: drawerWidth,
          boxSizing: "border-box",
          padding: 2,
        },
      }}
    >
      <Box sx={{ mb: 4, px: 2, textAlign: "center" }}>
        <Typography
          variant="h5"
          fontWeight="bold"
          sx={{
            background: "linear-gradient(45deg, #60A5FA, #3B82F6)",
            backgroundClip: "text",
            textFillColor: "transparent",
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
            mb: 1,
            letterSpacing: 2
          }}
        >
          ClassConnect
        </Typography>
        <Typography variant="caption" color="text.secondary">
          Admin Dashboard
        </Typography>
      </Box>

      <List>
        {menuItems.map((item) => (
          <ListItem key={item.text} disablePadding sx={{ mb: 1 }}>
            <ListItemButton
              selected={location.pathname === item.path}
              onClick={() => navigate(item.path)}
              sx={{
                borderRadius: "16px",
                my: 0.5,
                mx: 1,
                "&.Mui-selected": {
                  background: "rgba(96, 165, 250, 0.15)",
                  border: "1px solid rgba(96, 165, 250, 0.3)",
                  "& .MuiListItemIcon-root": {
                    color: "#60A5FA",
                  },
                },
                "&:hover": {
                  backgroundColor: "rgba(255, 255, 255, 0.05)",
                  transform: "translateX(5px)",
                  transition: "transform 0.2s",
                },
              }}
            >
              <ListItemIcon sx={{ color: "text.secondary", minWidth: 40 }}>
                {item.icon}
              </ListItemIcon>
              <ListItemText primary={item.text} primaryTypographyProps={{ fontWeight: 500 }} />
            </ListItemButton>
          </ListItem>
        ))}
      </List>
      
      <Box sx={{ flexGrow: 1 }} />
      <Divider sx={{ my: 2, borderColor: "rgba(255,255,255,0.1)" }} />
      
      <List>
         <ListItem disablePadding>
            <ListItemButton 
              sx={{ borderRadius: "12px", color: "#ef5350" }}
              onClick={() => {
                const confirmLogout = window.confirm("Are you sure you want to logout?");
                if (confirmLogout) {
                  localStorage.removeItem("isAuthenticated");
                  navigate("/login");
                }
              }}
            >
              <ListItemIcon sx={{ color: "#ef5350", minWidth: 40 }}>
                <LogoutIcon />
              </ListItemIcon>
              <ListItemText primary="Logout" />
            </ListItemButton>
          </ListItem>
      </List>
    </Drawer>
  );
}
