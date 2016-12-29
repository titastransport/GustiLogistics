require_relative 'index' 

inv = Roo::Spreadsheet.open('inventory_2012.xlsx')

inventory = {
  ids: [],
  descriptions: [], 
  curs: [],
  reorder_by: []
}

populate(inv, inventory)
seed(inventory)


# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
