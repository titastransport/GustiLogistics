require "test_helper"

feature "CanUpdateProduct" do
  
  before do
    feature_log_in
    @product = products(:pianogrillo)
    visit edit_product_path(@product) 
  end

  scenario "Gustiamo successfully updates product" do
    fill_in 'Current', with: 10000
    fill_in 'Cover time', with: 100
    click_button 'Update Product'

    page.must_have_content 'Product was successfully updated.'
    page.must_have_content 'Current: 10000' 
  end

  scenario "Gustiamo sells all products so current reorder date is displayed as today!" do
    fill_in 'Current', with: 0
    click_button 'Update Product'

    page.must_have_content 'Product was successfully updated.'
    page.must_have_content 'Reorder By: Today!' 
  end
end
