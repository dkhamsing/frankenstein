# Dates
module Frankenstein
  class << self
    def number_of_days_since(date)
      days = difference date
      "last updated #{days} #{pluralize 'day', days} ago"
    end

    def difference(date)
      time = Time.new
      difference = -((date - time)/60/60/24)
      difference.round(0)
    end
  end # class
end
