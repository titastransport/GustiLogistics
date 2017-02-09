require_relative 'seed_helper'
require_relative 'upload_activities'

path_to_file = "./uar_test_anelli.xlsx"
UnitActivityReport.new(path_to_file).upload_uar
