import { useEffect, useState } from "react";
import { 
  Box, 
  Typography, 
  CircularProgress,
  Card,
  Grid,
  LinearProgress,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Chip
} from "@mui/material";
import { ExpandMore, Quiz } from "@mui/icons-material";
import { parentService } from "../../services/parent.service";

export default function ParentQuizzes() {
  const [loading, setLoading] = useState(true);
  const [quizzes, setQuizzes] = useState<any[]>([]);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const studentId = localStorage.getItem("studentId");
        if (studentId) {
          const data = await parentService.getStudentQuizzes(studentId);
          setQuizzes(data);
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
      <Typography variant="h4" sx={{ fontWeight: 800, color: "#ffff", mb: 4 }}>
        Quiz Performance
      </Typography>

      <Grid container spacing={3}>
        {quizzes.map((quiz) => {
            const percentage = (quiz.score / quiz.total) * 100;
            return (
                <Grid size={{xs:12}} key={quiz.id}>
                    <Card sx={{ borderRadius: '16px', overflow: 'hidden', boxShadow: '0 2px 10px rgba(0,0,0,0.03)' }}>
                        <Accordion elevation={0}>
                            <AccordionSummary 
                                expandIcon={<ExpandMore />}
                                sx={{ '& .MuiAccordionSummary-content': { display: 'block' } }}
                            >
                                <Box display="flex" justifyContent="space-between" alignItems="center" width="100%" mb={1}>
                                    <Box display="flex" alignItems="center" gap={2}>
                                        <Box 
                                            sx={{ 
                                                p: 1, 
                                                borderRadius: '10px', 
                                                bgcolor: 'rgba(96, 165, 250, 0.1)', 
                                                color: '#60A5FA' 
                                            }}
                                        >
                                            <Quiz />
                                        </Box>
                                        <Box>
                                            <Typography variant="subtitle1" fontWeight={700}>
                                                {quiz.title || quiz.quizId || "Quiz Result"}
                                            </Typography>
                                            <Typography variant="caption" color="textSecondary">
                                                {quiz.submittedAt ? new Date(quiz.submittedAt.seconds * 1000).toLocaleDateString() : ''}
                                            </Typography>
                                        </Box>
                                    </Box>
                                    <Box textAlign="right">
                                        <Typography variant="h6" fontWeight={800} color={percentage < 50 ? 'error.main' : 'success.main'}>
                                            {quiz.score} / {quiz.total}
                                        </Typography>
                                        <Typography variant="caption" display="block">Score</Typography>
                                    </Box>
                                </Box>
                                <LinearProgress 
                                    variant="determinate" 
                                    value={percentage} 
                                    sx={{ 
                                        height: 6, 
                                        borderRadius: 3, 
                                        bgcolor: '#F1F5F9',
                                        '& .MuiLinearProgress-bar': {
                                            bgcolor: percentage < 50 ? '#EF4444' : percentage >= 80 ? '#10B981' : '#F59E0B'
                                        }
                                    }}
                                />
                            </AccordionSummary>
                            <AccordionDetails>
                                <Box mt={1}>
                                    <Typography variant="subtitle2" gutterBottom>Weak Concepts:</Typography>
                                    <Box display="flex" flexWrap="wrap" gap={1}>
                                        {quiz.weakConcepts && quiz.weakConcepts.map((concept: string, idx: number) => (
                                            <Chip 
                                                key={idx} 
                                                label={concept} 
                                                size="small" 
                                                sx={{ 
                                                    bgcolor: '#FEF2F2', 
                                                    color: '#EF4444', 
                                                    fontWeight: 500 
                                                }} 
                                            />
                                        ))}
                                    </Box>
                                </Box>
                            </AccordionDetails>
                        </Accordion>
                    </Card>
                </Grid>
            );
        })}
      </Grid>
    </Box>
  );
}
