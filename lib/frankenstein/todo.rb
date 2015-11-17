# Add a repo to the frankenstein to do list
module Todo
  require 'colored'

  require 'frankenstein/constants'
  require 'frankenstein/core'
  require 'frankenstein/io'

  PRODUCT = 'todo'

  OPTION_LIST = 'list'

  LEADING_SPACE = '    '

  argv1 = ARGV[0]
  o_p = PRODUCT.blue
  if argv1.nil?
    o_r = 'repo'.white
    o_l = OPTION_LIST.blue
    u = 'Add a repo to run frankenstein on later'
    m = "#{o_p} #{u.white} \n"\
        "#{LEADING_SPACE} Usage: #{o_p} <#{o_r}> \n"\
        "#{LEADING_SPACE} Usage: #{o_p} #{o_l}"
    puts m
    exit
  end

  if argv1 == OPTION_LIST
    l = Frankenstein.io_json_read Frankenstein::FILE_TODO
    l.each do |x|
      repo = x['repo']
      puts " #{repo.white}"
    end
    puts "#{o_p} items: #{l.count.to_s.white}"
    exit
  end

  item = {
    repo: argv1
  }

  l = Frankenstein.core_todo_add item

  puts "Added #{argv1.white} to #{o_p}"
  puts "#{o_p} items: #{l.count.to_s.white}"
end
