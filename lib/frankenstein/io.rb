# I/O
module Frankenstein

  KEY_LOG = 'log'
  KEY_VISIT = 'visit'

  class << self
    require 'json'
    require 'time'

    def io_record_visits(repo, redirects, file)
      visit = {
        type: KEY_VISIT,
        date: Time.now.utc.iso8601,
        redirects: redirects.count,
        file: file
      }
      logs = [visit]

      if File.exist? FILE_VISITS
        r = io_json_read FILE_VISITS
        if r.has_key? repo
          hash = r[repo]
          list = hash[KEY_LOG]
          list.push visit
        else
          r[repo] = {KEY_LOG => logs}
        end

        io_json_write FILE_VISITS, r
      else
        hash = { repo => { KEY_LOG => logs} }

        io_json_write FILE_VISITS, hash
      end
      # puts 'visit recorded ✅'
    end

    def io_repo_log_json(list, log)
      log.add "\nWriting repo log ... "
      json = if File.exist?(FILE_REPO)
               saved = io_json_read FILE_REPO

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
      io_json_write FILE_REPO, json
    end

    def io_json_read(filename)
      c = File.read(filename)
      c ? JSON.parse(c) : nil
    end

    def io_json_write(filename, content)
      json = content.to_json
      File.open(filename, 'w') { |f| f.puts(json) }
    end
  end
end
