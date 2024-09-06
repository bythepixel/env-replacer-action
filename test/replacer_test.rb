# frozen_string_literal: true

require "minitest/autorun"
require "fileutils"
require_relative "../lib/replacer"
require_relative "support/EnvironmentHelper"

class ReplacerTest < Minitest::Test
  include EnvironmentHelper
  def setup
    @file_path = "test_file"
    FileUtils.touch(@file_path)
  end

  def teardown
    FileUtils.rm(@file_path)
  end

  def test_it_can_be_constructed_from_args
    args = [@file_path, "environment"]
    replacer = Replacer.from_args(args)
    assert_instance_of Replacer, replacer
  end

  def test_it_fails_if_not_given_2_args
    args = [@file_path]
    assert_raises(ArgumentError) { Replacer.from_args(args) }
  end

  def test_it_fails_if_file_does_not_exist
    args = ["non_existent_file", "environment"]
    assert_raises(ArgumentError) { Replacer.from_args(args) }
  end

  def test_it_fails_if_tokens_are_missing
    with_environment({"NAME" => "Sean"}) do
      File.write(@file_path, "NAME={NAME}\nAGE={AGE}")
      args = [@file_path, "environment"]
      assert_raises(Replacer::MissingTokensError) { Replacer.from_args(args) }
    end
  end

  def test_it_replaces_tokens_in_a_file
    with_environment({"NAME" => "Sean"}) do
      File.write(@file_path, "NAME={NAME}")
      args = [@file_path, "environment"]
      Replacer.from_args(args).replace
      assert_equal "NAME=Sean", File.read(@file_path)
    end
  end

  def test_it_defaults_to_environment_specific_token
    with_environment({"STAGING_NAME" => "Seanster", "NAME" => "Sean"}) do
      File.write(@file_path, "NAME={NAME}")
      args = [@file_path, "staging"]
      Replacer.from_args(args).replace
      assert_equal "NAME=Seanster", File.read(@file_path)
    end
  end
end
