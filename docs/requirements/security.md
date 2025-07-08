# Security Requirements
- All inputs must be sanitized (e.g., date format YYYY-MM-DD).
- Scripts must avoid using eval or unsafe shell interpolation.
- Network requests must use HTTPS and validate certificates.
- CLI tools must avoid writing secrets to disk or stdout.