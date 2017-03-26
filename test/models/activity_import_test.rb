require 'test_helper'

describe ActivityImport, '.save' do

  describe 'when given a valid file' do

    before do 
      file = File.new(Rails.root.join('test/fixtures/files/UAR_March_2017_basic_test.xlsx'))
      @activity_import = ActivityImport.new(file: file)
    end

    after do
      Activity.delete_all 
    end

    it "creates new activities" do
        num_activities_before = Activity.count 

        @activity_import.save 
        num_activities_after = Activity.count
        
        num_activities_after.must_be :>, num_activities_before
    end

    it 'updates activities that already exist' do
      @activity_import.save 
      num_activities_after_first_save = Activity.count 

      @activity_import.save 
      num_activities_after_second_save = Activity.count

      num_activities_after_first_save.must_be :==, num_activities_after_second_save
    end
  end

  describe "when given an invalid file" do

    it "rejects activities when a product doesn't exist" do
      file = File.new(Rails.root.join('test/fixtures/files/UAR_March_2017_nonexistent_product.xlsx'))
      @activity_import = ActivityImport.new(file: file)

      num_activities_before = Activity.count 

      @activity_import.save 
      num_activities_after = Activity.count


      num_activities_after.must_be :==, num_activities_before
    end
  end
end
