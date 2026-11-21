# Editor compatibility specs

These specs lock in the Ruby 4 / Rails 8 behavior this editor needs. They sit next to the older suites and do not replace them.

Run them from the cartodb checkout against the test database (`carto_db_test`) and a test Redis. Do not point `RAILS_ENV=test` at the production database.

## Rails

One file covers the flows that do not need a populated database:

```bash
bundle exec rspec spec/models/carto/editor_flows_spec.rb
```

That file checks:

- An organization admin receives `CREATEROLE` before the rest of owner setup. Group creation runs `CREATE ROLE` as that user, and the privilege is not inherited.
- Dataset and map presenters accept keyword options.
- Map options and slide transitions survive JSON columns and `ActionController::Parameters`.
- Widget options and organization SAML settings load when the stored value is a JSON string.
- OAuth signing recognizes `ActionDispatch::Request`, which the public map list uses.

Examples added to existing files, with a filter so the rest of those files is not required:

```bash
bundle exec rspec spec/requests/carto/api/records_controller_spec.rb -e "dataset row parameters"
bundle exec rspec spec/requests/carto/api/permissions_controller_spec.rb -e "form parameters"
bundle exec rspec spec/requests/admin/organizations_controller_spec.rb -e "settings form"
bundle exec rspec spec/queries/carto/visualization_query_searcher_spec.rb -e "quote"
bundle exec rspec spec/models/carto/visualization_spec.rb -e "#widgets"
```

| Spec | What it checks |
| --- | --- |
| `spec/requests/carto/api/records_controller_spec.rb` | A new dataset row keeps column values and drops `api_key`, `user_domain`, and the other request fields. Parameters are converted to a hash before `symbolize_keys`. |
| `spec/requests/carto/api/permissions_controller_spec.rb` | Sharing a map accepts an ACL posted as form parameters. |
| `spec/requests/admin/organizations_controller_spec.rb` | Organization settings save the `carto_organization` fields the settings form posts. |
| `spec/queries/carto/visualization_query_searcher_spec.rb` | A dataset or map search that contains a quote does not raise. |
| `spec/models/carto/visualization_spec.rb` | Loading widgets for a map returns a list. |

The request specs need the normal test users, PostgreSQL extensions, and Redis. `editor_flows_spec.rb` only needs the test boot.

## Builder

Column and row creation updates an existing notice instead of replacing it. The notice object has to come back from that update, or the success handler calls `set` on an empty value.

```bash
npm run test:builder
```

The examples are:

- `lib/assets/test/spec/builder/components/notifier/notifier-model.spec.js`
- `lib/assets/test/spec/builder/components/notifier/notifier-collection.spec.js`

`npm run test:builder` builds the Builder specs and opens them in a browser. It needs the frontend dependencies installed.
