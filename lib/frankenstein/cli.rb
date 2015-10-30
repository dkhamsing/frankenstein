# Process cli: command line interface
module Frankenstein
  class << self
    def option_value(name, separator)
      regex = "#{name}#{separator}"
      verbose "Regular expression: #{regex}"
      temp = ARGV.find { |e| /#{regex}/ =~ e }

      temp ? temp.split(separator)[1].to_i : nil
    end
  end # class
end
