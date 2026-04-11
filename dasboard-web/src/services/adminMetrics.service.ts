import { collection, getDocs, query, where } from "firebase/firestore";
import { db } from "../firebase/firebase";

export const getAdminOverviewMetrics = async (collegeName?: string, department?: string) => {


  if (collegeName || department) {
      // Classes (Note: Classes don't have department in schema yet, filtering only by college if present)
      // If we need class department filter, schema needs update. For now, filter by college.
      const classConstraints = [];
      if (collegeName) classConstraints.push(where("collegeSchoolName", "==", collegeName));
      // if (department) classConstraints.push(where("department", "==", department)); // Future support
      
      const qClasses = query(collection(db, "classes"), ...classConstraints);

      // Students
      const studentConstraints = [];
      if (collegeName) studentConstraints.push(where("collegeSchoolName", "==", collegeName));
      if (department) studentConstraints.push(where("studentDepartment", "==", department));
      
      const qStudents = query(collection(db, "students"), ...studentConstraints);

      // Teachers (Using collegeName instead of collegeSchoolName as per schema)
      const teacherConstraints = [];
      if (collegeName) teacherConstraints.push(where("collegeName", "==", collegeName));
      if (department) teacherConstraints.push(where("teacherDepartment", "==", department));

      const qTeachers = query(collection(db, "teachers"), ...teacherConstraints);

      const [classesSnap, studentsSnap, teachersSnap] = await Promise.all([
          getDocs(qClasses),
          getDocs(qStudents),
          getDocs(qTeachers)
      ]);

      return {
          totalClasses: classesSnap.size,
          totalStudents: studentsSnap.size,
          totalTeachers: teachersSnap.size,
      };
  } else {
      // Fallback for super admin
      const classes = await getDocs(collection(db, "classes"));
      const students = await getDocs(collection(db, "students"));
      const teachers = await getDocs(collection(db, "teachers"));

      return {
        totalClasses: classes.size,
        totalStudents: students.size,
        totalTeachers: teachers.size,
      };
  }
};
