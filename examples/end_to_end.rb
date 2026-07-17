# frozen_string_literal: true

# End-to-end example: create a form, add a field, publish it, create a
# submission, and list submissions.
#
# Run it with your API key in the environment:
#
#   ANOTA_API_KEY=anota_sk_... ruby -Ilib examples/end_to_end.rb
#
require "anota_api"

api_key = ENV["ANOTA_API_KEY"]
abort "Set ANOTA_API_KEY (create one at https://anota.cloud/api-keys)" if api_key.nil? || api_key.empty?

client = AnotaApi::Client.new(api_key: api_key)

puts "Creating form..."
form = client.create_form(
  "Contact us",
  [{ "type" => "text", "label" => "Your name", "required" => true }],
  description: "Created from the Ruby SDK example"
)
form_id = form["id"]
puts "  form id: #{form_id}"

puts "Adding an email field..."
client.add_fields(form_id, [{ "type" => "email", "label" => "Your email", "required" => true }])

puts "Publishing..."
client.publish_form(form_id)

puts "Creating a submission..."
form = client.get_form(form_id)
first_field_id = form["fields"].first["id"]
submission = client.create_submission(form_id, { first_field_id => "Ada Lovelace" })
puts "  submission id: #{submission["id"]}"

puts "Listing submissions..."
result = client.list_submissions(form_id)
count = result.is_a?(Hash) ? (result["items"] || result["submissions"] || []).length : result.length
puts "  #{count} submission(s) so far"

puts "Done."
