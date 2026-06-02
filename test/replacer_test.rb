# frozen_string_literal: true

require "minitest/autorun"
require "fileutils"
require_relative "../lib/replacer"
require_relative "support/EnvironmentHelper"

class ReplacerTest < Minitest::Test
  include EnvironmentHelper

  def setup
    @environment = "staging"
    @file_name = "test_file"
    @file_path = "#{@file_name}.#{@environment}"
    FileUtils.touch(@file_path)
  end

  def teardown
    FileUtils.rm(@file_path) if File.exist?(@file_path)
    FileUtils.rm(@file_name) if File.exist?(@file_name)
  end

  def test_it_can_be_constructed
    replacer = Replacer.from(environment: @environment, output_file: @file_name)
    assert_instance_of Replacer, replacer
  end

  def test_it_fails_if_file_does_not_exist
    assert_raises(ArgumentError) { Replacer.from(environment: "environment", output_file: "non_existent_file") }
  end

  def test_it_fails_if_the_environment_doesnt_match
    assert_raises(ArgumentError) { Replacer.from(environment: "non_existent_environment", output_file: @file_name) }
  end

  def test_it_fails_if_tokens_are_missing
    with_environment({"NAME" => "Sean"}) do
      File.write(@file_path, "NAME={NAME}\nAGE={AGE}")
      assert_raises(Replacer::MissingTokensError) { Replacer.from(environment: @environment, output_file: @file_name) }
    end
  end

  def test_it_ignore_dollar_sign_prefixed_tokens
    File.write(@file_path, "NAME=Cool\nOTHER_NAME=${NAME}")
    Replacer.from(environment: @environment, output_file: @file_name).replace
    assert_equal "NAME=Cool\nOTHER_NAME=${NAME}", File.read(@file_name)
  end

  def test_it_replaces_tokens_in_a_file
    with_environment({"NAME" => "Sean"}) do
      File.write(@file_path, "NAME={NAME}")
      Replacer.from(environment: @environment, output_file: @file_name).replace
      assert_equal "NAME=Sean", File.read(@file_name)
    end
  end

  def test_it_deletes_the_environment_specific_file_after_replacing
    with_environment({"NAME" => "Sean"}) do
      File.write(@file_path, "NAME={NAME}")
      Replacer.from(environment: @environment, output_file: @file_name).replace
      refute File.exist?(@file_path)
    end
  end

  def test_it_defaults_to_environment_specific_token
    with_environment({"STAGING_NAME" => "Seanster", "NAME" => "Sean"}) do
      File.write(@file_path, "NAME={NAME}")
      Replacer.from(environment: @environment, output_file: @file_name).replace
      assert_equal "NAME=Seanster", File.read(@file_name)
    end
  end

  def test_it_does_not_replace_dollar_sign_prefixed_tokens
    with_environment({"NAME" => "Sean"}) do
      File.write(@file_path, "NAME={NAME}\nOTHER_NAME=${NAME}")
      Replacer.from(environment: @environment, output_file: @file_name).replace

      assert_equal "NAME=Sean\nOTHER_NAME=${NAME}", File.read(@file_name)
    end
  end

  def test_it_supports_hyphenated_environment_names
    environment = "test-environment"
    file_path = "#{@file_name}.#{environment}"
    FileUtils.touch(file_path)

    with_environment({"TEST_ENVIRONMENT_SECRET_1" => "secret_value"}) do
      File.write(file_path, "SECRET_1={SECRET_1}")
      Replacer.from(environment: environment, output_file: @file_name).replace
      assert_equal "SECRET_1=secret_value", File.read(@file_name)
    end
  ensure
    FileUtils.rm(file_path) if File.exist?(file_path)
  end

  def test_keeps_template_when_delete_is_false
    with_environment({"NAME" => "Sean"}) do
      File.write(@file_path, "NAME={NAME}")
      Replacer.from(environment: @environment, output_file: @file_name, delete_template: false).replace
      assert_equal "NAME=Sean", File.read(@file_name)
      assert File.exist?(@file_path), "sibling template must be kept when delete_template is false"
    end
  end

  def test_from_fills_a_json_file_in_place
    template = "appsettings.Production.json"
    File.write(template, %({"ClientId":"{RAMP_CLIENT_ID}"}))
    with_environment({"RAMP_CLIENT_ID" => "abc123"}) do
      Replacer.from(environment: "production", output_file: template, template_path: template, delete_template: false).replace
      assert_equal %({"ClientId":"abc123"}), File.read(template)
      assert File.exist?(template), "in-place fill must keep the file"
    end
  ensure
    FileUtils.rm(template) if File.exist?(template)
  end

  def test_from_with_distinct_output_deletes_the_template
    template = "config.template.json"
    output = "config.json"
    File.write(template, %({"name":"{NAME}"}))
    with_environment({"NAME" => "Sean"}) do
      Replacer.from(environment: "production", output_file: output, template_path: template).replace
      assert_equal %({"name":"Sean"}), File.read(output)
      refute File.exist?(template), "a distinct output must delete the template"
    end
  ensure
    FileUtils.rm(template) if File.exist?(template)
    FileUtils.rm(output) if File.exist?(output)
  end

  def test_from_keeps_template_when_delete_is_false
    template = "config.template.json"
    output = "config.json"
    File.write(template, %({"name":"{NAME}"}))
    with_environment({"NAME" => "Sean"}) do
      Replacer.from(environment: "production", output_file: output, template_path: template, delete_template: false).replace
      assert_equal %({"name":"Sean"}), File.read(output)
      assert File.exist?(template), "template must be kept when delete_template is false"
    end
  ensure
    FileUtils.rm(template) if File.exist?(template)
    FileUtils.rm(output) if File.exist?(output)
  end

  def test_from_prefers_environment_specific_token
    template = "appsettings.Production.json"
    File.write(template, %({"ClientId":"{RAMP_CLIENT_ID}"}))
    with_environment({"PRODUCTION_RAMP_CLIENT_ID" => "prod", "RAMP_CLIENT_ID" => "bare"}) do
      Replacer.from(environment: "production", output_file: template, template_path: template, delete_template: false).replace
      assert_equal %({"ClientId":"prod"}), File.read(template)
    end
  ensure
    FileUtils.rm(template) if File.exist?(template)
  end

  def test_from_fails_if_template_missing
    assert_raises(ArgumentError) { Replacer.from(environment: "production", output_file: "nope.json", template_path: "nope.json") }
  end
end
