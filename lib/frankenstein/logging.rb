require 'frankenstein/constants'
require 'frankenstein/emoji'

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

    def in_white_list(input, cli_wl, log)
      # verbose "cli wl: #{cli_wl}"
      white_list = cli_wl ? WHITE_LIST_REGEXP.dup.push(cli_wl.split('^')).flatten : WHITE_LIST_REGEXP
      # verbose "white list: #{white_list}"
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

    def repo_log_json(list, log)
      log.add "\nWriting repo log ... "
      json = if File.exist?(FILE_REPO)
               file = File.read(FILE_REPO)
               saved = JSON.parse(file)

               list.each do |x|
                 h = saved.map { |s| s if s['repo'] == x[:repo] }.compact.first
                 unless h.nil? || x[:count].nil?
                   difference = x[:count] - h['count']
                   m = "#{x[:repo]} count difference: #{difference} #{em_star}"
                   log.add m unless difference == 0
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
  end # class
end
