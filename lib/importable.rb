require 'roo'

module Importable
  def open_spreadsheet
    Roo::Spreadsheet.open(file)
  end

  def file_extname
    File.extname(import_params[:file].original_filename)
  end

  # Filename method currently used for both Action Dispatch object for file
    # upload and rake db:seed tasks
  def filename
    File.basename(file) || File.basename(file.original_filename, '.xlsx')
  end

  def check_valid_file_present
    import_controller = params[:controller].singularize.to_sym
    
    if params[import_controller].nil?
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
