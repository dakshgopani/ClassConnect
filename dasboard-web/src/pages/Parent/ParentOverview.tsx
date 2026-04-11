import { useEffect, useState } from "react";
import { 
  Box, 
  Grid, 
  Card, 
  CardContent, 
  Typography, 
  CircularProgress,
  LinearProgress
} from "@mui/material";
import { 
  TrendingUp, 
  EventAvailable, 
  EmojiEvents,
  Person,
  School,
  Email,
  Phone
} from "@mui/icons-material";
import { parentService } from "../../services/parent.service";

// Types for stats
// Types for stats
interface StudentStats {
  xp: number;
  attendancePercentage: number;
  presentCount: number;
  absentCount: number;
  totalClasses: number;
  classIds: string[];
  totalAssignments?: number;
  quizAverage?: number;
  studentProfile?: {
      name: string;
      email: string;
      studentClass: string;
      studentRollNo: string;
      studentSem: number;
      parentEmail: string;
      parentPhoneNumber: string;
      photoUrl: string;
      role: string;
      collegeSchoolName?: string;
      studentDepartment?: string;
  };
}

export default function ParentOverview() {
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState<StudentStats | null>(null);

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const studentId = localStorage.getItem("studentId");
        if (studentId) {
          const data = await parentService.getStudentStats(studentId);
          setStats(data as unknown as StudentStats);
        }
      } catch (error) {
        console.error("Failed to fetch stats", error);
      } finally {
        setLoading(false);
      }
    };
    
    fetchStats();
  }, []);

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="60vh">
        <CircularProgress />
      </Box>
    );
  }

  const StatCard = ({ title, value, icon, gradient, subtitle }: any) => (
    <Card 
        sx={{ 
            height: '100%', 
            position: 'relative',
            overflow: 'hidden',
            borderRadius: '24px',
            boxShadow: '0 10px 30px rgba(0,0,0,0.1)'
        }}
    >
      <Box 
        sx={{ 
            position: 'absolute', 
            top: 0, 
            left: 0, 
            width: '100%', 
            height: '6px', 
            background: gradient 
        }} 
      />
      <CardContent sx={{ p: 4 }}>
        <Box display="flex" justifyContent="space-between" alignItems="flex-start">
          <Box>
            <Typography variant="body1" sx={{ color: 'text.secondary', fontWeight: 600, mb: 1 }}>
              {title}
            </Typography>
            <Typography variant="h3" sx={{ fontWeight: 800, color: 'text.primary' }}>
              {value}
            </Typography>
            {subtitle && (
                <Typography variant="body2" sx={{ color: 'text.secondary', mt: 1, opacity: 0.8 }}>
                    {subtitle}
                </Typography>
            )}
          </Box>
          <Box 
            sx={{ 
                p: 2, 
                borderRadius: '16px', 
                background: `${gradient}20`, 
                color: gradient.split(' ')[2] 
            }}
          >
            {icon} 
          </Box>
        </Box>
      </CardContent>
    </Card>
  );

  return (
    <Box>
      {/* Header Section */}
      <Box mb={5}>
        <Typography variant="h4" sx={{ fontWeight: 800, color: "text.primary", mb: 1 }}>
            Welcome, {stats?.studentProfile?.name?.split(' ')[0] || "Parent"}
        </Typography>
         {stats?.studentProfile?.collegeSchoolName && (
            <Typography variant="h6" sx={{ color: "primary.main", fontWeight: 600, opacity: 0.9 }}>
                {stats?.studentProfile?.collegeSchoolName}
            </Typography>
        )}
      </Box>

      {/* Metrics Grid */}
      <Grid container spacing={4} mb={5}>
        {/* Attendance Card */}
        <Grid size={{xs:12, sm:6, md:3}}>
          <StatCard
            title="Attendance"
            value={`${stats?.attendancePercentage || 0}%`}
            subtitle={`${stats?.presentCount || 0}/${stats?.totalClasses || 0} Sessions`}
            icon={<EventAvailable sx={{ color: '#10B981' }} />}
            gradient="linear-gradient(135deg, #10B981 0%, #059669 100%)"
          />
        </Grid>

        {/* Quiz Performance Card */}
         <Grid size={{xs:12, sm:6, md:3}}>
          <StatCard
            title="Quiz Avg"
            value={`${stats?.quizAverage || 0}%`}
            subtitle="Recent Performance"
            icon={<EmojiEvents sx={{ color: '#F59E0B' }} />}
            gradient="linear-gradient(135deg, #F59E0B 0%, #D97706 100%)"
          />
        </Grid>

         {/* Assignments Card */}
         <Grid size={{xs:12, sm:6, md:3}}>
          <StatCard
            title="Assignments"
            value={stats?.totalAssignments || 0}
            subtitle="Total Assigned"
            icon={<School sx={{ color: '#3B82F6' }} />}
            gradient="linear-gradient(135deg, #3B82F6 0%, #2563EB 100%)"
          />
        </Grid>

        {/* XP / Gamification Card */}
        <Grid size={{xs:12, sm:6, md:3}}>
          <StatCard
            title="Total XP"
            value={stats?.xp || 0}
            subtitle="Gamified Progress"
            icon={<TrendingUp sx={{ color: '#6366F1' }} />}
            gradient="linear-gradient(135deg, #6366F1 0%, #4F46E5 100%)"
          />
        </Grid>
      </Grid>
      
      {/* Detailed Profile Info Section */}
       <Box sx={{ mt: 4 }}>
        <Typography variant="h6" sx={{ fontWeight: 700, mb: 2, color: 'text.primary' }}>
            Student Profile Details
        </Typography>
        <Card sx={{ p: 0, borderRadius: '24px', boxShadow: '0 10px 30px rgba(0,0,0,0.1)' }}>
            <Box 
                sx={{ 
                    height: '8px', 
                    background: "linear-gradient(90deg, #6366F1 0%, #EC4899 100%)"
                }} 
            />
            <CardContent sx={{ p: 4 }}>
                <Grid container spacing={3} alignItems="center">
                    <Grid size={{xs: 12, md: 2}} display="flex" justifyContent="center">
                         <Box
                            component="img"
                            src={stats?.studentProfile?.photoUrl || `https://ui-avatars.com/api/?name=${stats?.studentProfile?.name || 'Student'}`}
                            sx={{ 
                                width: 100, 
                                height: 100, 
                                borderRadius: '50%',
                                border: '4px solid rgba(99, 102, 241, 0.2)'
                            }}
                        />
                    </Grid>
                    <Grid size={{xs: 12, md: 10}}>
                        <Grid container spacing={2}>
                            <Grid size={{xs: 12}}>
                                <Typography variant="h5" fontWeight="bold">
                                    {stats?.studentProfile?.name}
                                </Typography>
                            </Grid>
                            
                             <Grid size={{xs: 6, md: 3}}>
                                <Typography variant="caption" color="text.secondary" fontWeight="bold">CLASS</Typography>
                                <Typography variant="body1" fontWeight="500">{stats?.studentProfile?.studentClass}</Typography>
                            </Grid>
                            <Grid size={{xs: 6, md: 3}}>
                                <Typography variant="caption" color="text.secondary" fontWeight="bold">ROLL NO</Typography>
                                <Typography variant="body1" fontWeight="500">{stats?.studentProfile?.studentRollNo}</Typography>
                            </Grid>
                             <Grid size={{xs: 6, md: 3}}>
                                <Typography variant="caption" color="text.secondary" fontWeight="bold">DEPARTMENT</Typography>
                                <Typography variant="body1" fontWeight="500">{stats?.studentProfile?.studentDepartment || 'N/A'}</Typography>
                            </Grid>
                             <Grid size={{xs: 6, md: 3}}>
                                <Typography variant="caption" color="text.secondary" fontWeight="bold">SEMESTER</Typography>
                                <Typography variant="body1" fontWeight="500">{stats?.studentProfile?.studentSem}</Typography>
                            </Grid>
                        </Grid>
                        
                        <Box mt={3} p={2} bgcolor="rgba(0,0,0,0.02)" borderRadius="12px">
                            <Grid container spacing={2}>
                                <Grid size={{xs:12, md:6}}>
                                    <Box display="flex" alignItems="center" gap={2} mb={1}>
                                        <Email sx={{ color: 'text.secondary', fontSize: 20 }} />
                                        <Box>
                                            <Typography variant="caption" color="text.secondary">Student Email</Typography>
                                            <Typography variant="body2" fontWeight={500}>{stats?.studentProfile?.email || "N/A"}</Typography>
                                        </Box>
                                    </Box>
                                     <Box display="flex" alignItems="center" gap={2}>
                                        <Person sx={{ color: 'text.secondary', fontSize: 20 }} />
                                        <Box>
                                            <Typography variant="caption" color="text.secondary">Parent Email</Typography>
                                            <Typography variant="body2" fontWeight={500}>{stats?.studentProfile?.parentEmail || "N/A"}</Typography>
                                        </Box>
                                    </Box>
                                </Grid>
                                <Grid size={{xs:12, md:6}}>
                                     <Box display="flex" alignItems="center" gap={2}>
                                        <Phone sx={{ color: 'text.secondary', fontSize: 20 }} />
                                        <Box>
                                            <Typography variant="caption" color="text.secondary">Parent Phone</Typography>
                                            <Typography variant="body2" fontWeight={500}>{stats?.studentProfile?.parentPhoneNumber || "N/A"}</Typography>
                                        </Box>
                                    </Box>
                                </Grid>
                            </Grid>
                        </Box>
                    </Grid>
                </Grid>
            </CardContent>
        </Card>
      </Box>

        {/* Attendance Progress Bar Visual */}
       <Box sx={{ mt: 6 }}>
        <Typography variant="h6" sx={{ fontWeight: 700, mb: 2, color: 'text.primary' }}>
            Attendance Health
        </Typography>
         <Card sx={{ p: 4, borderRadius: '24px', boxShadow: '0 10px 30px rgba(0,0,0,0.1)' }}>
            <Box display="flex" alignItems="center" justifyContent="space-between" mb={1}>
                <Typography variant="body2" fontWeight={600} color="text.secondary">
                    Overall Attendance
                </Typography>
                <Typography variant="body2" fontWeight={700} color={ (stats?.attendancePercentage || 0) < 75 ? "error.main" : "success.main" }>
                    {stats?.attendancePercentage}%
                </Typography>
            </Box>
            <LinearProgress 
                variant="determinate" 
                value={stats?.attendancePercentage || 0} 
                sx={{ 
                    height: 10, 
                    borderRadius: 5,
                    backgroundColor: 'rgba(255,255,255,0.1)',
                    '& .MuiLinearProgress-bar': {
                        backgroundColor: (stats?.attendancePercentage || 0) < 75 ? '#EF4444' : '#10B981',
                        borderRadius: 5
                    }
                }}
            />
            <Typography variant="caption" sx={{ mt: 2, display: 'block', color: 'text.secondary' }}>
                * Standard requirement is 75%
            </Typography>
         </Card>
      </Box>
    </Box>
  );
}
