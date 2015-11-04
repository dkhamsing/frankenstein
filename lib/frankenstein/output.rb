# Output
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
