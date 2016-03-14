file = 'mds'
c = File.read file

list = c.split "\n"
m = list.map { |y| y.sub './', 'https://raw.githubusercontent.com/fastlane/fastlane/master/' }

m.each do |x|
  puts x
end

file = 'mds_raw'
File.delete(file) if File.exist? file

m.each do |z|
  File.open(file, 'a') { |file| file.puts( z ) if z.include? '.md' }
end
puts "Wrote #{file}"
