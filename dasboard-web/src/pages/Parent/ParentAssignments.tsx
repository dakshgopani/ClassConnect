import { useEffect, useState } from "react";
import { 
  Box, 
  Typography, 
  CircularProgress,
  Card,
  Grid,
  Chip,
  Button
} from "@mui/material";
import { Assignment, Science } from "@mui/icons-material";
import { parentService } from "../../services/parent.service";

export default function ParentAssignments() {
  const [loading, setLoading] = useState(true);
  const [assignments, setAssignments] = useState<any[]>([]);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const studentId = localStorage.getItem("studentId");
        if (studentId) {
          const data = await parentService.getStudentAssignments(studentId);
          setAssignments(data);
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

  const AssignmentCard = ({ item }: { item: any }) => (
      <Card sx={{ p: 3, height: '100%' }}>
          <Box display="flex" alignItems="flex-start" justifyContent="space-between" mb={2}>
             <Chip 
                label={item.type || 'Assignment'} 
                size="small" 
                icon={item.type === 'Project' ? <Science fontSize="small" /> : <Assignment fontSize="small" />}
                sx={{ 
                    borderRadius: '8px', 
                    fontWeight: 600,
                    backgroundColor: item.type === 'Project' ? 'rgba(99, 102, 241, 0.1)' : 'rgba(59, 130, 246, 0.1)',
                    color: item.type === 'Project' ? '#6366F1' : '#3B82F6'
                }} 
             />
             <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                {item.submittedAt ? new Date(item.submittedAt.seconds * 1000).toLocaleDateString() : 'Pending'}
             </Typography>
          </Box>
          <Typography variant="h6" sx={{ fontWeight: 700, color: 'text.primary', mb: 1, lineHeight: 1.3 }}>
              {item.title || item.fileName || "Untitled Assignment"}
          </Typography>
          <Typography variant="body2" sx={{ color: 'text.secondary', mb: 2, display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>
              {item.className ? `Class: ${item.className}` : ''}
              {item.fileUrl ? ' (File Attached)' : ''}
          </Typography>
          
          {item.fileUrl && (
              <Button 
                variant="outlined" 
                size="small" 
                fullWidth 
                href={item.fileUrl} 
                target="_blank"
                sx={{ borderRadius: '10px', textTransform: 'none' }}
              >
                  View Submission
              </Button>
          )}
          {item.status && (
              <Box mt={2} display="flex" gap={1}>
                  <Typography variant="caption" sx={{ fontWeight: 600 }}>Status:</Typography>
                  <Typography variant="caption" sx={{ color: item.status === 'pending' ? 'orange' : 'green' }}>{item.status}</Typography>
              </Box>
          )}
      </Card>
  );

  return (
    <Box>
      <Typography variant="h4" sx={{ fontWeight: 800, color: "text.primary", mb: 4 }}>
        Assignments & Projects
      </Typography>

      {assignments.length === 0 ? (
          <Box textAlign="center" py={8}>
              <Typography sx={{ color: 'text.secondary' }}>No assignments found.</Typography>
          </Box>
      ) : (
          <Grid container spacing={3}>
              {assignments.map((item, index) => (
                  <Grid size={{xs:12, sm:6, md:4}} key={item.id || index}>
                      <AssignmentCard item={item} />
                  </Grid>
              ))}
          </Grid>
      )}
    </Box>
  );
}
