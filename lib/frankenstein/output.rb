# Output
module Frankenstein
  class << self
    def elapsed(elapsed_seconds)
      case
      when elapsed_seconds > 60
        minutes = (elapsed_seconds / 60).floor
        seconds = elapsed_seconds - minutes * 60
        m = "#{minutes.round(0)} #{pluralize 'minute', minutes} "
        m << "#{seconds > 0 ? seconds.round(0).to_s << 's' : ''}"
      else
        "#{elapsed_seconds.round(2)} #{pluralize 'second', elapsed_seconds}"
      end
    end

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

    def pluralize2(count, text)
      "#{count} #{text}#{count > 1 ? 's' : ''}"
    end

    def in_white_list(input, cli_wl, log)
      white_list = cli_wl ? WHITE_LIST_REGEXP.dup.push(cli_wl.split('^')).flatten : WHITE_LIST_REGEXP
      white_list.each do |regexp|
        if input.match(regexp)
          log.verbose "#{input} is in white list matching #{regexp}".white
          return true
        end
      end
      false
    end

    def output_status(flag_minimize_output, status, link, log)
      if flag_minimize_output
        log.my_print status_glyph status, link, log
      else
        m = status_glyph(status, link, log)
        m << ' '
        m << "#{status} " unless status == 200
        m << link
        log.add m
      end
    end

    def status_glyph(status, url, log)
      return em_status_white if in_white_list(url, nil, log)

      case
      when status == 200
        return '✅ '
      when status.to_s.start_with?('3')
        return em_status_yellow
      when status.to_s.start_with?('4')
        return em_status_red
      else
        return em_status_white
      end
    end
  end # class
end
