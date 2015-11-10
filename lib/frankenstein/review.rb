# Facilitate creating pull requests to update redirects
module Review
  require 'colored'
  # require 'parallel'

  # require 'frankenstein/constants'
  # require 'frankenstein/core'
  require 'frankenstein/github'
  require 'frankenstein/log'
  # require 'frankenstein/network'
  # require 'frankenstein/output'

  PRODUCT = 'review'
  PRODUCT_DESCRIPTION = 'Facilitate creating pull requests to update redirects'

  argv_1 = ARGV[0]
  if argv_1.nil?
    m = "#{PRODUCT.blue} #{PRODUCT_DESCRIPTION.white} \n"\
        "Usage: #{PRODUCT.blue} <#{'file'.white}> "
    puts m
    puts "\n"
    exit
  end

  unless Frankenstein.github_creds
    puts Frankenstein::GITHUB_CREDS_ERROR
    exit(1)
  end

  # unless File.exist? argv_1
  #   puts "#{PRODUCT.red} File #{argv1.white} does not exist"
  #   exit(1)
  # end

  puts "Processing #{argv_1.white}"

  file_redirects = 'temp-r'
  file_updated = 'temp-u'

  # check these files exist
  # logs_dir = Frankenstein::FILE_LOG_DIRECTORY

  file_copy = "#{argv_1}-copy"
  puts "file_copy: #{file_copy}"

  redirects_file = "#{argv_1}-redirects"
  puts "redirects_file: #{redirects_file}"
  c = File.read(redirects_file)

  puts c.class
  puts c

  log = Frankenstein::Log.new(false, 'temp-review')

  exit

  Frankenstein.core_process_redirects(
    file_redirects,
    file_copy,
    file_updated,
    redirects,
    log)
end
