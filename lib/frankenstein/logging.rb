require 'frankenstein/constants'

# Logging
module Frankenstein
  class << self
    def heat_index(count)
      count = count.to_i
      case
      when count > 2000
        return em_heat << em_heat << em_heat << em_heat << em_heat
      when count > 1000
        return em_heat << em_heat << em_heat << em_heat
      when count > 500
        return em_heat << em_heat << em_heat
      when count > 200
        return em_heat << em_heat
      when count > 100
        return em_heat
      end
    end

    def pluralize(text, count)
      "#{text}#{count > 1 ? 's' : ''}"
    end

    def in_white_saved(input)
      WHITE_LIST_REGEXP.each do |regexp|
        if input.match(regexp)
          verbose "#{input} is in white saved matching #{regexp}".white
          return true
        end
      end
      false
    end

    def status_glyph(status, url)
      return '⚪  white saved' if in_white_saved(url)

      case
      when status == 200
        return '✅ '
      when status.to_s.start_with?('3')
        return em_status_red
      when status.to_s.start_with?('4')
        return em_status_red
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

    def repo_log_json(list)
      f_puts "\nWriting repo log ... "
      json = if File.exist?(FILE_REPO)
               file = File.read(FILE_REPO)
               saved = JSON.parse(file)

               list.each do |x|
                 h = saved.map { |s| s if s['repo'] == x[:repo] }.compact.first
                 unless h.nil?
                   difference = x[:count] - h['count']
                   m = "#{x[:repo]} count difference: #{difference} #{em_star}"
                   f_puts m unless difference == 0
                   saved.delete(h)
                 end

                 saved.push(x)
               end

               saved
             else
               list
             end
      File.open(FILE_REPO, 'w') { |f| f.puts(json.to_json) }
    end

    def verbose(message)
      f_puts message if $flag_verbose
    end
  end # class
end
