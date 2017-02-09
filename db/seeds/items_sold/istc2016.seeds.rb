require_relative '../seed_helper'
require_relative 'upload_itsc'

PATH_TO_DIR = "#{Rails.root}/db/seeds/items_sold/purchases_2016/"
Dir.foreach(PATH_TO_DIR) do |file|
  next if is_hidden?(file)
  path_to_file = "#{PATH_TO_DIR}/#{file}"
  ItemsSoldToCustomers.new(path_to_file).upload_itsc
end
