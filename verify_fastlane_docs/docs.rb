`git clone https://github.com/fastlane/fastlane.git --depth=1`
`cd fastlane/`

puts 'get markdown...'
`ruby get_markdown.rb`

puts 'generate links...'
`ruby make_raw.rb`
