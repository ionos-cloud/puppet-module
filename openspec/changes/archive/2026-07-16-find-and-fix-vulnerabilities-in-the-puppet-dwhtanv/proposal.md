## Why

The puppet-module has multiple unaddressed security vulnerabilities: `IONOS_API_URL` accepts plain HTTP, silently exposing credentials in transit; `Puppet.debug` output can leak authentication tokens; the `json` gem is pinned to versions affected by CVE-2020-10663; and there is no automated dependency-vulnerability gate in CI. The recent S3 key exposure (commit `41ab40f`) confirms these are real risks, not theoretical.

## What Changes

* Enforce HTTPS-only on `IONOS_API_URL`; raise `Puppet::Error` on any non-HTTPS scheme — no escape hatch
* Mask credentials (token, username, password) from `Puppet.debug` output via a `log_debug` wrapper helper
* Add `bundler-audit` to CI and raise the `json` gem floor to `>= 2.3.1`
* Extend VCR cassette configuration to strip `Authorization` (Basic and Bearer) and `X-Auth-Token` headers via a `before_record` hook; use `filter_sensitive_data` for literal env-var values
* Audit and scrub all existing cassette files for raw credential values before merge

## Capabilities

### New Capabilities

- `secure-transport-enforcement`: Validate that `IONOS_API_URL` uses HTTPS; raise `Puppet::Error` on any other scheme before credentials are attached
- `dependency-vulnerability-scanning`: CI job that runs `bundler-audit` on every PR and blocks merge on known CVEs; enforces minimum safe gem versions
- `secret-leakage-prevention`: VCR `before_record` hook and `filter_sensitive_data` rules that prevent credentials from being recorded into cassette fixture files
- `credential-log-masking`: `log_debug` wrapper that redacts token, username, and password values before they reach `Puppet.debug`

### Modified Capabilities

## Impact

* `lib/puppet_x/ionoscloud/helper.rb` — URL scheme validation + `log_debug` masking wrapper
* `Gemfile` — `json` floor constraint `>= 2.3.1`; `bundler-audit` added as dev dependency
* `spec/spec_helper.rb` — VCR `before_record` hook and `filter_sensitive_data` extended to cover all auth headers
* `.github/workflows/ci.yml` — new `bundler-audit` step
