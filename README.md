# BTP Environment Replacer Github Action

This is an improved github action to handle replacing environment secrets in our .env files.
It validates the .env file to ensure that we actually have defined a secret for each key in the .env file where it is required.

## Conventions
- The action will look for a file named `.env.${environment-name}` where `${environment-name}` is the value of the `environment-name` input.
- Your .env file should use the convention `SECRET_KEY={SECRET_KEY}` for any key you want replaced
- The action will check your secrets you pass in, and replace them using the following priority:
  1. ENVIRONMENT_NAME_SECRET_KEY (e.g. STAGING_SECRET_KEY will replace SECRET_KEY in .env.staging)
  2. SECRET_KEY (e.g. SECRET_KEY will replace SECRET_KEY in .env.staging only if STAGING_SECRET_KEY is not defined)

## Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `secrets` | Yes | — | JSON glob of all secrets (`${{ toJSON(secrets) }}`). |
| `environment-name` | Yes | — | The environment to replace variables for (e.g. `staging`). |
| `env-file-path` | Yes | — | Path to the output file. |
| `template-file-path` | No | — | Explicit path to the template file. Use this when the template does not follow the `<env-file-path>.<environment-name>` naming convention (e.g. `appsettings.Production.json`). When omitted, the template is inferred from `env-file-path` + `environment-name`. |
| `delete-template` | No | `true` | Whether to delete the template file after writing the output. Set to `false` to keep it. |
| `additional-variables` | No | `{}` | JSON object of extra non-secret variables to substitute (e.g. `{"APP_SHA": "abc123"}`). |

## Usage

**Convention mode** — template is inferred from `env-file-path` + `environment-name`:
```yaml
- name: Replace Environment Secrets
  uses: bythepixel/env-replacer-action@1.0.0
  with:
    environment-name: staging
    env-file-path: .env
    secrets: ${{ toJSON(secrets) }}
```

**Explicit template mode** — use `template-file-path` when the template doesn't follow the standard naming convention:
```yaml
- name: Replace Environment Secrets
  uses: bythepixel/env-replacer-action@1.0.0
  with:
    environment-name: production
    template-file-path: appsettings.Production.json
    env-file-path: appsettings.json
    secrets: ${{ toJSON(secrets) }}
```

If you have additional variables that are not secrets but are dynamic, pass them via `additional-variables`:
```yaml
- name: Replace Environment Secrets
  uses: bythepixel/env-replacer-action@1.0.0
  with:
    environment-name: staging
    env-file-path: .env
    secrets: ${{ toJSON(secrets) }}
    additional-variables: '{"APP_SHA": "${{ env.sha }}" }'
```

To keep the template file after replacement (e.g. for debugging), set `delete-template: false`:
```yaml
- name: Replace Environment Secrets
  uses: bythepixel/env-replacer-action@1.0.0
  with:
    environment-name: staging
    env-file-path: .env
    secrets: ${{ toJSON(secrets) }}
    delete-template: false
```

## Examples
There is an example workflow [here](https://github.com/bythepixel/env-replacer-action/actions/workflows/example-workflow.yml) that you can run manually in your browser to see the expected output.
You can cross reference the [examples](./examples) directory as well as the defined [secrets](https://github.com/bythepixel/env-replacer-action/settings/secrets/actions) for this repository to understand how the action works. 

## Assumptions
- This action is written as a "composite" action, meaning it runs on github runner that uses it. 
- It does not use docker or any other dependencies. It is written in Ruby with no gem dependencies. Github runners come with Ruby pre-installed and we are not using any version specific features.  
  - The moment you need to use a gem, you will need to update the action to install a specific ruby version and bundle install the gems. 
- This action will take the template file, replace all the keys with the secrets you pass in, and write to the output file you specify. By default it deletes the template file after writing; set `delete-template: false` to keep it.

# Local Development

## Requirements
- Ruby (asdf is the recommended version manager)

## Setup
1. Clone the repository
2. Run `bundle install` to install the required gems

## Running the tests
```bash
rake
```


## Linting
```bash
bundle exec standardrb --fix
```

