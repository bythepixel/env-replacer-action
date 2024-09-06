# Replace all given tokens in a file with the corresponding values from the ENV
# Tokens are in the format {token_name}
# The ENV should have keys that match token_name and values that are the replacement value
# We will first look for an environment prefixed version of the token, e.g. PRODUCTION_TOKEN_NAME
# If that is not found, we will look for the non-environment specific version
# If that is not found, we will raise an error
class Replacer
  class MissingTokensError < StandardError; end

  class << self
    # Factory to create a new Replacer instance from positional command line arguments
    def from_args(args)
      validate_args!(args)
      file_path, environment = args
      new(file_path, environment)
    end

    private

    def validate_args!(args)
      return if args.length == 2

      raise ArgumentError, "Usage: ruby replacer.rb <file_path> <environment>"
    end
  end

  def initialize(file_path, environment)
    @file_path = file_path
    @environment = environment
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
    ENV[env_specific_token] || ENV[token_to_replace]
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
