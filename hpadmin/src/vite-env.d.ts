/// <reference types="vite/client" />

interface ImportMetaEnv {
  /** Backend API base, e.g. https://api.eaglesoft.org/api/v1 (defaults to the local backend). */
  readonly VITE_API_URL?: string;
  /** Path the site is served from, e.g. '/' or '/hungerpoint/'. */
  readonly VITE_BASE?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
