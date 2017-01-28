Dir.foreach('unitactivityreportfaella2016') do |file|
  next if file.start_with? '.'
  puts "#{File.path(file)}"
end
