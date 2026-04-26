// Configuration
// The webapp connects to the Go microservice through ToxiProxy
// Vite dev server proxies /api to http://localhost:8000 (ToxiProxy)
export const SERVICE_URL = '/api';

// Request timeout in milliseconds
// Default: 30000ms (30 seconds)
// Enterprise policy: 5000ms (5 seconds) - change this for Step 7
export const REQUEST_TIMEOUT = 5000;
