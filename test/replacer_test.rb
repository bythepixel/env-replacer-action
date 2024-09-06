# frozen_string_literal: true

require "minitest/autorun"
require "fileutils"
require_relative "../lib/replacer"

class ReplacerTest < Minitest::Test
  def setup
    @file_path = "test_file"
    FileUtils.touch(@file_path)
  end

  def teardown
    FileUtils.rm(@file_path)
  end

  def test_it_can_be_constructed_from_args
    args = [@file_path, "environment", '{"key": "value"}']
    replacer = Replacer.from_args(args)
    assert_instance_of Replacer, replacer
  end

  def test_it_fails_if_not_given_three_args
    args = [@file_path, "environment"]
    assert_raises(ArgumentError) { Replacer.from_args(args) }
  end

  def test_it_fails_if_file_does_not_exist
    args = ["non_existent_file", "environment", '{"key": "value"}']
    assert_raises(ArgumentError) { Replacer.from_args(args) }
  end

  def test_it_fails_if_tokens_are_missing
    File.write(@file_path, "NAME={NAME}\nAGE={AGE}")
    args = [@file_path, "environment", '{"NAME": "Sean"}']
    assert_raises(Replacer::MissingTokensError) { Replacer.from_args(args) }
  end

  def test_it_replaces_tokens_in_a_file
    File.write(@file_path, "NAME={NAME}")
    args = [@file_path, "environment", '{"NAME": "Sean"}']
    Replacer.from_args(args).replace
    assert_equal "NAME=Sean", File.read(@file_path)
  end

  def test_it_defaults_to_environment_specific_token
    File.write(@file_path, "NAME={NAME}")
    args = [@file_path, "staging", '{"STAGING_NAME": "Seanster", "NAME": "Sean"}']
    Replacer.from_args(args).replace
    assert_equal "NAME=Seanster", File.read(@file_path)
  end
end
