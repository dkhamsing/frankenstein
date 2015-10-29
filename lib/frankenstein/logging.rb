module Frankenstein
  require 'frankenstein/constants'

  class << self
    def heat_index(count)
      count = count.to_i
      case
      when count>2000
        return heat << heat << heat << heat << heat
      when count>1000
        return heat << heat << heat << heat
      when count>500
        return heat << heat << heat
      when count>200
        return heat << heat
      when count>100
        return heat
      end
    end

    def pluralize(text, count)
      return text << "#{count > 1 ? "s" : ""}"
    end

    def in_white_list(input)
      WHITE_LIST_REGEXP.each { |regexp|
        if input.match(regexp)
          verbose "#{input} is in white list matching #{regexp}".white
          return true
        end
      }
      false
    end

    def status_glyph(status, url)
      if in_white_list(url)
        return "⚪  white list"
      end

      case
      when status == 200
        return "✅ "
      when status.to_s.start_with?("3")
        return "🔶 "
      when status.to_s.start_with?("4")
        return "🔴 "
      else
        return "⚪ "
      end
    end

    # logging
    def error_result_header(error)
      f_print "\n📋  frankenstein results: ".white
      f_puts error.red
    end

    def f_print(input)
      print input
      if $option_log_to_file
        franken_log(input)
      end
    end

    def f_puts(input)
      puts input
      if $option_log_to_file
        franken_log(input)
        franken_log("\n")
      end
    end

    def f_puts_with_index(index, total, input)
      if $number_of_threads == 0
        f_print "#{index}/#{total} "
      end
      f_puts input
    end

    def franken_log(input)
      File.open(FILE_LOG, 'a') { |f|
        f.write(input)
      }
    end

    def verbose(message)
      if $flag_verbose
        f_puts message
      end
    end
  end # class
end
