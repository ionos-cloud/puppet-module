## Unreleased

### BREAKING CHANGES

- **HTTP API URLs are now hard-blocked.** If `IONOS_API_URL` is set to a non-HTTPS URL (e.g. `http://...` or `ftp://...`), the module raises `Puppet::Error` immediately before making any network call. There is no opt-out. Operators using a plain HTTP internal endpoint must place an HTTPS-terminating proxy in front of it.

### Security Fixes

- **CVE-2020-10663 (json gem)**: Raised minimum `json` gem version to `>= 2.3.1`, removing Ruby-version-specific pins that allowed `2.0.4` or `2.1.0`.
- **Dependency vulnerability scanning**: Added `bundler-audit` as a development dependency and added a CI step (`bundle exec bundle-audit check --update`) that blocks merge on any known gem advisory.
- **Secure transport enforcement**: `IONOS_API_URL` scheme is validated in `helper.rb` before credentials are assigned to the API config. Any non-HTTPS scheme raises `Puppet::Error`.
- **Credential log masking**: Added `log_debug` private helper in `PuppetX::IonoscloudX::Helper` that scrubs `IONOS_TOKEN`, `IONOS_USERNAME`, and `IONOS_PASSWORD` values from debug messages before they reach `Puppet.debug`.
- **VCR cassette hardening**: Updated `spec/spec_helper.rb` VCR config to replace `Authorization` and `X-Auth-Token` request headers with `<FILTERED>` via a `before_record` hook (covers both Basic and Bearer forms unconditionally). Added guarded `filter_sensitive_data` entries for `IONOS_USERNAME` and `IONOS_PASSWORD`.
