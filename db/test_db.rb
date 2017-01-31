MATCH_MONTH = /(?<=_)\w+(?=_)/ 
months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September',
          'October', 'November', 'December']

Dir.foreach('unitactivityreportfaella2016') do |file|
  next if file.start_with? '.'
  file_name = File.basename(file)
  file_month = file_name.match(MATCH_MONTH).to_s 
  puts file_month
end
