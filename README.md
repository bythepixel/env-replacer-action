# BTP Environment Replacer Github Action

This is an improved github action to handle replacing environment secrets in our .env files.
It validates the .env file to ensure that we actually have defined a secret for each key in the .env file where it is required.

## Conventions
- The action will look for a file named `.env.${environment-name}` where `${environment-name}` is the value of the `environment-name` input.
- Your .env file should use the convention `SECRET_KEY={SECRET_KEY}` for any key you want replaced
- The action will check your secrets you pass in, and replace them using the following priority:
  1. ENVIRONMENT_NAME_SECRET_KEY (e.g. STAGING_SECRET_KEY will replace SECRET_KEY in .env.staging)
  2. SECRET_KEY (e.g. SECRET_KEY will replace SECRET_KEY in .env.staging only if STAGING_SECRET_KEY is not defined)

## Usage

The following is an example of how to use this action in your github workflow.
```yaml
name: Replace Environment Secrets
uses: bythepixel/env-replacer-action@1.0.0
with:
    environment-name: staging
    env-file-path: .env
    secrets: ${{ toJSON(secrets) }}
```