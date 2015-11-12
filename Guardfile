directories %w(lib)

guard :rubocop do
  watch(/.+\.rb$/)  
  watch(%r{(?:.+/)?\.rubocop\.yml$}) { |m| File.dirname(m[0]) }
end
