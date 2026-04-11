import { collection, getDocs, QuerySnapshot, type DocumentData, query, where } from "firebase/firestore";
import { db } from "../firebase/firebase";

export interface TeacherData {
  id: string;
  name: string;
  email: string;
  subject?: string;
}

export interface StudentData {
  id: string;
  name: string;
  rollNo?: string;
  classId?: string;
  className?: string; // Optional if we want to join or store it
}

export const getAllTeachers = async (collegeName?: string, department?: string): Promise<TeacherData[]> => {
  try {
    let q;
    const constraints = [];
    
    // Schema fix: Teachers use 'collegeName'
    if (collegeName) constraints.push(where("collegeName", "==", collegeName));
    if (department) constraints.push(where("teacherDepartment", "==", department));

    if (constraints.length > 0) {
        q = query(collection(db, "teachers"), ...constraints);
    } else {
        q = collection(db, "teachers");
    }
    const querySnapshot: QuerySnapshot<DocumentData> = await getDocs(q);
    const teachers: TeacherData[] = [];
    
    querySnapshot.forEach((doc) => {
      const data = doc.data();
      teachers.push({
        id: doc.id,
        name: data.name || "Unknown Teacher",
        email: data.email || "",
        subject: data.subject || "General",
      });
    });

    return teachers;
  } catch (error) {
    console.error("Error fetching teachers:", error);
    return [];
  }
};

export const getAllStudents = async (collegeName?: string, department?: string): Promise<StudentData[]> => {
  try {
    let studentsQuery;
    let classesQuery;
    
    // Students filter
    const studentConstraints = [];
    if (collegeName) studentConstraints.push(where("collegeSchoolName", "==", collegeName));
    if (department) studentConstraints.push(where("studentDepartment", "==", department));

    if (studentConstraints.length > 0) {
        studentsQuery = query(collection(db, "students"), ...studentConstraints);
    } else {
        studentsQuery = collection(db, "students");
    }

    // Classes filter (Classes don't have department support yet, filtering by college only)
    if (collegeName) {
        classesQuery = query(collection(db, "classes"), where("collegeSchoolName", "==", collegeName));
    } else {
        classesQuery = collection(db, "classes");
    }

    const [studentsSnap, classesSnap, classStudentsSnap] = await Promise.all([
      getDocs(studentsQuery),
      getDocs(classesQuery),
      getDocs(collection(db, "class_students")),
    ]);

    const classMap: Record<string, string> = {};
    classesSnap.forEach((doc) => {
      classMap[doc.id] = doc.data().class_name || "Unknown Class";
    });

    const studentToClass: Record<string, string> = {};
    classStudentsSnap.forEach((doc) => {
      const data = doc.data();
      if (data.studentId) {
        studentToClass[data.studentId] = data.classId || "";
      }
    });

    const students: StudentData[] = [];
    studentsSnap.forEach((doc) => {
      const data = doc.data();
      const classId = studentToClass[doc.id] || "";
      students.push({
        id: doc.id,
        name: data.name || "Unknown Student",
        rollNo: data.rollNo || "",
        classId: classId,
        className: classMap[classId] || "No Class Assigned",
      });
    });

    return students;
  } catch (error) {
    console.error("Error fetching students:", error);
    return [];
  }
};
