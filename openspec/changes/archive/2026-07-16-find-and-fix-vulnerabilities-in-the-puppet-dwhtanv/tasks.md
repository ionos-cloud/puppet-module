## 1. Dependency Updates

- [x] 1.1 Raise `json` gem floor to `>= 2.3.1` in `Gemfile`, removing Ruby-version-specific pins for 2.0.4 and 2.1.0
- [x] 1.2 Add `bundler-audit` as a development dependency in `Gemfile`
- [ ] 1.3 Run `bundle install` locally and verify `bundle exec bundle-audit check --update` exits 0 with the updated gem set

## 2. CI Pipeline — bundler-audit Step

- [x] 2.1 Add a `bundle-audit` job step to `.github/workflows/ci.yml` that runs `bundle exec bundle-audit check --update`
- [ ] 2.2 Confirm the step runs on pull_request events and blocks merge on non-zero exit
- [ ] 2.3 Verify CI passes on a clean branch after gem floor update

## 3. Secure Transport Enforcement

- [x] 3.1 In `lib/puppet_x/ionoscloud/helper.rb`, locate the `IONOS_API_URL` parsing block in both `ionoscloud_api_client` and `ionoscloud_dbaas_postgres_api_client`
- [x] 3.2 Add URI scheme validation: if `uri.scheme != 'https'`, raise `Puppet::Error` with message `IONOS_API_URL must use HTTPS (got: <scheme>)`
- [x] 3.3 Move the credential assignment block to after the scheme validation so credentials are never attached to an invalid config
- [x] 3.4 Write unit tests: (a) valid HTTPS URL accepted, (b) HTTP URL raises `Puppet::Error`, (c) ftp:// URL raises `Puppet::Error`, (d) unset URL skips validation

## 4. Credential Log Masking

- [x] 4.1 Add a private `log_debug(msg)` helper method to `PuppetX::Ionoscloud::Helper` that scrubs token/password values from the message before calling `Puppet.debug`
- [x] 4.2 Replace direct `Puppet.debug` calls in `helper.rb` that reference API config or credential variables with `log_debug`
- [x] 4.3 Write unit tests verifying that `IONOS_TOKEN`, `IONOS_USERNAME`, `IONOS_PASSWORD` values are replaced with `[REDACTED]` in `log_debug` output
- [x] 4.4 Confirm non-credential debug messages pass through to `Puppet.debug` unchanged

## 5. VCR Cassette Hardening

- [x] 5.1 In `spec/spec_helper.rb`, add a `before_record` hook that sets `interaction.request.headers['Authorization'] = ['<FILTERED>']` whenever an `Authorization` header is present (covers both Basic and Bearer forms)
- [x] 5.2 In the same `before_record` hook, replace `X-Auth-Token` header values with `<FILTERED>`
- [x] 5.3 Add `filter_sensitive_data('<IONOS_USERNAME>') { ENV['IONOS_USERNAME'] }` and `filter_sensitive_data('<IONOS_PASSWORD>') { ENV['IONOS_PASSWORD'] }` entries (each guarded: only registered when the env var is non-nil)
- [x] 5.4 Scan all files in `spec/fixtures/vcr_cassettes/` for raw credential values: `grep -r 'Authorization: Basic [A-Za-z0-9]' spec/fixtures/`
- [x] 5.5 Re-record or manually scrub any cassette files that contain unfiltered credential values
- [ ] 5.6 Run the full spec suite against the updated cassettes to confirm no regressions

## 6. Validation and Release

- [ ] 6.1 Run `bundle exec rspec` locally — all tests pass
- [ ] 6.2 Run `bundle exec puppet-lint lib/` — no new offences
- [x] 6.3 Update `CHANGELOG.md`: note the HTTP URL hard block as a breaking change and list all security fixes
- [ ] 6.4 Open PR, confirm CI (unit tests + bundler-audit) green before requesting review
