# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

# Ruby client for the anota API (https://anota.cloud).
#
# A thin, dependency-free wrapper over the 25-operation REST API. Every method
# returns the server's JSON parsed into plain Ruby Hashes/Arrays; there are no
# rigid response model classes.
module AnotaApi
  VERSION = "2.0.0"

  # Raised for any non-2xx response. Carries the HTTP +status+ code and the
  # server's message (the problem-details +detail+, falling back to +title+,
  # then the raw body). Network failures surface as the native Ruby exception,
  # not wrapped in this class.
  class ApiError < StandardError
    attr_reader :status

    def initialize(status, message)
      @status = status
      super(message)
    end
  end

  # The API client. Create one with your API key:
  #
  #   client = AnotaApi::Client.new(api_key: ENV.fetch("ANOTA_API_KEY"))
  #   client.list_forms
  #
  class Client
    DEFAULT_BASE_URL = "https://anota.cloud/api/v1"

    METHODS = {
      "GET" => Net::HTTP::Get,
      "POST" => Net::HTTP::Post,
      "PATCH" => Net::HTTP::Patch,
      "PUT" => Net::HTTP::Put,
      "DELETE" => Net::HTTP::Delete,
    }.freeze

    # +http_factory+ is an injection seam for tests: a callable that receives a
    # URI and returns an object responding to +#request(req)+ (a configured
    # Net::HTTP by default).
    def initialize(api_key:, base_url: DEFAULT_BASE_URL, http_factory: nil)
      raise ArgumentError, "api_key is required (create one at https://anota.cloud/api-keys)" if api_key.nil? || api_key.empty?

      @api_key = api_key
      @base_url = base_url.gsub(%r{/+\z}, "")
      @http_factory = http_factory || lambda do |uri|
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == "https")
        http
      end
    end

    # ----- forms -----
    def list_forms
      request("GET", "/forms")
    end

    def create_form(title, fields, description: nil)
      request("POST", "/forms", body: { title: title, fields: fields, description: description })
    end

    def get_form(form_id)
      request("GET", "/forms/#{form_id}")
    end

    def add_fields(form_id, fields)
      request("POST", "/forms/#{form_id}/fields", body: { fields: fields })
    end

    def edit_field(form_id, field_id, field)
      request("PATCH", "/forms/#{form_id}/fields/#{encode(field_id)}", body: { field: field })
    end

    def delete_field(form_id, field_id)
      request("DELETE", "/forms/#{form_id}/fields/#{encode(field_id)}")
    end

    def publish_form(form_id)
      request("POST", "/forms/#{form_id}/publish")
    end

    def rename_form(form_id, title)
      request("PATCH", "/forms/#{form_id}", body: { title: title })
    end

    def set_pdf_template(form_id, key)
      request("PUT", "/forms/#{form_id}/pdf-template", body: { key: key })
    end

    def delete_form(form_id)
      request("DELETE", "/forms/#{form_id}")
    end

    def clone_form(form_id)
      request("POST", "/forms/#{form_id}/clone")
    end

    # ----- logic rules -----
    def add_logic_rules(form_id, rules)
      request("POST", "/forms/#{form_id}/logic-rules", body: { rules: rules })
    end

    def edit_logic_rule(form_id, rule_id, rule)
      request("PUT", "/forms/#{form_id}/logic-rules/#{encode(rule_id)}", body: { rule: rule })
    end

    def delete_logic_rule(form_id, rule_id)
      request("DELETE", "/forms/#{form_id}/logic-rules/#{encode(rule_id)}")
    end

    # ----- submissions -----
    def list_submissions(form_id, page: 1, page_size: 25, status: nil)
      request("GET", "/forms/#{form_id}/submissions", query: { "page" => page, "pageSize" => page_size, "status" => status })
    end

    def get_submission(submission_id)
      request("GET", "/submissions/#{submission_id}")
    end

    def create_submission(form_id, answers)
      request("POST", "/forms/#{form_id}/submissions", body: { answers: answers })
    end

    def set_submission_status(submission_id, status)
      request("PATCH", "/submissions/#{submission_id}/status", body: { status: status })
    end

    def delete_submission(submission_id)
      request("DELETE", "/submissions/#{submission_id}")
    end

    def submission_stats(form_id)
      request("GET", "/forms/#{form_id}/stats")
    end

    # ----- templates -----
    def list_templates(language: "es")
      request("GET", "/templates", query: { "language" => language })
    end

    def create_form_from_template(template_id)
      request("POST", "/forms/from-template/#{template_id}")
    end

    # ----- webhooks -----
    # Lists a form's webhooks. Each row has id, url, events, enabled, secretHint and secretNote.
    # The full signing secret is never returned here: secretHint is a masked form
    # ("whsec_…" + last 4 characters, or just "whsec_…" for short secrets) that identifies
    # which secret a receiver holds, and secretNote explains the show-once rule. To replace a
    # lost secret, delete the webhook and add it again.
    def list_webhooks(form_id)
      request("GET", "/forms/#{form_id}/webhooks")
    end

    # Registers a webhook URL that receives submission.created events. The response
    # (id, formId, url, secret, note) is the ONLY place the full signing secret appears:
    # store it now, it cannot be read back later (list_webhooks shows only secretHint).
    def add_webhook(form_id, url)
      request("POST", "/forms/#{form_id}/webhooks", body: { url: url })
    end

    def delete_webhook(form_id, webhook_id)
      request("DELETE", "/forms/#{form_id}/webhooks/#{webhook_id}")
    end

    private

    def request(method, path, body: nil, query: nil)
      uri = URI.parse(@base_url + path)
      if query
        filtered = query.reject { |_, v| v.nil? }
        uri.query = URI.encode_www_form(filtered) unless filtered.empty?
      end

      request_class = METHODS.fetch(method) { raise ArgumentError, "Unsupported HTTP method: #{method}" }
      req = request_class.new(uri)
      req["Authorization"] = "Bearer #{@api_key}"
      unless body.nil?
        req["Content-Type"] = "application/json"
        req.body = JSON.generate(body)
      end

      response = @http_factory.call(uri).request(req)
      status = response.code.to_i
      text = response.body.to_s

      unless (200..299).cover?(status)
        message = text
        begin
          problem = JSON.parse(text)
          message = (problem["detail"] || problem["title"] || text) if problem.is_a?(Hash)
        rescue JSON::ParserError
          # non-JSON body: keep the raw text
        end
        raise ApiError.new(status, message)
      end

      text.empty? ? nil : JSON.parse(text)
    end

    def encode(segment)
      URI.encode_www_form_component(segment.to_s).gsub("+", "%20")
    end
  end
end
