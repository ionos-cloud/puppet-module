## ADDED Requirements

### Requirement: IONOS_API_URL must use HTTPS scheme
When the `IONOS_API_URL` environment variable is set, the module SHALL validate that the URL scheme is `https` before configuring the API client. Any other scheme SHALL cause a `Puppet::Error` to be raised with a message identifying the invalid scheme. There is no opt-out mechanism.

#### Scenario: HTTPS URL accepted
- **WHEN** `IONOS_API_URL` is set to a URL beginning with `https://`
- **THEN** the module configures the API client with that URL and proceeds normally

#### Scenario: HTTP URL rejected
- **WHEN** `IONOS_API_URL` is set to a URL beginning with `http://`
- **THEN** the module raises `Puppet::Error` containing the text `IONOS_API_URL must use HTTPS` before making any network call

#### Scenario: Unsupported scheme rejected
- **WHEN** `IONOS_API_URL` is set to a URL with a scheme other than `https` or `http` (e.g., `ftp://`)
- **THEN** the module raises `Puppet::Error` identifying the unsupported scheme

#### Scenario: Unset URL uses SDK default
- **WHEN** `IONOS_API_URL` is not set
- **THEN** the module does not perform scheme validation and uses the ionoscloud SDK's default HTTPS endpoint

### Requirement: URL validation occurs before credential attachment
The scheme check SHALL be performed before credentials (token, username, or password) are assigned to the API configuration object, so that plaintext transmission of credentials is impossible even on error paths.

#### Scenario: Credentials not attached on invalid URL
- **WHEN** `IONOS_API_URL` is set to `http://malicious.example.com` and `IONOS_TOKEN` is set
- **THEN** the module raises `Puppet::Error` before assigning `IONOS_TOKEN` to the API config
