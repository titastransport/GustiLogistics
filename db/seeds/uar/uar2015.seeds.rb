require_relative '../seed_helper'
require_relative 'upload_activities'

# Upload all unit activity Faella for 2016
PATH_TO_DIR = "#{Rails.root}/db/seeds/unit_activity_reports/unitactivityreportfaella2015/"
Dir.foreach(PATH_TO_DIR) do |file|
  next if is_hidden?(file)
  path_to_file = "#{PATH_TO_DIR}/#{file}"
  UnitActivityReport.new(path_to_file).upload_uar
end
