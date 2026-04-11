import { Navigate, Outlet, useLocation } from "react-router-dom";

export const ParentAuthGuard = () => {
  const location = useLocation();
  const isAuthenticated = localStorage.getItem("isAuthenticated") === "true";
  const userRole = localStorage.getItem("userRole");

  if (!isAuthenticated || userRole !== "parent") {
    // If not authenticated or not a parent, redirect to login
    // If they are admin, they shouldn't be here either without explicit navigation, but cleaner to just send to login
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  return <Outlet />;
};
