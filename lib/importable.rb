module Importable
  def open_spreadsheet
    Roo::Spreadsheet.open(file)
  end
    # Filename method currently used for both Action Dispatch object for file
    # upload and rake db:seed tasks
  def filename
    file.is_a?(String) ? File.basename(file) : File.basename(file.original_filename, '.xlsx')
  end

  def check_for_valid_file
    if params[:activity_import].nil?
      redirect_to new_activity_import_path, alert: "File missing for upload."
    elsif file_extname != ".xlsx"
      redirect_to new_activity_import_path,\
        alert: "Incorrect file type. Please upload a .xlsx file"
    end
  end

  def display_errors(invalid_purchases)
    invalid_purchases.each_with_index do |purchase, index|
      purchase.errors.full_messages.each do |message|
        self.errors.add :base, "Row #{index + 2}: #{message}"
      end
    end
  end
end
