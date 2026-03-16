# Project Guidelines

## Build and Run
- For database setup, execute SQL scripts in order: `2_create_tables.sql`, then `3_insert_data.sql`.
- Run Node.js commands from `web-ui/` (not repository root).
- Web UI commands:
  - `npm install`
  - `npm start`
  - `npm run dev`

## Architecture
- Root-level SQL and docs define the Oracle DigiBook schema/data (`1_Database_Design.md`, `2_create_tables.sql`, `3_insert_data.sql`).
- Backend API is in `web-ui/src/server.js` and database access layer is in `web-ui/src/db.js`.
- Frontend is static vanilla JS/CSS/HTML in `web-ui/public/`, served by Express.
- Keep backend data access read-oriented and table access restricted through the `allowedTables` whitelist in `server.js`.

## Conventions
- Use CommonJS (`require`, `module.exports`) for Node.js files.
- Keep Oracle access through `query()` in `web-ui/src/db.js`; avoid ad-hoc connection handling in route handlers.
- When adding table endpoints, follow existing limit handling pattern (parse numeric limit, clamp to 1..100).
- Preserve current API response style (`{ message: ... }`, `{ rows: [...] }`, structured objects for summary endpoints).

## Environment and Pitfalls
- `web-ui/.env` is required; start from `web-ui/.env.example`.
- Required env vars: `ORACLE_USER`, `ORACLE_PASSWORD`, `ORACLE_CONNECTION_STRING`.
- Server may auto-shift to the next free port if `PORT` is busy; use startup logs or `/api/runtime` to confirm actual URL.
- If Oracle is unavailable, `/api/health` returns an error; verify DB connectivity before debugging frontend issues.