# Replace all given tokens in a file with the corresponding values from the ENV
# Tokens are in the format {token_name}
# The ENV should have keys that match token_name and values that are the replacement value
# We will first look for an environment prefixed version of the token, e.g. PRODUCTION_TOKEN_NAME
# If that is not found, we will look for the non-environment specific version
# If that is not found, we will raise an error

class Replacer
  class MissingTokensError < StandardError; end

  class << self
    def from(environment:, output_file:, template_path: nil, delete_template: true)
      template = template_path || "#{output_file}.#{environment}"
      fail_unless_file!(template)
      new(template, environment, output_file, delete_template: delete_template)
    end

    private

    def file_path(args)
      args.join(".")
    end

    def fail_unless_file!(file_path)
      raise ArgumentError, "File not found: #{File.expand_path(file_path)}" unless File.exist?(file_path)
    end
  end

  attr_reader :normalized_environment

  def initialize(template_path, environment, output_path, delete_template: true)
    @template_path = template_path
    @environment = environment
    @output_path = output_path
    @delete_template = delete_template
    @normalized_environment = environment.upcase.tr("-", "_")
    validate!
  end

  def replace
    content = File.read(@template_path)
    tokens_needing_replacement.each do |token|
      content.gsub!(/(?<!\$)\{#{token}\}/, get_value(token))
    end
    File.write(@output_path, content)
    File.delete(@template_path) if @delete_template && @output_path != @template_path
  end

  private

  def tokens_needing_replacement
    @tokens_needing_replacement ||= File.read(@template_path)
      .scan(/(?<!\$)\{(\w+)\}/).flatten
  end

  # Get the value to replace the token with, prioritizing an environment specific version
  # @param token_to_replace [String]
  # @return [String, Nil]
  def get_value(token_to_replace)
    env_specific_token = normalized_environment + "_" + token_to_replace
    ENV[env_specific_token] || ENV[token_to_replace]
  end

  # Validate that all tokens in the file have a corresponding value
  # @return [Nil]
  def validate!
    tokens = tokens_needing_replacement
    missing_tokens = tokens.select { |token| get_value(token).nil? }
    return if missing_tokens.empty?

    raise MissingTokensError, "Missing values for the #{normalized_environment} environment! Tokens with no values: #{missing_tokens.join(", ")}"
  end
end
