require_relative 'upload_activities'

# Upload all unit activity Falle for 2016
PATH_TO_DIR = "#{Rails.root}/db/seeds/"
path_to_file = "#{PATH_TO_DIR}/UAR_2014_June.xlsx"
UnitActivityReport.new(path_to_file).upload_uar
