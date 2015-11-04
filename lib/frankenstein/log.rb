# Logger
module Frankenstein

  # Logger
  class Log
    # require constants, emoji, colored

    def initialize(opt_verbose, opt_write_to_file)
      @verbose = opt_verbose
      @write_to_file = opt_write_to_file
      # puts "log verbose=#{@verbose}"
      # puts "log write to file=#{@write_to_file}"
    end

    def error(message)
      self.add "#{em_mad} Error: #{message}".red
    end

    def error_header(message)
      m = "\n📋  #{PRODUCT} results: ".white
      self.my_print m
      self.add message.red
    end

    def add(message)
      puts message
      self.file_write message if @write_to_file
    end

    def my_print(message)
      print message
      self.file_write message if @write_to_file
    end

    def file_write(message)
      File.open(FILE_LOG, 'a') { |f| f.write(message) }
    end

    def verbose(message)
      self.add message if @verbose
    end
  end
end
