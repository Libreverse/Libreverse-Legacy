# Production Bug Report

Generated from analysis of production logs (`b8s0o8o0g084ss4s84skg080-191243450421-all-logs-2026-05-13-18-32-29.txt`).

---

## 1. [FIXED] WhitespaceCompressor: `minify_html` native panic on iframe srcdoc

**Severity:** Critical

**Evidence:**
```
thread '<unnamed>' panicked at .../minify-js/src/minify/pass1.rs:331:13:
assertion failed: cons_expr.returns && alt_expr.returns
lib/middleware/whitespace_compressor.rb:132:in 'Kernel#minify_html'
```

**Root cause:** `minify_srcdoc_iframes_with_nokogiri` called `minify_html` with `minify_js: true` on untrusted iframe `srcdoc` content. The Rust JS minifier panicked on certain JS expressions.

**Fix applied:**
- Replaced all direct `minify_html` calls with `safe_minify_html`, which rescues exceptions and returns original HTML.
- Disabled JS minification for `srcdoc` content (`minify_js: false`).
- Added regression tests in `test/lib/whitespace_compressor_test.rb`.

**Files changed:**
- `lib/middleware/whitespace_compressor.rb`
- `test/lib/whitespace_compressor_test.rb`

---

## 2. Dashboard crashes with private method `federated_identifier`

**Severity:** Very High

**Evidence:**
```
ActionView::Template::Error - private method 'federated_identifier' called for an instance of Account
app/views/dashboard/index.haml:46
```

**Affected code:**
```haml
app/views/dashboard/index.haml:46
\#{@account.federated_identifier}

app/views/dashboard/index.haml:62
.info-value= @account.federated_identifier
```

**Impact:** Real 500 errors on `/dashboard` for affected accounts.

**Likely cause:** `Account#federated_identifier` exists but is private (or provided by a concern as a private helper). Views cannot call private methods directly.

**Fix options:**
1. Expose a public presenter/helper method for display.
2. Make `federated_identifier` public on `Account` if it is intended to be displayed.
3. Use a defensive fallback (username, email, or ID) when no public federated identifier is available.

---

## 3. TiDB / Trilogy: entry too large (`6.8MB > 6MB` limit)

**Severity:** Very High

**Evidence:**
```
ActiveRecord::StatementInvalid - Trilogy::ProtocolError:
8025: entry too large, the max entry size is 6291456, the size of data is 6823833
```

**Impact:** Real request failure. The DB rejected a payload/query result around `6.8MB`, above the configured max entry size of `6MB`.

**Likely causes:**
- Large experience HTML/blob/content being stored directly in a row.
- Large serialized/cache/encrypted payload.
- A query trying to insert/update too much data in one entry.

**Recommended investigation:**
- Find the request path around `2026-05-04 21:07:54`.
- Inspect experience/content columns for large HTML fields.
- Add app-level size validation before DB write.
- Move large payloads to Active Storage or file/blob storage rather than TiDB row storage.
- If intentional, raise TiDB limit only if safe, but app-level limits are better.

---

## 4. SQLite database locked during boot (`rails runner` / init)

**Severity:** High

**Evidence:**
```
SQLite3::BusyException: database is locked
config/initializers/encrypted_solid.rb:18
config/initializers/encrypted_solid.rb:30
```

**Impact:** Can break boot-time `rails runner`, background jobs, health checks, or deploy tasks.

**Likely cause:** `config/initializers/encrypted_solid.rb` queries table/column existence during initialization while SQLite/Solid databases are locked or being configured.

**Recommended fix:**
- Avoid DB schema introspection during app initialization unless wrapped defensively.
- Rescue `SQLite3::BusyException`, `ActiveRecord::StatementInvalid`, and connection errors.
- Defer encryption setup until after boot if possible.
- Ensure SQLite busy timeout / WAL mode is configured before initializers query the DB.

**Files to inspect:**
- `config/initializers/encrypted_solid.rb`

---

## 5. `EmojiReplacer` processing timeouts

**Severity:** Medium-High

**Evidence:**
```
EmojiReplacer: Processing timeout
EmojiReplacer: Error processing request: ...
```

**Code location:**
```ruby
lib/middleware/emoji_replacer.rb:130
```

**Impact:** Performance degradation. May also obscure upstream exceptions because it logs "Error processing request" after another failure.

**Likely cause:** Large HTML responses, expensive Nokogiri parsing, or repeated document traversal.

**Recommended fix:**
- Skip emoji replacement for large responses above a byte threshold.
- Cache processed output by digest, similar to `WhitespaceCompressor`.
- Ensure the middleware does not log upstream app exceptions as its own processing failure.
- Consider moving emoji processing earlier / statically rather than per-response middleware.

---

## 6. ImageMagick cannot encode AVIF

**Severity:** Medium

**Evidence:**
```
convert-im6.q16: no encode delegate for this image format `AVIF'
```

**Likely code location:**
```ruby
config/initializers/thredded.rb:88-94
.convert("avif")
```

**Impact:** Avatar/icon generation or forum asset generation fails or degrades.

**Cause:** Production ImageMagick lacks AVIF encoder support.

**Fix options:**
1. Install ImageMagick with AVIF/libheif support.
2. Change generated format from `avif` to `webp` or `png`.
3. Add fallback: try AVIF, rescue, then WebP/PNG.

---

## 7. CrowdSec bouncer config warnings/errors

**Severity:** Medium

**Evidence:**
```
unsupported configuration 'BOUNCER_LOG_LEVEL'
unsupported configuration 'HTTP_TIMEOUT'
error loading captcha plugin: no recaptcha site key provided
BAN_TEMPLATE_PATH and REDIRECT_LOCATION variable are empty, will return HTTP 403
```

**Impact:** Security layer still initializes, but configuration is partially invalid or degraded.

**Recommended fix:**
- Remove unsupported `BOUNCER_LOG_LEVEL` and `HTTP_TIMEOUT` from the Nginx bouncer config for the installed version.
- Disable captcha plugin or provide Recaptcha keys.
- Configure `BAN_TEMPLATE_PATH` or `REDIRECT_LOCATION` if branded ban pages are preferred over bare `403`.

---

## 8. Thredded deprecation spam

**Severity:** Low-Medium

**Evidence:**
```
[DEPRECATION] `:whitelist` authorization mode is deprecated. Please use `:allow_authorized` instead.
```

**Relevant file:**
- `config/initializers/thredded.rb`

**Impact:** Not a crash, but noisy logs and future compatibility risk.

**Recommended fix:**
Search current Thredded config for `:whitelist` and replace with `:allow_authorized` where supported. The existing monkey patch for `ContentFormatter.whitelist` does not address the source of the authorization mode deprecation.

---

## 9. Ruby version inconsistency (production vs. repo)

**Severity:** High

**Evidence:**
```
Unknown ruby string: ruby-3.4.
Required ruby-3.4 is not installed.
```

But stack traces show:
```
/usr/local/rvm/gems/ruby-3.4.8
/usr/local/rvm/rubies/ruby-3.4.8
```

**Repo declares:**
```
ruby-3.3.7
```

**Impact:** Production is not running the repo-declared Ruby version. This can explain odd compatibility behavior and makes local/prod debugging unreliable.

**Fix:** Align production Ruby version with `.ruby-version` and `Gemfile`, or upgrade the repo to `3.4.8` if that is the intended target.

---

## 10. Moderation validation logged at ERROR level

**Severity:** Medium

**Evidence:**
```
EXPERIENCE ERRORS: ["Title contains inappropriate content and cannot be saved", ...]
```

**Impact:** Expected validation rejections are logged as errors, polluting production logs and hiding real incidents.

**Recommended fix:**
Downgrade expected moderation/validation failures from `error` to `info` or `warn`. Keep true exceptions at `error`.

**Files to inspect:**
- `app/models/experience.rb`
- Experience create/update controller paths

---

## Recommended Fix Order

1. Fix dashboard `federated_identifier` crash (direct 500).
2. Fix DB oversized entry (app-level validation or storage architecture).
3. Harden `encrypted_solid.rb` initializer (boot-time DB locks).
4. Optimize/limit `EmojiReplacer` (timeout prevention).
5. Fix AVIF fallback (runtime image processing).
6. Clean deployment config (Ruby version, CrowdSec, Thredded).
7. Adjust moderation error logging level.
