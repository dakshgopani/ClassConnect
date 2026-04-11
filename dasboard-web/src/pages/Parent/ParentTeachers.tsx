import { useEffect, useState } from "react";
import { 
  Box, 
  Typography, 
  CircularProgress,
  Card,
  Grid,
  Avatar,
  Button,
  Chip
} from "@mui/material";
import { Email } from "@mui/icons-material";
import { parentService } from "../../services/parent.service";

export default function ParentTeachers() {
  const [loading, setLoading] = useState(true);
  const [classes, setClasses] = useState<any[]>([]);
  const [teachers, setTeachers] = useState<Record<string, any>>({}); // Map teacherId to teacher data

  useEffect(() => {
    const fetchData = async () => {
      try {
        const studentId = localStorage.getItem("studentId");
        if (studentId) {
          const stats = await parentService.getStudentStats(studentId);
          if (stats.classIds && stats.classIds.length > 0) {
              const classesData = await parentService.getClassDetails(stats.classIds);
              setClasses(classesData);
              
              const teacherIds = classesData.map((c: any) => c.teacherId).filter(Boolean);
              const uniqueTeacherIds = Array.from(new Set(teacherIds));
              
              const teachersData = await parentService.getTeachers(uniqueTeacherIds);
              
              const teacherMap: Record<string, any> = {};
              teachersData.forEach((t: any) => {
                  teacherMap[t.uid || t.id] = t; 
              });
              setTeachers(teacherMap);
          }
        }
      } catch (error) {
        console.error("error", error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  if (loading) {
    return <Box p={4} display="flex" justifyContent="center"><CircularProgress /></Box>;
  }

  return (
    <Box>
      <Typography variant="h4" sx={{ fontWeight: 800, color: "text.primary", mb: 4 }}>
        Teachers & Classes
      </Typography>

      <Grid container spacing={3}>
          {classes.map((cls) => {
              const teacher = teachers[cls.teacherId];
              return (
                  <Grid size={{xs:12, md:6}} key={cls.id}>
                      <Card sx={{ p: 3, height: '100%' }}>
                          <Box display="flex" justifyContent="space-between" alignItems="start" mb={2}>
                              <Box>
                                <Typography variant="h6" fontWeight={700} color="text.primary">
                                    {cls.class_name || "Class Name"}
                                </Typography>
                                <Typography variant="body2" color="text.secondary">
                                    Subject: {cls.subject || "General"}
                                </Typography>
                              </Box>
                              <Chip label={cls.class_code} size="small" variant="outlined" sx={{ fontWeight: 600 }} />
                          </Box>

                          {teacher ? (
                              <Box 
                                sx={{ 
                                    mt: 3, 
                                    p: 2, 
                                    bgcolor: 'rgba(255, 255, 255, 0.05)', 
                                    borderRadius: '16px',
                                    display: 'flex',
                                    alignItems: 'center',
                                    gap: 2
                                }}
                              >
                                  <Avatar src={teacher.photoUrl} alt={teacher.name} sx={{ width: 48, height: 48 }} />
                                  <Box flexGrow={1}>
                                      <Typography variant="subtitle2" fontWeight={700} color="text.primary">
                                          {teacher.name}
                                      </Typography>
                                      <Typography variant="caption" color="text.secondary">
                                          Teacher
                                      </Typography>
                                  </Box>
                              </Box>
                          ) : (
                              <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
                                  Teacher information unavailable.
                              </Typography>
                          )}
                          
                          {teacher && (
                             <Box display="flex" gap={2} mt={2}>
                                {teacher.email && (
                                    <Button 
                                        variant="outlined" 
                                        startIcon={<Email />} 
                                        fullWidth 
                                        href={`mailto:${teacher.email}`}
                                        sx={{ borderRadius: '12px', textTransform: 'none' }}
                                    >
                                        Email
                                    </Button>
                                )}
                             </Box>
                          )}
                      </Card>
                  </Grid>
              );
          })}
      </Grid>
    </Box>
  );
}
