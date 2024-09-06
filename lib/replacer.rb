require "json"

# Replace all given tokens in a file with the corresponding values
# Tokens are in the format {token_name}
# The values to replace the tokens with are passed in as a JSON string
# The json string should have keys that match token_name and values that are the replacement value
# We will first look for an environment specific version of the token, e.g. PRODUCTION_TOKEN_NAME
# If that is not found, we will look for the non-environment specific version
# If that is not found, we will raise an error
class Replacer
  class MissingTokensError < StandardError; end

  class << self
    # Factory to create a new Replacer instance from positional command line arguments
    def from_args(args)
      validate_args!(args)
      file_path, environment, json_key_values = args
      key_values = JSON.parse(json_key_values)
      new(file_path, environment, key_values)
    end

    private

    def validate_args!(args)
      return if args.length == 3

      raise ArgumentError, "Usage: ruby replacer.rb <file_path> <environment> <key_values_as_json>"
    end
  end

  def initialize(file_path, environment, key_values)
    @file_path = file_path
    @environment = environment
    @key_values = key_values
    validate!
  end

  def replace
    content = File.read(@file_path)
    tokens_needing_replacement.each do |token|
      content.gsub!("{#{token}}", get_value(token))
    end
    File.write(@file_path, content)
  end

  private

  def tokens_needing_replacement
    @tokens_needing_replacement ||= File.read(@file_path)
      .scan(/\{(\w+)\}/).flatten
  end

  # Get the value to replace the token with, prioritizing an environment specific version
  # @param token_to_replace [String]
  # @return [String, Nil]
  def get_value(token_to_replace)
    env_specific_token = @environment.upcase + "_" + token_to_replace
    @key_values[env_specific_token] || @key_values[token_to_replace]
  end

  # Validate that all tokens in the file have a corresponding value
  # @return [Nil]
  def validate!
    validate_file!
    validate_tokens!
  end

  def validate_file!
    raise ArgumentError, "File not found: #{@file_path}" unless File.exist?(@file_path)
  end

  def validate_tokens!
    tokens = tokens_needing_replacement
    missing_tokens = tokens.select { |token| get_value(token).nil? }
    return if missing_tokens.empty?

    raise MissingTokensError, "Missing values for tokens: #{missing_tokens.join(", ")}"
  end
end
