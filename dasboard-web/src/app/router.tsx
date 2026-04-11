import { createBrowserRouter, Navigate } from "react-router-dom";
import LoginPage from "../pages/Login/LoginPage";
import OverviewPage from "../pages/Overview/OverviewPage";
import ClassDetailPage from "../pages/Classes/ClassDetailPage";
import ClassesPage from "../pages/Classes/ClassesPage";
import TeacherDetailPage from "../pages/Teachers/TeacherDetailPage";
import TeachersPage from "../pages/Teachers/TeachersPage";
import StudentDetailPage from "../pages/Students/StudentDetailPage";
import StudentsPage from "../pages/Students/StudentsPage";
import MainLayout from "../components/layout/MainLayout";
import { AuthGuard } from "../components/auth/AuthGuard";

// Parent Imports
import { ParentAuthGuard } from "../components/auth/ParentAuthGuard";
import ParentLayout from "../components/layout/ParentLayout";
import ParentOverview from "../pages/Parent/ParentOverview";
import ParentAttendance from "../pages/Parent/ParentAttendance";
import ParentAssignments from "../pages/Parent/ParentAssignments";
import ParentQuizzes from "../pages/Parent/ParentQuizzes";
import ParentTeachers from "../pages/Parent/ParentTeachers";

export const router = createBrowserRouter([
  {
    path: "/",
    element: <AuthGuard />,
    children: [
      {
        path: "/",
        element: <MainLayout />,
        children: [
          {
            path: "/",
            element: <OverviewPage />,
          },
          {
            path: "/classes",
            element: <ClassesPage />,
          },
          {
            path: "/classes/:classId",
            element: <ClassDetailPage />,
          },
          {
            path: "/teachers",
            element: <TeachersPage />,
          },
          {
            path: "/teachers/:teacherId",
            element: <TeacherDetailPage />,
          },
          {
            path: "/students",
            element: <StudentsPage />,
          },
          {
            path: "/students/:studentId",
            element: <StudentDetailPage />,
          },
        ],
      },
    ],
  },
  {
    path: "/parent",
    element: <ParentAuthGuard />,
    children: [
      {
        path: "/parent",
        element: <ParentLayout />,
        children: [
          {
            index: true,
            element: <Navigate to="/parent/overview" replace />,
          },
          {
            path: "overview",
            element: <ParentOverview />,
          },
          {
            path: "attendance",
            element: <ParentAttendance />,
          },
          {
            path: "assignments",
            element: <ParentAssignments />,
          },
          {
            path: "quizzes",
            element: <ParentQuizzes />,
          },
          {
            path: "teachers",
            element: <ParentTeachers />,
          },
        ],
      },
    ],
  },
  {
    path: "/login",
    element: <LoginPage />,
  },
]);
