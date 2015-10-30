require 'frankenstein/constants'

# Logging
module Frankenstein
  class << self
    def heat_index(count)
      count = count.to_i
      case
      when count > 2000
        return heat << heat << heat << heat << heat
      when count > 1000
        return heat << heat << heat << heat
      when count > 500
        return heat << heat << heat
      when count > 200
        return heat << heat
      when count > 100
        return heat
      end
    end

    def pluralize(text, count)
      "#{text}#{count > 1 ? 's' : ''}"
    end

    def in_white_list(input)
      WHITE_LIST_REGEXP.each do |regexp|
        if input.match(regexp)
          verbose "#{input} is in white list matching #{regexp}".white
          return true
        end
      end
      false
    end

    def status_glyph(status, url)
      return '⚪  white list' if in_white_list(url)

      case
      when status == 200
        return '✅ '
      when status.to_s.start_with?('3')
        return '🔶 '
      when status.to_s.start_with?('4')
        return '🔴 '
      else
        return '⚪ '
      end
    end

    # logging
    def error_result_header(error)
      f_print "\n📋  frankenstein results: ".white
      f_puts error.red
    end

    def f_print(input)
      print input
      franken_log(input) if $option_log_to_file
    end

    def f_puts(input)
      puts input
      franken_log "#{input}\n" if $option_log_to_file
    end

    def f_puts_with_index(index, total, input)
      f_print "#{index}/#{total} " if $number_of_threads == 0
      f_puts input
    end

    def franken_log(input)
      File.open(FILE_LOG, 'a') { |f| f.write(input) }
    end

    def repo_log(repo, star_count, last_push)
      # print repo + star_count.to_s + last_push.to_s

      File.open(FILE_REPO, 'a') do |f|
        separator = '::'
        m = "#{repo}#{separator}#{star_count}#{separator}#{last_push} \n"
        f.write m
      end
    end

    def verbose(message)
      f_puts message if $flag_verbose
    end
  end # class
end
