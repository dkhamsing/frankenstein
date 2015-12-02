# Output
module Frankenstein
  class << self
    def elapsed(elapsed_seconds)
      case
      when elapsed_seconds > 60
        minutes = (elapsed_seconds / 60).floor
        seconds = elapsed_seconds - minutes * 60
        m = "#{pluralize2 minutes.round(0), 'minute'}"
        m << "#{seconds > 0 ? seconds.round(0).to_s << 's' : ''}"
      else
        "#{pluralize2 elapsed_seconds.round(2), 'second'}"
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

    def pluralize2(count, text)
      "#{count} #{text}#{count > 1 ? 's' : ''}"
    end

    def in_white_list2(w, input, cli_wl, log)       
      white_list = cli_wl ? w.dup.push(cli_wl.split('^')).flatten : w
      white_list.each do |regexp|
        if input.match(regexp)
          log.verbose "#{input} is in white list matching #{regexp}".white
          return true
        end
      end
      false
    end

    def output_issues(issues, links_to_check, log)
      if issues.count > 0
        percent = issues.count * 100 / links_to_check.count
        m = "#{pluralize2 issues.count, 'issue'} (#{percent.round}%)"
        log.error_header m

        m = "   (#{issues.count} of #{pluralize2 links_to_check.count, 'link'}"
        log.add m

        log.add issues
      else
        m = "\n#{PRODUCT.white} #{'found no errors'.green} for "\
            "#{pluralize2 links_to_check.count, 'link'} #{em_sunglasses}"
        log.add m
      end
    end

    def output_misc(misc, log)
      log.add "\n #{pluralize2 misc.count, 'misc item'}".white
    end

    def output_status(flag_minimize_output, status, link, log)
      if flag_minimize_output
        log.my_print status_glyph status, link, log
      else
        m = status_glyph(status, link, log)
        m << ' '
        m << "#{status} " unless
          (status == 200) || (status == WHITE_LIST_STATUS)
        m << link
        log.add m
      end
    end

    def status_glyph(status, url, log)
      return em_status_white if in_white_list2 WHITE_LIST_REGEXP, url, nil, log

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
