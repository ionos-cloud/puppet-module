## Context

The puppet-module is a Ruby-based Puppet provider for IONOS Cloud resources. All API calls route through `lib/puppet_x/ionoscloud/helper.rb`, which reads credentials from `IONOS_TOKEN`, `IONOS_USERNAME`, and `IONOS_PASSWORD` and optionally overrides the API base URL via `IONOS_API_URL`. The module uses the `ionoscloud` Ruby gem (v6.1.0) as its HTTP client. CI runs on GitHub Actions with unit tests against Puppet 6 and 7. Commit `41ab40f` ("removed sensitive data from s3key tests") confirms credential leakage into VCR cassettes has already caused a real incident.

## Goals / Non-Goals

**Goals:**
- Block HTTP API URLs before any network call is made; no escape hatch
- Eliminate credential values from `Puppet.debug` output
- Gate every PR on known-CVE dependency checks
- Prevent future cassette credential commits via sanitisation rules
- Upgrade `json` gem floor to address CVE-2020-10663

**Non-Goals:**
- Replacing basic-auth support with token-only (separate deprecation effort)
- Certificate pinning for the IONOS API endpoint
- Hiera-eyaml or Vault integration for credential storage
- Changing the public Puppet type/provider interface

## Decisions

**1. Validate URL scheme in `helper.rb`, not in Puppet types**

The `IONOS_API_URL` override is read once in the API client factory methods in `helper.rb`. Validating there catches all 40+ providers through a single code path.

*Alternative considered:* Validate at the Puppet type `newparam` level — rejected because the URL is a global config value, not a per-resource parameter.

**2. Hard block on HTTP URLs — no `IONOS_ALLOW_HTTP` escape hatch**

Any non-HTTPS scheme raises `Puppet::Error` immediately. A warning or an opt-in env var would allow connections to proceed and silently transmit credentials over plaintext. The escape hatch is explicitly not implemented: operators who need a non-TLS internal endpoint must place an HTTPS-terminating proxy in front of it. This is a **breaking change** for anyone currently overriding `IONOS_API_URL` with a plain HTTP URL.

*Alternative considered:* Accept `IONOS_ALLOW_HTTP=true` for non-production use — rejected because opt-out flags are routinely misused and the credential exposure risk outweighs operator convenience. Including it as an open question has been resolved here: hard block always.

**3. Credential masking scoped to `Puppet.debug` calls only**

Introduce a `log_debug(msg)` private helper in `PuppetX::Ionoscloud::Helper` that scrubs known credential patterns before delegating to `Puppet.debug`. Scope is limited to debug calls because the existing `Puppet.info`, `Puppet.warning`, and `Puppet.err` call sites in `helper.rb` log only resource lifecycle events (e.g., "Creating server: #{name}") and do not include credential-adjacent values.

*Alternative considered:* Wrap all four log levels — rejected as over-engineering; credentials do not appear at info/warn/err call sites.

**4. `bundler-audit` as a required CI step, not advisory**

The step runs `bundle exec bundle-audit check --update` and exits non-zero on any advisory match, blocking merge. Advisory-only mode was rejected because it accumulates ignored alerts over time.

**5. VCR Bearer token filtering via `before_record` hook; literal env-var values via `filter_sensitive_data`**

VCR's `filter_sensitive_data` replaces a known literal string — suitable for `IONOS_USERNAME` and `IONOS_PASSWORD` values which are set in the test environment. Bearer tokens in `Authorization` headers vary per session and cannot be matched by literal string; VCR's `before_record { |interaction| ... }` hook is the correct mechanism. The hook checks `interaction.request.headers['Authorization']` and replaces the value with `<FILTERED>` unconditionally (covering both Basic and Bearer forms), and does the same for `X-Auth-Token`.

*Alternative considered:* Using `filter_sensitive_data` with `ENV['IONOS_TOKEN']` — works only when the token env var is set during test runs; silently misses cassettes recorded without that env var set. The `before_record` hook fires unconditionally.

## Risks / Trade-offs

- **[Risk] `bundler-audit` database lag** — advisory DB updates daily; a zero-day window exists. → Mitigation: enable GitHub Dependabot for the repo alongside `bundler-audit`.
- **[Risk] Hard HTTP block is a breaking change** — automation targeting a non-TLS internal endpoint will fail without notice. → Mitigation: document prominently in CHANGELOG as a breaking change; recommend HTTPS-terminating proxy as migration path.
- **[Risk] Log masking regex over-scrubs** — a resource name matching a credential pattern is redacted. → Mitigation: mask only well-defined patterns (UUID tokens, `password=...` key-value pairs), not arbitrary strings.

## Migration Plan

1. Merge gem version floor and `bundler-audit` additions first — green CI validates no new breakage.
2. Merge VCR cassette sanitisation — re-record any cassettes that fail the new filter.
3. Merge `helper.rb` URL validation and `log_debug` wrapper — unit tests cover both paths.
4. Tag a patch release; update CHANGELOG with the HTTP-URL hard block as a breaking change.
5. Rollback: revert `helper.rb` commit; no data migration required.
