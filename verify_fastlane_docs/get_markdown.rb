def get(dir)
  dir += '/' unless dir.include? '/'
  glob = Dir.glob "#{dir}**/*"
  glob.select { |x| x.downcase.include? 'md' }
end

list = get '.'
puts list

file = 'mds'
File.delete(file) if File.exist? file
list.each do |x|
  File.open('mds', 'a') { |file| file.puts( x ) }
end
puts "Wrote #{file}"
