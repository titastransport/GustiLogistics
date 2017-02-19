module ApplicationHelper
  def full_title(page_title = '')
    base_title = "GustiLogistics"
    if page_title.empty?
      base_title
    else
      page_title + " | " + base_title
    end
  end

  def flash_id(message_type)
    case message_type
    when "alert alert-info"     then :notice
    when "alert alert-success"  then :success
    when "alert alert-error"    then :alert
    when "alert alert-alert"    then :alert
    end
  end
end

module ImportsHelper
  def open_spreadsheet
    Roo::Spreadsheet.open(file.path)
  end

  def filename
    File.basename(file.original_filename, File.extname(file.original_filename))
  end

  def display_errors(invalid_purchases)
    purchases.each_with_index do |purchase, index|
      purchase.errors.full_messages.each do |message|
        self.errors.add :base, "Row #{index + 2}: #{message}"
      end
    end
  end
end
