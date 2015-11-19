# Dates
module Frankenstein
  class << self
    def number_of_days_since(date)
      days = difference date
      months = days / 30

      m = text_from(days, months)

      case
      when days < 10
        return m.green
      when days < 30
        return m.blue
      when days < 60
        return m
      else
        return m.red
      end
    end

    def difference(date)
      time = Time.new
      return 0 if date.nil?

      difference = -((date - time) / 60 / 60 / 24)
      difference.round(0)
    end

    def text_from(days, months)
      m = 'last updated '
      case
      when days == 0
        m << 'today'
      when days < 100
        m << "#{pluralize2 days, 'day'} ago"
      else
        m << "#{pluralize2 months, 'month'} ago"
      end

      m
    end
  end # class
end
