import { collection, query, where, getDocs, doc, getDoc } from "firebase/firestore";
import { db } from "../firebase/firebase";

export const parentService = {
  // Get Student Stats (Attendance, Assignments, Quizzes Overview)
  // Actually, we can get detailed attendance here or in a separate call
  getStudentStats: async (studentId: string) => {
    try {
        // Fetch student details to get XP and other profile info if needed
        const studentRef = doc(db, "students", studentId);
        const studentSnap = await getDoc(studentRef);
        const studentData = studentSnap.exists() ? studentSnap.data() : {};

        // 1. Attendance Overview (from 'attendance' collection)
        // 'attendance' collection seems to be organized by date/class? 
        // Based on user prompt: "attendance having this fields: absentCount, absentStudentIds(array), classId, presentCount, presentStudentIds(array)"
        // This structure implies one doc per class-session.
        // To find if a specific student was present/absent, we need to query all attendance records where:
        // classId matches student's class (we need to find student's class first)
        // AND checks if studentId is in presentStudentIds or absentStudentIds
        
        // This is expensive if we don't have a direct link. 
        // Let's find the student's class(es) first.
        
        // Find Classes via 'class_students'
        const classStudentsRef = collection(db, "class_students");
        const classQuery = query(classStudentsRef, where("studentId", "==", studentId));
        const classSnapshot = await getDocs(classQuery);
        
        const classIds = classSnapshot.docs.map(doc => doc.data().classId);
        
        let totalClasses = 0;
        let presentCount = 0;
        let absentCount = 0;
        
        // Only fetch attendance if enrolled in classes
        if (classIds.length > 0) {
             const attendanceRef = collection(db, "attendance");
             // We can't do 'array-contains-any' for two different arrays easily in one query for specific ID check.
             // But we can filter by classId.
             const attendanceQuery = query(attendanceRef, where("classId", "in", classIds));
             const attendanceDocs = await getDocs(attendanceQuery);
             
             attendanceDocs.forEach(doc => {
                 const data = doc.data();
                 const isPresent = data.presentStudentIds?.includes(studentId);
                 const isAbsent = data.absentStudentIds?.includes(studentId);
                 
                 if (isPresent) {
                     presentCount++;
                     totalClasses++;
                 } else if (isAbsent) {
                     absentCount++;
                     totalClasses++;
                 }
             });
        }
        
        const attendancePercentage = totalClasses > 0 ? Math.round((presentCount / totalClasses) * 100) : 0;
        
        // 2. Fetch Assignments (Workload)
        // Count assignments for the student's classes
        let totalAssignments = 0;
        if (classIds.length > 0) {
            const assignmentsRef = collection(db, "assignments");
            const qAssignments = query(assignmentsRef, where("classId", "in", classIds));
            const assignmentsSnap = await getDocs(qAssignments);
            totalAssignments = assignmentsSnap.size;
        }

        // 3. Fetch Quiz Performance
        // Calculate average score from quiz_attempts
        let quizAverage = 0;
        const quizAttemptsRef = collection(db, "quiz_attempts");
        const qQuizzes = query(quizAttemptsRef, where("studentId", "==", studentId));
        const quizSnap = await getDocs(qQuizzes);
        
        if (!quizSnap.empty) {
            let totalScore = 0;
            let totalMax = 0;
            quizSnap.forEach(doc => {
                const data = doc.data();
                if (data.score !== undefined && data.total !== undefined) {
                    totalScore += data.score;
                    totalMax += data.total;
                }
            });
             // Avoid division by zero
            if (totalMax > 0) {
                 quizAverage = Math.round((totalScore / totalMax) * 100);
            }
        }

        return {
            xp: studentData.xp || 0,
            attendancePercentage,
            presentCount,
            absentCount,
            totalClasses,
            classIds,
            totalAssignments,
            quizAverage,
            studentProfile: studentData
        };
        
    } catch (error) {
        console.error("Error fetching student stats:", error);
        throw error;
    }
  },

  getStudentAttendance: async (studentId: string, classIds: string[]) => {
      // Detailed attendance logs
      if (classIds.length === 0) return [];
      
      const attendanceRef = collection(db, "attendance");
      // Remove orderBy to avoid index issues with 'in' query
      const q = query(attendanceRef, where("classId", "in", classIds));
      const snapshot = await getDocs(q);
      
      let records = snapshot.docs.map(doc => {
          const data = doc.data();
          let status = "N/A"; // Default if not found in either list
          
          if (data.presentStudentIds?.includes(studentId)) status = "Present";
          else if (data.absentStudentIds?.includes(studentId)) status = "Absent";
          
          return {
              id: doc.id,
              date: data.date,
              createdAt: data.createdAt, // timestamp
              teacherId: data.teacherId,
              classId: data.classId,
              status
          };
      });
      
      // Filter out invalid/empty records if any (though logic handles N/A)
      
      // Fetch Teacher and Class details to populate names
      const teacherIds = [...new Set(records.map(r => r.teacherId).filter(Boolean))];
      const uniqueClassIds = [...new Set(records.map(r => r.classId).filter(Boolean))];
      
      const [teachers, classes] = await Promise.all([
          parentService.getTeachers(teacherIds),
          parentService.getClassDetails(uniqueClassIds)
      ]);
      
      const teacherMap: Record<string, string> = {};
      teachers.forEach(t => { teacherMap[t.uid || t.id] = t.name; });
      
      const classMap: Record<string, string> = {};
      classes.forEach(c => { classMap[c.id] = c.class_name || c.subject; });

      const enhancedRecords = records.map(record => ({
          ...record,
          teacherName: teacherMap[record.teacherId] || "Unknown Teacher",
          className: classMap[record.classId] || "Unknown Class"
      }));

      // Sort in memory
      enhancedRecords.sort((a, b) => {
          const dateA = new Date(a.date).getTime();
          const dateB = new Date(b.date).getTime();
          return dateB - dateA;
      });

      return enhancedRecords;
  },

  getStudentAssignments: async (studentId: string) => {
     // Fetch Homework and PBLs
     
     // 1. Homeworks assigned to the class
     // 'students > homework' seems to be where data is... wait. 
     // The prompt said: "students consisting of 2 collection homework which contains this fields... classId..."
     // Oh, is 'homework' a subcollection of 'students'? 
     // "8)students consisting of 2 collection homework..." usually means subcollection.
     // Let's assume it is a subcollection of user OR a root collection linked to class...
     // Re-reading: "8)students consisting of 2 collection homework..." 
     // This phrasing suggests 'homework' is a subcollection of a specific student document? 
     // IF so, we can just query `students/{studentId}/homework`.
     
     const assignments: any[] = [];
     
     try {
         const homeworkRef = collection(db, "students", studentId, "homework");
         const homeworkSnap = await getDocs(homeworkRef);
         
         homeworkSnap.forEach(doc => {
             assignments.push({
                 id: doc.id,
                 type: 'Homework',
                 ...doc.data()
             });
         });
         
         // 2. Submitted PBLs? 
         // "ANother collection submittedPBL inside students only consist of this fields..."
         // So `students/{studentId}/submittedPBL`
         const pblRef = collection(db, "students", studentId, "submittedPBL");
         const pblSnap = await getDocs(pblRef);
         
         pblSnap.forEach(doc => {
             assignments.push({
                 id: doc.id,
                 type: 'Project',
                 ...doc.data()
             });
         });
         
     } catch (e) {
         console.error("Error fetching assignments", e);
     }
     
     return assignments;
  },

  getStudentQuizzes: async (studentId: string) => {
      // `quiz_attempts` collection
      const q = query(collection(db, "quiz_attempts"), where("studentId", "==", studentId));
      const snapshot = await getDocs(q);
      
      return snapshot.docs.map(doc => ({
          id: doc.id,
          ...doc.data()
      }));
  },
  
  getClassDetails: async (classIds: string[]) => {
      if (classIds.length === 0) return [];
      // Fetch class details
      const classes: any[] = [];
      for (const id of classIds) {
          const docRef = doc(db, "classes", id);
          const snap = await getDoc(docRef);
          if (snap.exists()) {
              classes.push({ id: snap.id, ...snap.data() });
          }
      }
      return classes;
  },
  
  getTeachers: async (teacherIds: string[]) => {
      if (teacherIds.length === 0) return [];
      const teachers: any[] = [];
      for (const id of teacherIds) {
          // Assuming 'teachers' collection exists based on prompt point 9
          // Or users collection with role teacher? Prompt says "9)teachers collection"
          const q = query(collection(db, "teachers"), where("uid", "==", id)); 
          // Use UID or doc ID? Prompt: teacherId in 'classes' is "CpqH2jv0oye3pI7lUOz5475fLMh2"
          // Teachers collection has 'uid' field matching that.
          
          const snap = await getDocs(q);
          snap.forEach(doc => teachers.push({ id: doc.id, ...doc.data() }));
      }
      return teachers;
  }
};
