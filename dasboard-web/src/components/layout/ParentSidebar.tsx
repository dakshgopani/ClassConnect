import {
  Box,
  Drawer,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Typography,
  Avatar,
  Divider,
  useTheme,
} from "@mui/material";
import {
  Dashboard as DashboardIcon,
  EventAvailable as AttendanceIcon,
  Assignment as AssignmentIcon,
  Quiz as QuizIcon,
  People as TeachersIcon,
  Logout as LogoutIcon,
} from "@mui/icons-material";
import { useLocation, useNavigate } from "react-router-dom";

const DRAWER_WIDTH = 280;

export default function ParentSidebar() {
  const navigate = useNavigate();
  const location = useLocation();
  const theme = useTheme();

  const studentName = localStorage.getItem("studentName") || "Student";

  const menuItems = [
    { text: "Overview", icon: <DashboardIcon />, path: "/parent/overview" },
    { text: "Attendance", icon: <AttendanceIcon />, path: "/parent/attendance" },
    { text: "Assignments", icon: <AssignmentIcon />, path: "/parent/assignments" },
    { text: "Quizzes", icon: <QuizIcon />, path: "/parent/quizzes" },
    { text: "Teachers", icon: <TeachersIcon />, path: "/parent/teachers" },
  ];

  const handleLogout = () => {
    localStorage.removeItem("isAuthenticated");
    localStorage.removeItem("userRole");
    localStorage.removeItem("studentId");
    localStorage.removeItem("studentName");
    navigate("/login");
  };

  return (
    <Drawer
      variant="permanent"
      sx={{
        width: DRAWER_WIDTH,
        flexShrink: 0,
        "& .MuiDrawer-paper": {
          width: DRAWER_WIDTH,
          boxSizing: "border-box",
          // Theme handles background/glass
          p: 2,
          overflow: "hidden", // Prevent scrolling
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
          Parent Dashboard
        </Typography>
        </Box>   
        <Box
          sx={{
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: 1,
            mb: 2,
            p: 1.5,
            borderRadius: "16px",
            backgroundColor: "rgba(255, 255, 255, 0.03)",
            border: "1px solid rgba(255, 255, 255, 0.05)"
          }}
        >
          <Avatar sx={{ bgcolor: theme.palette.primary.main, width: 32, height: 32, fontSize: '1rem' }}>{studentName.charAt(0)}</Avatar>
          <Box sx={{ overflow: "hidden", textAlign: 'left' }}>
            <Typography variant="subtitle2" sx={{ color: "text.primary", fontWeight: 600, fontSize: '0.85rem' }} noWrap>
                {studentName}
            </Typography>
          </Box>
        </Box>
        {/* <Box sx={{ mb: 4, px: 2, textAlign: "center" }}>
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
          Parent Portal
        </Typography>
      </Box> */}
          
      <List>
        {menuItems.map((item) => {
          const isActive = location.pathname === item.path;
          return (
            <ListItem key={item.text} disablePadding sx={{ mb: 1 }}>
              <ListItemButton
                onClick={() => navigate(item.path)}
                selected={isActive}
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
                <ListItemIcon
                  sx={{
                    minWidth: 40,
                    color: isActive ? "#60A5FA" : "text.secondary",
                  }}
                >
                  {item.icon}
                </ListItemIcon>
                <ListItemText
                  primary={item.text}
                  primaryTypographyProps={{
                    fontWeight: isActive ? 600 : 500,
                  }}
                />
              </ListItemButton>
            </ListItem>
          );
        })}
      </List>

      <Box sx={{ mt: "auto", p: 2 }}>
        <Divider sx={{ mb: 2, borderColor: "rgba(255,255,255,0.1)" }} />
        <ListItemButton
          onClick={handleLogout}
          sx={{
            borderRadius: "12px",
            color: "#EF4444",
            "&:hover": {
              backgroundColor: "rgba(239, 68, 68, 0.1)",
            },
          }}
        >
          <ListItemIcon sx={{ minWidth: 40, color: "#EF4444" }}>
            <LogoutIcon />
          </ListItemIcon>
          <ListItemText primary="Sign Out" />
        </ListItemButton>
      </Box>
    </Drawer>
  );
}
