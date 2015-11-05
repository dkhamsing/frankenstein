# Logger
module Frankenstein
  # Logger
  class Log
    def initialize(opt_verbose, opt_write_to_file, argv1)
      @verbose = opt_verbose
      @write_to_file = opt_write_to_file

      epoch = Time.now.to_i
      filtered_argv1 = argv1.gsub(%r{(:|\/)}, '-')
      today = Date.today
      @identifier = "#{epoch}-#{today}-#{filtered_argv1}"

      @file_log = filename(FILE_LOG)
    end

    def filename(extension)
      "#{FILE_LOG_DIRECTORY}/#{@identifier}-#{extension}"
    end

    def error(message)
      add "#{Frankenstein.em_mad}  Error: #{message}".red
    end

    def error_header(message)
      m = "\n📋  #{PRODUCT} results: ".white
      my_print m
      add message.red
    end

    def add(message)
      puts message
      file_write "#{message}\n" if @write_to_file
    end

    def my_print(message)
      print message
      file_write message if @write_to_file
    end

    def file_write(message)
      File.open(@file_log, 'a') { |f| f.write(message) }
    end

    def verbose(message)
      add message if @verbose
    end
  end
end
