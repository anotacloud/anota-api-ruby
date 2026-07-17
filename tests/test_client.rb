# frozen_string_literal: true

require "minitest/autorun"
require "json"
require "anota_api"

# Records the requests it is handed and replays a canned response, so the
# client can be exercised without real network access.
class FakeResponse
  attr_reader :code, :body

  def initialize(code, body)
    @code = code.to_s
    @body = body
  end
end

class FakeHttp
  attr_reader :requests

  def initialize(response)
    @response = response
    @requests = []
  end

  def request(req)
    @requests << req
    @response
  end
end

class AnotaClientTest < Minitest::Test
  BASE = "https://example.test/api/v1"

  def build_client(response)
    http = FakeHttp.new(response)
    client = AnotaApi::Client.new(api_key: "anota_sk_test", base_url: BASE, http_factory: ->(_uri) { http })
    [client, http]
  end

  # (a) method + URL + auth header
  def test_list_forms_sends_get_with_bearer_header
    client, http = build_client(FakeResponse.new(200, "[]"))
    client.list_forms
    req = http.requests.first
    assert_instance_of Net::HTTP::Get, req
    assert_equal "#{BASE}/forms", req.uri.to_s
    assert_equal "Bearer anota_sk_test", req["Authorization"]
  end

  # (b) JSON body
  def test_create_submission_sends_json_body
    client, http = build_client(FakeResponse.new(200, "{}"))
    client.create_submission("form_1", { "f_1" => "hola" })
    req = http.requests.first
    assert_instance_of Net::HTTP::Post, req
    assert_equal "application/json", req["Content-Type"]
    assert_equal({ "answers" => { "f_1" => "hola" } }, JSON.parse(req.body))
  end

  # (c) problem-details error extraction
  def test_error_response_raises_api_error_with_status_and_detail
    client, = build_client(FakeResponse.new(400, '{"detail":"Error: bad"}'))
    error = assert_raises(AnotaApi::ApiError) { client.list_forms }
    assert_equal 400, error.status
    assert_equal "Error: bad", error.message
  end

  # (d) query building
  def test_list_submissions_builds_query
    client, http = build_client(FakeResponse.new(200, "{}"))
    client.list_submissions("form_1", page: 2, page_size: 10, status: "New")
    assert_equal "page=2&pageSize=10&status=New", http.requests.first.uri.query
  end

  # (d, cont.) nil query values are omitted
  def test_list_submissions_omits_nil_status
    client, http = build_client(FakeResponse.new(200, "{}"))
    client.list_submissions("form_1")
    assert_equal "page=1&pageSize=25", http.requests.first.uri.query
  end

  def test_error_message_falls_back_to_title_then_raw_body
    client, = build_client(FakeResponse.new(500, '{"title":"Server error"}'))
    assert_equal "Server error", assert_raises(AnotaApi::ApiError) { client.list_forms }.message

    client, = build_client(FakeResponse.new(502, "Bad Gateway"))
    assert_equal "Bad Gateway", assert_raises(AnotaApi::ApiError) { client.list_forms }.message
  end

  def test_empty_success_body_returns_nil
    client, = build_client(FakeResponse.new(204, ""))
    assert_nil client.delete_form("form_1")
  end

  def test_missing_api_key_raises
    assert_raises(ArgumentError) { AnotaApi::Client.new(api_key: "") }
  end
end
