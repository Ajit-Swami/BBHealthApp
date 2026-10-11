// ===============================
// FRONTEND ENV CONFIG (FIXED)
// ===============================

// Dynamic host detection: In browser, use current host IP/domain so API calls reach the backend
const browserHost =
  typeof window !== "undefined" && window.location && window.location.hostname
    ? window.location.hostname
    : "localhost";

const docSvc = browserHost !== "localhost" ? browserHost : (process.env.REACT_APP_DOCSVC_HOST || "localhost");
const regSvc = browserHost !== "localhost" ? browserHost : (process.env.REACT_APP_REGSVC_HOST || "localhost");
const masterSvc = browserHost !== "localhost" ? browserHost : (process.env.REACT_APP_MASTERSVC_HOST || "localhost");

export const environment = {
  // MASTER SERVICE
  MASTER_HOST_URL: `http://${masterSvc}:8081`,

  // AUTH / REGISTER SERVICE
  REGISTER_BASE_URL: `http://${regSvc}:8082`,
  LOGIN_URL: `http://${masterSvc}:8081/auth/login`,
  REGISTER_URL: `http://${regSvc}:8082/auth/register`,
  DOCTOR_REGISTER_URL: `http://${regSvc}:8082/auth/doctor/register`,
  TESTER_REGISTER_URL: `http://${regSvc}:8082/auth/tester/register`,

  // DOCUMENT SERVICE
  DOCUMENT_BASE_URL: `http://${docSvc}:8083`,
  DOCUMENT_UPLOAD_URL: `http://${docSvc}:8083/documents/upload`,
  DOCUMENT_DOWNLOAD_URL: `http://${docSvc}:8083/documents/download`,
};