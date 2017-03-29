require 'roo'
include Dateable

module Importable

  # Before action
  def check_valid_file_present
    import_controller = params[:controller].singularize.to_sym
    
    if params[import_controller].nil?
      redirect_to "/#{params[:controller]}", alert: "File missing for upload."
    elsif file_extname != ".xlsx"
      redirect_to "/#{params[:controller]}", alert: "Incorrect file type. Please upload a .xlsx file"
    end
  end

  def check_valid_filename
    begin
      date_from_file_name(import_params[:file].original_filename) 
    rescue 
      redirect_to "/#{params[:controller]}", alert: "Please save file in the following format: Type_Month_Year.xlsx, i.e., UAR_July_2015.xlsx"
    end
  end

  def file_extname
    File.extname(import_params[:file].original_filename)
  end

  # Filename method currently used for both Action Dispatch object for file
  # upload and rake db:seed tasks, and test
  # Ok checking for string since String and File are core Ruby class and most likely
  # won't change too much
  def filename
    case file
    when String, File
      File.basename(file) 
    else
      File.basename(file.original_filename, '.xlsx')
    end
  end

  def open_spreadsheet
    Roo::Spreadsheet.open(file)
  end

  def display_errors(invalid_records)
    invalid_records.each_with_index do |record, index|
      record.errors.full_messages.each do |message|
        self.errors.add :base, "Row #{index + 2}: #{message}"
      end
    end
  end

  def import_month
    @import_month ||= date_from_file_name(filename)
  end
end
