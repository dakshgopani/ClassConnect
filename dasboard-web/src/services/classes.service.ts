import { collection, getDocs, QuerySnapshot, type DocumentData, query, where } from "firebase/firestore";
import { db } from "../firebase/firebase";

export interface ClassData {
  id: string;
  name: string;
  grade?: string;
  section?: string;
  studentCount?: number;
}

export const getAllClasses = async (collegeName?: string): Promise<ClassData[]> => {
  try {
    let q;
    if (collegeName) {
        q = query(collection(db, "classes"), where("collegeSchoolName", "==", collegeName));
    } else {
        q = collection(db, "classes");
    }
    const querySnapshot: QuerySnapshot<DocumentData> = await getDocs(q);
    const classes: ClassData[] = [];
    
    querySnapshot.forEach((doc) => {
      const data = doc.data();
      classes.push({
        id: doc.id,
        name: data.class_name || "Unknown Class",
        grade: data.grade || "",
        section: data.section || "",
        studentCount: data.student_count || 0,
      });
    });

    return classes;
  } catch (error) {
    console.error("Error fetching classes:", error);
    return [];
  }
};
