module Importable
  def open_spreadsheet
    Roo::Spreadsheet.open(file)
  end
    # Filename method currently used for both Action Dispatch object for file
    # upload and rake db:seed tasks
  def filename
    file.is_a?(String) ? File.basename(file) : File.basename(file.original_filename, '.xlsx')
  end

  def display_errors(invalid_purchases)
    invalid_purchases.each_with_index do |purchase, index|
      purchase.errors.full_messages.each do |message|
        self.errors.add :base, "Row #{index + 2}: #{message}"
      end
    end
  end
end
