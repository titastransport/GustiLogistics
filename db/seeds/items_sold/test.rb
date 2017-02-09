require_relative '../seed_helper'
require_relative 'upload_itsc'

PATH_TO_DIR = "purchases_2015/"
Dir.foreach(PATH_TO_DIR) do |file|
  next if is_hidden?(file)
  path_to_file = "#{PATH_TO_DIR}/#{file}"
  ItemsSoldToCustomers.new(path_to_file).upload_itsc
end
