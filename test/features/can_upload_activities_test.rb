require "test_helper"

feature "CanUploadActivities" do
  
  before do
    feature_log_in
    visit "/activity_imports/new"
  end

  scenario "Gustiamo uploads a Unit Activity Report" do
    file = Rails.root.join('test/fixtures/files/UAR_March_2017_basic_test.xlsx')
    find('#activity_import_file').set(file)
    click_button "Import"

    page.must_have_content 'Imported Unit Activity Report successfully.'
  end

  scenario "Gustiamo attempts to upload no file" do
    click_button "Import"
    
    page.must_have_content 'File missing for upload'
  end

  scenario "Gustiamo attempts to upload a non-Excel file" do
    file = Rails.root.join('app/models/product.rb')
    find('#activity_import_file').set(file)

    click_button "Import"
    
    page.must_have_content 'Incorrect file type. Please upload a .xlsx file'
  end

  scenario "Gustiamo attempts to upload a valid file with an improper name" do
    file = Rails.root.join('test/fixtures/files/improper_file_name.xlsx')
    find('#activity_import_file').set(file)

    click_button "Import"
    
    page.must_have_content 'Please save file in the following format: Type_Month_Year.xlsx, i.e., UAR_July_2015.xlsx'
  end
end
