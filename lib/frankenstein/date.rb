# Dates
module Frankenstein
  class << self
    def number_of_days_since(date)
      days = difference date
      months = days / 30

      m = 'last updated '

      case
      when days == 0
        m << 'today'
      when days < 100
        m << "#{days} #{pluralize 'day', days} ago"
      else
        m << "#{months} #{pluralize 'month', months} ago"
      end

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
      difference = -((date - time)/60/60/24)
      difference.round(0)
    end
  end # class
end
