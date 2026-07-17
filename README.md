# anota-api-ruby · Official Ruby client for the [anota](https://anota.cloud) API

**[Léeme en español](README.es.md)** · [Interactive API reference](https://anota.cloud/developers) · [All SDKs](https://github.com/anotacloud/anota-api)

![CI](https://github.com/anotacloud/anota-api-ruby/actions/workflows/ci.yml/badge.svg)

Create and publish forms, edit fields and conditional logic, read and write
submissions, and wire webhooks — everything the anota REST API can do, from Ruby.

It is a thin, dependency-free client: it uses only the Ruby standard library
(`net/http` + `json`), and every method returns the server's JSON parsed into
plain Ruby Hashes and Arrays. There are no response model classes to learn.

## Install

Add it to your `Gemfile` straight from GitHub:

```ruby
gem "anota-api", git: "https://github.com/anotacloud/anota-api-ruby"
```

Then `bundle install`. Or download a snapshot and put `lib/` on your load path:
[ZIP](https://github.com/anotacloud/anota-api-ruby/archive/refs/heads/main.zip) ·
[Tarball](https://github.com/anotacloud/anota-api-ruby/archive/refs/heads/main.tar.gz)

## Quickstart

```ruby
require "anota_api"

client = AnotaApi::Client.new(api_key: ENV.fetch("ANOTA_API_KEY"))

form = client.create_form(
  "Contact us",
  [{ "type" => "text", "label" => "Your name", "required" => true }]
)
client.publish_form(form["id"])

submissions = client.list_submissions(form["id"])
puts submissions
```

## Authentication

Create an API key in your workspace at https://anota.cloud/api-keys and pass it to the
client. Keys look like `anota_sk_…` and also power the Claude MCP connector.

```ruby
client = AnotaApi::Client.new(api_key: "anota_sk_...")
# Point at a different environment if you need to:
client = AnotaApi::Client.new(api_key: "anota_sk_...", base_url: "https://anota.cloud/api/v1")
```

## All methods

| # | Method | HTTP |
|---|---|---|
| 1 | `list_forms` | `GET /forms` |
| 2 | `create_form(title, fields, description: nil)` | `POST /forms` |
| 3 | `get_form(form_id)` | `GET /forms/{formId}` |
| 4 | `add_fields(form_id, fields)` | `POST /forms/{formId}/fields` |
| 5 | `edit_field(form_id, field_id, field)` | `PATCH /forms/{formId}/fields/{fieldId}` |
| 6 | `delete_field(form_id, field_id)` | `DELETE /forms/{formId}/fields/{fieldId}` |
| 7 | `publish_form(form_id)` | `POST /forms/{formId}/publish` |
| 8 | `rename_form(form_id, title)` | `PATCH /forms/{formId}` |
| 9 | `set_pdf_template(form_id, key)` | `PUT /forms/{formId}/pdf-template` |
| 10 | `delete_form(form_id)` | `DELETE /forms/{formId}` |
| 11 | `clone_form(form_id)` | `POST /forms/{formId}/clone` |
| 12 | `add_logic_rules(form_id, rules)` | `POST /forms/{formId}/logic-rules` |
| 13 | `edit_logic_rule(form_id, rule_id, rule)` | `PUT /forms/{formId}/logic-rules/{ruleId}` |
| 14 | `delete_logic_rule(form_id, rule_id)` | `DELETE /forms/{formId}/logic-rules/{ruleId}` |
| 15 | `list_submissions(form_id, page: 1, page_size: 25, status: nil)` | `GET /forms/{formId}/submissions` |
| 16 | `get_submission(submission_id)` | `GET /submissions/{submissionId}` |
| 17 | `create_submission(form_id, answers)` | `POST /forms/{formId}/submissions` |
| 18 | `set_submission_status(submission_id, status)` | `PATCH /submissions/{submissionId}/status` |
| 19 | `delete_submission(submission_id)` | `DELETE /submissions/{submissionId}` |
| 20 | `submission_stats(form_id)` | `GET /forms/{formId}/stats` |
| 21 | `list_templates(language: "es")` | `GET /templates` |
| 22 | `create_form_from_template(template_id)` | `POST /forms/from-template/{templateId}` |
| 23 | `list_webhooks(form_id)` | `GET /forms/{formId}/webhooks` |
| 24 | `add_webhook(form_id, url)` | `POST /forms/{formId}/webhooks` |
| 25 | `delete_webhook(form_id, webhook_id)` | `DELETE /forms/{formId}/webhooks/{webhookId}` |

`fields`/`field` are plain hashes: `{ "type" => …, "label" => …, "required" => …, "options" => …, "rows" => …, "columns" => … }`.
`rules`/`rule`: `{ "match" => "all" | "any", "if" => [...], "then" => [...] }`.
`answers` is a hash keyed by field id, with string or array-of-string values.

A runnable end-to-end script lives in [`examples/end_to_end.rb`](examples/end_to_end.rb).

## Errors

Non-2xx responses raise `AnotaApi::ApiError` with the HTTP status and the server's message:

```ruby
begin
  client.get_form("does-not-exist")
rescue AnotaApi::ApiError => e
  warn "#{e.status}: #{e.message}"
end
```

Note: once a form has been published, its existing fields are locked
(`edit_field`/`delete_field` return 400); you can always `add_fields`.

## License

MIT
