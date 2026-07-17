# anota-api-ruby · Cliente Ruby oficial de la API de [anota](https://anota.cloud)

**[Read me in English](README.md)** · [Referencia interactiva de la API](https://anota.cloud/developers) · [Todos los SDK](https://github.com/anotacloud/anota-api)

![CI](https://github.com/anotacloud/anota-api-ruby/actions/workflows/ci.yml/badge.svg)

Crea y publica formularios, edita campos y lógica condicional, lee y escribe
respuestas, y conecta webhooks — todo lo que la API REST de anota puede hacer, desde Ruby.

Es un cliente ligero y sin dependencias: usa únicamente la biblioteca estándar de
Ruby (`net/http` + `json`), y cada método devuelve el JSON del servidor convertido en
Hashes y Arrays simples de Ruby. No hay clases de modelo de respuesta que aprender.

## Instalación

Agrégalo a tu `Gemfile` directamente desde GitHub:

```ruby
gem "anota-api", git: "https://github.com/anotacloud/anota-api-ruby"
```

Luego ejecuta `bundle install`. O descarga una copia y agrega `lib/` a tu ruta de carga:
[ZIP](https://github.com/anotacloud/anota-api-ruby/archive/refs/heads/main.zip) ·
[Tarball](https://github.com/anotacloud/anota-api-ruby/archive/refs/heads/main.tar.gz)

## Inicio rápido

```ruby
require "anota_api"

client = AnotaApi::Client.new(api_key: ENV.fetch("ANOTA_API_KEY"))

form = client.create_form(
  "Contáctanos",
  [{ "type" => "text", "label" => "Tu nombre", "required" => true }]
)
client.publish_form(form["id"])

submissions = client.list_submissions(form["id"])
puts submissions
```

## Autenticación

Crea una clave de API en tu workspace en https://anota.cloud/api-keys y pásala al
cliente. Las claves se ven como `anota_sk_…` y también habilitan el conector MCP de Claude.

```ruby
client = AnotaApi::Client.new(api_key: "anota_sk_...")
# Apunta a otro entorno si lo necesitas:
client = AnotaApi::Client.new(api_key: "anota_sk_...", base_url: "https://anota.cloud/api/v1")
```

## Todos los métodos

| # | Método | HTTP |
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

`fields`/`field` son hashes simples: `{ "type" => …, "label" => …, "required" => …, "options" => …, "rows" => …, "columns" => … }`.
`rules`/`rule`: `{ "match" => "all" | "any", "if" => [...], "then" => [...] }`.
`answers` es un hash indexado por el id del campo, con valores de tipo string o arreglo de strings.

Hay un script completo de ejemplo de extremo a extremo en [`examples/end_to_end.rb`](examples/end_to_end.rb).

## Errores

Las respuestas que no sean 2xx lanzan `AnotaApi::ApiError` con el código de estado HTTP y el mensaje del servidor:

```ruby
begin
  client.get_form("no-existe")
rescue AnotaApi::ApiError => e
  warn "#{e.status}: #{e.message}"
end
```

Nota: una vez que un formulario ha sido publicado, sus campos existentes quedan bloqueados
(`edit_field`/`delete_field` devuelven 400); siempre puedes usar `add_fields`.

## Licencia

MIT
