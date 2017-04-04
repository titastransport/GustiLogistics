require "test_helper"

feature "CanUploadPurchases" do
  
  before do
    feature_log_in
    visit "/purchase_imports/new"
  end

  scenario "Gustiamo uploads an Items Sold to Customer" do
    file = Rails.root.join('test/fixtures/files/ISTC_March_2017_basic_text.xlsx')
    find('#purchase_import_file').set(file)
    click_button "Import"

    page.must_have_content 'Imported Items Sold to Customers Report successfully.'
  end

  scenario "Gustiamo attemps to upload no file" do
    click_button "Import"
    
    page.must_have_content 'File missing for upload'
  end

  scenario "Gustiamo attempts to upload a non-Excel file" do
    file = Rails.root.join('app/models/product.rb')
    find('#purchase_import_file').set(file)

    click_button "Import"
    
    page.must_have_content 'Incorrect file type. Please upload a .xlsx file'
  end

  scenario "Gustiamo attempts to upload a valid file with an improper name" do
    file = Rails.root.join('test/fixtures/files/improper_file_name.xlsx')
    find('#purchase_import_file').set(file)

    click_button "Import"
    
    page.must_have_content 'Please save file in the following format: Type_Month_Year.xlsx, i.e., UAR_July_2015.xlsx'
  end

  scenario "Gustiamo attempts to upload a file with a non-existent product" do
    file = Rails.root.join('test/fixtures/files/ISTC_March_2017_nonexistent_product_test.xlsx')
    find('#purchase_import_file').set(file)

    click_button "Import"
    
    page.must_have_content "errors prohibited this import"
  end
end
