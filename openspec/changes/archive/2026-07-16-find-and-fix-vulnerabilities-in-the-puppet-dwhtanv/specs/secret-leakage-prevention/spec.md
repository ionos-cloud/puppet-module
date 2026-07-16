## ADDED Requirements

### Requirement: VCR cassettes filter Authorization headers via before_record hook
The VCR configuration in `spec/spec_helper.rb` SHALL register a `before_record` hook that replaces the full value of any `Authorization` request header with `<FILTERED>` before the cassette is written to disk. The hook SHALL apply unconditionally to all cassette recordings, covering both `Authorization: Basic ...` and `Authorization: Bearer ...` forms, regardless of whether credential environment variables are set.

#### Scenario: Bearer token header stripped from cassette
- **WHEN** a VCR cassette is recorded and the request contains an `Authorization: Bearer <token>` header
- **THEN** the cassette file on disk contains `<FILTERED>` instead of the token value

#### Scenario: Basic auth header stripped from cassette
- **WHEN** a VCR cassette is recorded and the request contains an `Authorization: Basic <encoded>` header
- **THEN** the cassette file on disk contains `<FILTERED>` instead of the encoded credentials

#### Scenario: before_record hook fires unconditionally
- **WHEN** `IONOS_TOKEN` is not set in the environment and a cassette is recorded with a Bearer token
- **THEN** the `before_record` hook still replaces the `Authorization` header value with `<FILTERED>`

#### Scenario: Playback uses placeholder without error
- **WHEN** a cassette containing `<FILTERED>` placeholder values is used for test playback
- **THEN** the test suite runs without authentication errors against the recorded responses

### Requirement: VCR cassettes filter X-Auth-Token headers via before_record hook
The same `before_record` hook SHALL also replace the value of any `X-Auth-Token` request header with `<FILTERED>` before the cassette is written to disk.

#### Scenario: X-Auth-Token header stripped from cassette
- **WHEN** a VCR cassette is recorded and the request contains an `X-Auth-Token` header
- **THEN** the cassette file on disk contains `<FILTERED>` instead of the token value

### Requirement: IONOS_USERNAME and IONOS_PASSWORD values filtered via filter_sensitive_data
The VCR configuration SHALL register `filter_sensitive_data` entries using the literal values of `IONOS_USERNAME` and `IONOS_PASSWORD` environment variables to replace those strings wherever they appear in cassette body or header content. Each entry SHALL be registered only when the corresponding environment variable is set (nil guard required).

#### Scenario: Username value replaced in cassette body
- **WHEN** `IONOS_USERNAME` is set to `testuser` and a cassette is recorded that includes that string in a response body
- **THEN** the cassette file contains `<IONOS_USERNAME>` instead of `testuser`

#### Scenario: No-op when environment variables are unset
- **WHEN** `IONOS_USERNAME` is not set
- **THEN** no `filter_sensitive_data` entry is registered for that variable and recording proceeds without error

### Requirement: Existing cassettes re-validated after filter update
All cassette files in `spec/fixtures/vcr_cassettes/` SHALL be audited and any file containing a literal `Authorization` value or token string SHALL be re-recorded or manually scrubbed before the change is merged.

#### Scenario: Cassette audit finds no raw credentials
- **WHEN** the cassette directory is scanned for patterns matching `Authorization: Basic [A-Za-z0-9+/=]+` or `Authorization: Bearer [A-Za-z0-9._-]+`
- **THEN** no matches are found (all values are placeholders)
