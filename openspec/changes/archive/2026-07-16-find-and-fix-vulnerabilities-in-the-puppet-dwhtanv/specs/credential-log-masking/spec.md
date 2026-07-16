## ADDED Requirements

### Requirement: Token values are never written to Puppet debug logs
The helper layer SHALL ensure that the value of `IONOS_TOKEN` is never passed as-is to `Puppet.debug`. Any debug message containing a token value SHALL have the token replaced with `[REDACTED]` before the call reaches the Puppet logger.

#### Scenario: Token value redacted from debug output
- **WHEN** `IONOS_DEBUG` is set to `true` and a Puppet catalog is applied
- **THEN** no debug log line written by the module contains the literal value of `IONOS_TOKEN`

#### Scenario: Token value redacted on debug error path
- **WHEN** an API call fails and the helper logs diagnostic details at debug level
- **THEN** the debug log does not include the token value

### Requirement: Username and password values are never written to Puppet debug logs
The helper layer SHALL ensure that the values of `IONOS_USERNAME` and `IONOS_PASSWORD` are never written to `Puppet.debug` output.

#### Scenario: Password redacted from debug output
- **WHEN** debug logging is enabled and the module logs API configuration details
- **THEN** the debug log message does not contain the value of `IONOS_PASSWORD`

#### Scenario: Username redacted from debug output
- **WHEN** debug logging is enabled and the module logs API configuration details
- **THEN** the debug log message does not contain the literal value of `IONOS_USERNAME`

### Requirement: Masking applied via log_debug wrapper; scope limited to Puppet.debug
Credential masking SHALL be implemented as a `log_debug(msg)` private helper method that scrubs known credential values before delegating to `Puppet.debug`. The Puppet logger itself SHALL NOT be monkey-patched or replaced. Masking SHALL NOT be applied to `Puppet.info`, `Puppet.warning`, or `Puppet.err` calls, as those call sites log only resource lifecycle events and do not include credential-adjacent values.

#### Scenario: log_debug used for credential-adjacent debug calls in helper.rb
- **WHEN** `helper.rb` is audited
- **THEN** all `Puppet.debug` calls that may include credential-adjacent data use `log_debug` instead of calling `Puppet.debug` directly with raw configuration values

#### Scenario: Non-sensitive debug messages pass through unchanged
- **WHEN** a debug message contains no credential values
- **THEN** the message is passed to `Puppet.debug` without modification
