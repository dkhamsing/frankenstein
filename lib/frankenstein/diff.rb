# String diffs
module Frankenstein
  require 'differ'
  require 'differ/string'

  # Diff change
  class Differ::Diff
    def changes
      @raw.reject { |e| e.is_a? String }
    end
  end

end
