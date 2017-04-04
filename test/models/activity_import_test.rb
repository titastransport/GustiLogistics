require 'test_helper'

describe ActivityImport, '.save' do

  describe 'when given a valid file' do

    before do 
      file = File.new(Rails.root.join('test/fixtures/files/UAR_March_2017_basic_test.xlsx'))
      @activity_import_new = ActivityImport.new(file: file)
    end

    after do
      Activity.delete_all 
    end

    it "creates new activities for existing product" do
      assert_difference 'Activity.count', 2 do
        @activity_import_new.save 
      end
    end

    describe "when activities already exist" do

      before do
        file = File.new(Rails.root.join('test/fixtures/files/UAR_March_2017_update_test.xlsx'))
        @activity_import_update = ActivityImport.new(file: file)
      end

      it "doesn't create new activities" do
        @activity_import_new.save 

        assert_no_difference 'Activity.count' do 
          @activity_import_update.save 
        end
      end

      it "updates activities that already exist for a given month and product" do
        assert_difference 'Activity.first.sold', 100 do 
          @activity_import_update.save 
        end
      end
    end
  end

  describe "when given an invalid file" do

    before do
      file = File.new(Rails.root.join('test/fixtures/files/UAR_March_2017_nonexistent_product.xlsx'))
      @activity_import = ActivityImport.new(file: file)
    end

    it "rejects activities when a product doesn't exist" do
      assert_no_difference 'Activity.count' do 
        @activity_import.save 
      end
    end
  end
end
