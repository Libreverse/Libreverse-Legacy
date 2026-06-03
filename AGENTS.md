## Learned User Preferences

- Prefer minimal-scope diffs; do not change unrelated code.
- Do not create git commits or push unless explicitly asked.
- When asked to explore or report (e.g. CI logs), do not change code until the user requests it.
- Prefer concise explanations after security or bug fixes.
- Will not rearchitect GitHub Actions secrets; accepts ~7-day package trust for deps that passed existing CI gates.
- Avoid changes that could trigger unexpected paid serverless or database spend.
- Do not circumvent Snyk scanners (e.g. string-splitting hardcoded credentials); implement real security controls.

## Learned Workspace Facts

- Rails 8 app (Libreverse-Legacy); Ruby 3.3.7 via rbenv (`.ruby-version`); run Ruby tools with `rbenv exec bundle exec …`.
- JavaScript dependencies use Bun (`bun.lock`); Ruby gems use Bundler (`Gemfile.lock`).
- Security checks: Brakeman for Ruby; Snyk Code for JS/Ruby (IDE/MCP scans).
- Federated experiences link out via `experience_url` in views (no `redirect_to` with user-supplied URLs in `ExperiencesController#display`).
- Federated OIDC dynamic client registration must POST only to HTTPS endpoints whose host matches the validated `oidc_domain`.
- Browser JS security: use `CookieUtils` (`cookies.js`) with `secure: true`, not raw `document.cookie`; handle `postMessage` via `trusted_post_message.js` same-origin helpers (log messages must match the actual failure).
- System accounts (`system_account`, `SystemAccounts`): reserved usernames; no password/login (Rodauth blocks); `admin?` is always false; reconcile clears `admin` via `read_attribute(:admin)`, not `admin?`.
- Merging store state from `localStorage`/JSON must whitelist store names and use safe merge (skip `__proto__`, `constructor`, `prototype`).
- Production deploy host `libreverse-legacy.geor.me` (strict Cloudflare bot protection); CI deploy/health uses `.github/actions/bypass-cloudflare`.
- Autonomous dependency rolling uses 7-day lockfile delta age gates (`MIN_AGE_DAYS`); see `documentation/dependency-rolling-autonomous.md`.
- CI security secrets: `SNYK_TOKEN`, `SNYK_ORG`, `SOCKET_API_KEY`; protected `main` autofix/merge uses GitHub App (`APP_ID`, `APP_PRIVATE_KEY`).
- Full Rails test boot may fail locally with Rodauth/Zeitwerk `AccountSequel`; use targeted `ruby -Itest` files when boot fails.
