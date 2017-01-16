module ValueParser
  def argument_values
    values.reject { |x| x.include? '-' }
  end

  def option_values
    values.reject do |x|
      !x.include?('-') ||
        x.include?('=') ||
        @parameter_options_prefixes.any? { |pref| x.start_with?(pref) }
    end
  end

  def option_with_parameter_values
    values - argument_values - option_values
  end

  def parse_arguments(runner)
    arguments.zip(argument_values).each { |(_n, b), v| b.call(runner, v) }
  end

  def parse_options(runner)
    option_values.each { |value| options[value].call(runner, true) }
  end

  def parse_options_with_parameter(runner)
    option_with_parameter_values.each do |value|
      option, val = parse_parameter_value(value)
      options_with_parameter[option].call(runner, val)
    end
  end

  def parse_parameter_value(value)
    option, val = value.split('=')
    unless val
      val = option
      @parameter_options_prefixes.each do |prefix|
        option = option.slice! prefix if option.start_with? prefix
      end
    end
    [option, val]
  end
end

class CommandParser
  include ValueParser

  attr_reader :command_name, :arguments, :options,
              :options_with_parameter, :values, :options_help

  def initialize(command_name)
    @command_name = command_name
    @arguments = []
    @options = {}
    @options_with_parameter = {}
    @parameter_options_prefixes = []
    @values = []
    @options_help = []
  end

  def argument(name, &block)
    arguments << [name, block]
  end

  def option(short_name, name, desc, &block)
    set_options(options, short_name, name, block)
    options_help << "    -#{short_name}, --#{name} #{desc}"
  end

  def option_with_parameter(short_name, name, desc, argument, &block)
    set_options(options_with_parameter, short_name, name, block)
    options_help << "    -#{short_name}, --#{name}=#{argument} #{desc}\n"
    @parameter_options_prefixes << "--#{name}"
    @parameter_options_prefixes << "-#{short_name}"
  end

  def set_options(options_to_set, short_name, name, block)
    options_to_set["--#{name}"] = block
    options_to_set["-#{short_name}"] = block
  end

  def parse(runner, values)
    @values = values
    parse_arguments(runner)
    parse_options(runner)
    parse_options_with_parameter(runner)
  end

  def help
    help_message = "Usage: #{command_name}"
    help_message << " #{argument_help}" unless arguments.empty?
    help_message << "\n#{options_help.join("\n")}" unless options_help.empty?
    help_message
  end

  private

  def argument_help
    arguments.map do |name, _y|
      "[#{name}]"
    end.join(' ')
  end
end

