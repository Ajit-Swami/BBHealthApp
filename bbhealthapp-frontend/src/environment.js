// ===============================
// FRONTEND ENV CONFIG (INGRESS ROUTED)
// ===============================

export const environment = {
  baseUrl: "",

  // MASTER SERVICE
  MASTER_HOST_URL: "",

  // AUTH / REGISTER SERVICE
  REGISTER_BASE_URL: "",
  LOGIN_URL: "/auth/login",
  REGISTER_URL: "/auth/register",
  DOCTOR_REGISTER_URL: "/auth/doctor/register",
  TESTER_REGISTER_URL: "/auth/tester/register",

  // DOCUMENT SERVICE
  DOCUMENT_BASE_URL: "",
  DOCUMENT_UPLOAD_URL: "/documents/upload/",
  DOCUMENT_DOWNLOAD_URL: "/documents/download/",
  DOWNLOAD_BASE_URL: "/documents/download/",
};