require 'csv'

class CSVParser
  attr_reader :csv_file

  def initialize(csv_file)
    @csv_file = csv_file
  end

  def parsed
    CSV.parse(text, headers: true)
  end
  
  private 

    def text
      File.read(csv_file)
    end
end
