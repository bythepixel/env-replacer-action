# Replace all given tokens in a file with the corresponding values from the ENV
# Tokens are in the format {token_name}
# The ENV should have keys that match token_name and values that are the replacement value
# We will first look for an environment prefixed version of the token, e.g. PRODUCTION_TOKEN_NAME
# If that is not found, we will look for the non-environment specific version
# If that is not found, we will raise an error
#
# Two ways to point at files:
#   * Convention (default): a sibling "<output>.<environment>" template is read and
#     "<output>" is written (the source template is then deleted). This is the
#     ".env.production -> .env" flow.
#   * Explicit: pass a template path and an output path directly. When the two are
#     equal the file is filled in place and not deleted. This supports files whose
#     name does not follow the "<output>.<environment>" convention, e.g.
#     ASP.NET Core's appsettings.Production.json.

class Replacer
  class MissingTokensError < StandardError; end

  class << self
    # Factory from positional command-line args following the sibling convention:
    #   replace <output_file_path> <environment>   (reads <output_file_path>.<environment>)
    def from_args(args)
      validate_args!(args)
      environment = args[1]
      template    = file_path(args)
      output      = template.gsub(".#{environment}", "")
      new(template, environment, output)
    end

    # Factory with explicit template/output paths (convention-independent).
    def from_paths(template_path, environment, output_path)
      raise ArgumentError, "File not found: #{File.expand_path(template_path)}" unless File.exist?(template_path)

      new(template_path, environment, output_path)
    end

    private

    def file_path(args)
      args.join(".")
    end

    def validate_args!(args)
      raise ArgumentError, "Usage: ruby replacer.rb <file_path> <environment>" if args.length != 2
      raise ArgumentError, "File not found: #{File.expand_path(file_path(args))}" unless File.exist?(file_path(args))
    end
  end

  attr_reader :normalized_environment

  def initialize(template_path, environment, output_path)
    @template_path = template_path
    @environment = environment
    @output_path = output_path
    @normalized_environment = environment.upcase.tr("-", "_")
    validate!
  end

  def replace
    content = File.read(@template_path)
    tokens_needing_replacement.each do |token|
      content.gsub!(/(?<!\$)\{#{token}\}/, get_value(token))
    end
    File.write(@output_path, content)
    # Only remove the template when it is a distinct sibling; an in-place fill
    # (output == template) must keep the file it just wrote.
    File.delete(@template_path) if @output_path != @template_path
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
