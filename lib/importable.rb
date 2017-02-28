module Importable
  def open_spreadsheet
    Roo::Spreadsheet.open(file)
  end
    # Filename method currently used for both Action Dispatch object for file
    # upload and rake db:seed tasks
  def filename
      file.is_a?(String) ? File.basename(file) : file.original_filename
  end
end
