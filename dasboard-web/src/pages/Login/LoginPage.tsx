import { useState } from "react";
import {
  Box,
  Button,
  Card,
  CardContent,
  TextField,
  Typography,
  Alert,
  InputAdornment,
  IconButton,
  ToggleButton,
  ToggleButtonGroup,
  CircularProgress
} from "@mui/material";
import { useNavigate } from "react-router-dom";
import { Visibility, VisibilityOff, School, FamilyRestroom } from "@mui/icons-material";
import { collection, query, where, getDocs } from "firebase/firestore";
import { db } from "../../firebase/firebase";

export default function LoginPage() {
  const navigate = useNavigate();

  const [loginMode, setLoginMode] = useState<"admin" | "parent">("admin");
  
  // Admin State
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [collegeNameInput, setCollegeNameInput] = useState("");
  
  // Parent State
  const [phoneNumber, setPhoneNumber] = useState("");
  const [parentEmail, setParentEmail] = useState("");

  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  // Hardcoded Admin Credentials
  const ADMIN_EMAIL = "admin";
  const ADMIN_PASSWORD = "admin@123";

  const handleLogin = async () => {
    setError("");
    setLoading(true);

    try {
      if (loginMode === "admin") {
        // Simulate network delay for admin
        await new Promise(resolve => setTimeout(resolve, 800));
        
        // Check Firestore for Admin first (to get College Name)
        let adminCollege = "";
        try {
            const adminsRef = collection(db, "admins");
            const q = query(adminsRef, where("email", "==", email));
            const querySnapshot = await getDocs(q);
            if (!querySnapshot.empty) {
                const adminData = querySnapshot.docs[0].data();
                adminCollege = adminData.collegeSchoolName || "";
                
                // If password matches DB
                if (adminData.password === password) {
                     localStorage.setItem("isAuthenticated", "true");
                     localStorage.setItem("userRole", "admin");
                     
                     // Prioritize manual input, otherwise use DB value
                     if (collegeNameInput.trim()) {
                         localStorage.setItem("collegeName", collegeNameInput.trim());
                     } else if (adminCollege) {
                         localStorage.setItem("collegeName", adminCollege);
                     } else {
                         localStorage.removeItem("collegeName");
                     }

                     navigate("/");
                     return;
                }
            }
        } catch (e) {
            console.log("Admin Firestore Login failed, falling back to hardcoded");
        }

        if (email === ADMIN_EMAIL && password === ADMIN_PASSWORD) {
          localStorage.setItem("isAuthenticated", "true");
          localStorage.setItem("userRole", "admin");
          
          if (collegeNameInput.trim()) {
              localStorage.setItem("collegeName", collegeNameInput.trim());
          } else {
              localStorage.removeItem("collegeName");
          }
          
          navigate("/");
        } else {
          setError("Invalid admin credentials. Please try again.");
        }
      } else {
        // Parent Login Logic
        if (!phoneNumber || !parentEmail) {
            setError("Please enter both phone number and email.");
            setLoading(false);
            return;
        }

        const studentsRef = collection(db, "students");
        const q = query(studentsRef, where("parentPhoneNumber", "==", phoneNumber));
        const querySnapshot = await getDocs(q);

        if (!querySnapshot.empty) {
            // Assuming the first match is the correct one for now
            const studentDoc = querySnapshot.docs[0];
            const studentData = studentDoc.data();
            
            // Verify Parent Email
            if (studentData.parentEmail !== parentEmail) {
                setError("Email does not match our records for this phone number.");
                setLoading(false);
                return;
            }
            
            localStorage.setItem("isAuthenticated", "true");
            localStorage.setItem("userRole", "parent");
            localStorage.setItem("studentId", studentData.uid || studentDoc.id);
            localStorage.setItem("studentName", studentData.name);
            
            navigate("/parent/overview");
        } else {
            setError("Phone number not found. Please contact the school administrator.");
        }
      }
    } catch (err) {
        console.error("Login Error:", err);
        setError("An error occurred during login. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter") {
      handleLogin();
    }
  };

  const handleModeChange = (
    event: React.MouseEvent<HTMLElement>,
    newMode: "admin" | "parent" | null
  ) => {
    if (newMode !== null) {
      setLoginMode(newMode);
      setError("");
    }
  };

  return (
    <Box
      display="flex"
      justifyContent="center"
      alignItems="center"
      height="100vh"
      sx={{
        background: "linear-gradient(135deg, #0f1c3f 0%, #172a58 100%)",
      }}
    >
      <Card
        sx={{
          width: 380,
          backgroundColor: "rgba(15, 28, 63, 0.7)",
          backdropFilter: "blur(12px)",
          border: "1px solid rgba(96, 165, 250, 0.2)",
          borderRadius: "20px",
          boxShadow: "0 8px 32px 0 rgba(0, 0, 0, 0.5)",
        }}
        elevation={0}
      >
        <CardContent sx={{ p: 4 }}>
          <Box textAlign="center" mb={3}>
            <Typography
              variant="h4"
              sx={{
                fontWeight: 700,
                color: "#60A5FA",
                textShadow: "0 0 10px rgba(96, 165, 250, 0.5)",
                mb: 1,
              }}
            >
              Portal Access
            </Typography>
            <Typography variant="body2" sx={{ color: "#94A3B8" }}>
              Select your role to continue
            </Typography>
          </Box>

          <Box display="flex" justifyContent="center" mb={4}>
            <ToggleButtonGroup
              value={loginMode}
              exclusive
              onChange={handleModeChange}
              aria-label="login mode"
              sx={{
                backgroundColor: "rgba(0, 0, 0, 0.2)",
                borderRadius: "12px",
                "& .MuiToggleButton-root": {
                  color: "#94A3B8",
                  borderColor: "rgba(96, 165, 250, 0.3)",
                  "&.Mui-selected": {
                    color: "white",
                    backgroundColor: "rgba(96, 165, 250, 0.2)",
                    "&:hover": {
                        backgroundColor: "rgba(96, 165, 250, 0.3)",
                    }
                  },
                  "&:hover": {
                    backgroundColor: "rgba(255, 255, 255, 0.05)",
                  },
                },
              }}
            >
              <ToggleButton value="admin" sx={{ px: 3, textTransform: 'none' }}>
                <School sx={{ mr: 1, fontSize: 20 }} />
                Admin
              </ToggleButton>
              <ToggleButton value="parent" sx={{ px: 3, textTransform: 'none' }}>
                <FamilyRestroom sx={{ mr: 1, fontSize: 20 }} />
                Parent
              </ToggleButton>
            </ToggleButtonGroup>
          </Box>

          {error && (
            <Alert
              severity="error"
              sx={{ mb: 3, borderRadius: "10px", fontSize: "0.9rem" }}
            >
              {error}
            </Alert>
          )}

          {loginMode === "admin" ? (
            <>
              <TextField
                label="Username"
                fullWidth
                margin="normal"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                onKeyDown={handleKeyDown}
                sx={{
                  "& .MuiOutlinedInput-root": {
                    "& fieldset": { borderColor: "rgba(96, 165, 250, 0.3)" },
                    "&:hover fieldset": { borderColor: "#60A5FA" },
                    "&.Mui-focused fieldset": { borderColor: "#60A5FA" },
                    color: "white",
                    borderRadius: "12px",
                    backgroundColor: "rgba(0,0,0,0.2)",
                  },
                  "& .MuiInputLabel-root": { color: "#94A3B8" },
                  "& .MuiInputLabel-root.Mui-focused": { color: "#60A5FA" },
                }}
              />

              <TextField
                label="Password"
                type={showPassword ? "text" : "password"}
                fullWidth
                margin="normal"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                onKeyDown={handleKeyDown}
                InputProps={{
                  endAdornment: (
                    <InputAdornment position="end">
                      <IconButton
                        onClick={() => setShowPassword(!showPassword)}
                        edge="end"
                        sx={{ color: "#94A3B8" }}
                      >
                        {showPassword ? <VisibilityOff /> : <Visibility />}
                      </IconButton>
                    </InputAdornment>
                  ),
                }}
                sx={{
                  "& .MuiOutlinedInput-root": {
                    "& fieldset": { borderColor: "rgba(96, 165, 250, 0.3)" },
                    "&:hover fieldset": { borderColor: "#60A5FA" },
                    "&.Mui-focused fieldset": { borderColor: "#60A5FA" },
                    color: "white",
                    borderRadius: "12px",
                    backgroundColor: "rgba(0,0,0,0.2)",
                  },
                  "& .MuiInputLabel-root": { color: "#94A3B8" },
                  "& .MuiInputLabel-root.Mui-focused": { color: "#60A5FA" },
                }}
              />

              <TextField
                label="College Name (Optional)"
                placeholder="Enter to view specific institute data"
                fullWidth
                margin="normal"
                value={collegeNameInput}
                onChange={(e) => setCollegeNameInput(e.target.value)}
                onKeyDown={handleKeyDown}
                sx={{
                  "& .MuiOutlinedInput-root": {
                    "& fieldset": { borderColor: "rgba(96, 165, 250, 0.3)" },
                    "&:hover fieldset": { borderColor: "#60A5FA" },
                    "&.Mui-focused fieldset": { borderColor: "#60A5FA" },
                    color: "white",
                    borderRadius: "12px",
                    backgroundColor: "rgba(0,0,0,0.2)",
                  },
                  "& .MuiInputLabel-root": { color: "#94A3B8" },
                  "& .MuiInputLabel-root.Mui-focused": { color: "#60A5FA" },
                }}
              />
            </>
          ) : (
            <>
              <TextField
                label="Registered Phone Number"
                placeholder="e.g., 9876543210"
                fullWidth
                margin="normal"
                value={phoneNumber}
                onChange={(e) => setPhoneNumber(e.target.value)}
                onKeyDown={handleKeyDown}
                sx={{
                  "& .MuiOutlinedInput-root": {
                    "& fieldset": { borderColor: "rgba(96, 165, 250, 0.3)" },
                    "&:hover fieldset": { borderColor: "#60A5FA" },
                    "&.Mui-focused fieldset": { borderColor: "#60A5FA" },
                    color: "white",
                    borderRadius: "12px",
                    backgroundColor: "rgba(0,0,0,0.2)",
                  },
                  "& .MuiInputLabel-root": { color: "#94A3B8" },
                  "& .MuiInputLabel-root.Mui-focused": { color: "#60A5FA" },
                }}
              />
              <TextField
                label="Registered Parent Email"
                placeholder="e.g., parent@example.com"
                fullWidth
                margin="normal"
                value={parentEmail}
                onChange={(e) => setParentEmail(e.target.value)}
                onKeyDown={handleKeyDown}
                sx={{
                  "& .MuiOutlinedInput-root": {
                    "& fieldset": { borderColor: "rgba(96, 165, 250, 0.3)" },
                    "&:hover fieldset": { borderColor: "#60A5FA" },
                    "&.Mui-focused fieldset": { borderColor: "#60A5FA" },
                    color: "white",
                    borderRadius: "12px",
                    backgroundColor: "rgba(0,0,0,0.2)",
                  },
                  "& .MuiInputLabel-root": { color: "#94A3B8" },
                  "& .MuiInputLabel-root.Mui-focused": { color: "#60A5FA" },
                }}
              />
            </>
          )}

          <Button
            variant="contained"
            fullWidth
            size="large"
            disabled={loading}
            onClick={handleLogin}
            sx={{
              mt: 4,
              py: 1.5,
              fontWeight: 700,
              fontSize: "1rem",
              textTransform: "uppercase",
              letterSpacing: "0.1em",
              backgroundColor: "#60A5FA",
              "&:hover": {
                backgroundColor: "#3B82F6",
                boxShadow: "0 0 15px rgba(59, 130, 246, 0.5)",
              },
            }}
          >
            {loading ? <CircularProgress size={24} color="inherit" /> : `Login as ${loginMode === 'admin' ? 'Admin' : 'Parent'}`}
          </Button>
        </CardContent>
      </Card>
    </Box>
  );
}
