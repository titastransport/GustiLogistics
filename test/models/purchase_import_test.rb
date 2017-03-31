require 'test_helper'

describe PurchaseImport, '.save' do

  describe 'when given a valid file' do

    before do 
      file = File.new(Rails.root.join('test/fixtures/files/ISTC_March_2017_basic_text.xlsx'))
      @purchase_import = PurchaseImport.new(file: file)
    end

    after do
      CustomerPurchaseOrder.delete_all 
    end

    it "creates new purchases" do
      assert_difference 'CustomerPurchaseOrder.count', 3 do
        @purchase_import.save 
      end
    end

    it 'updates purchases that already exist' do
      @purchase_import.save 
  
      assert_no_difference 'CustomerPurchaseOrder.count' do
        @purchase_import.save 
      end
    end
  end
end
