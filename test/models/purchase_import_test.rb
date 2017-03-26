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
        num_purchases_before = CustomerPurchaseOrder.count 

        @purchase_import.save 
        num_purchases_after = CustomerPurchaseOrder.count
        
        num_purchases_after.must_be :>, num_purchases_before
    end

    it 'updates purchases that already exist' do
      @purchase_import.save 
      num_purchases_after_first_save = CustomerPurchaseOrder.count 

      @purchase_import.save 
      num_purchases_after_second_save = CustomerPurchaseOrder.count

      num_purchases_after_first_save.must_be :==, num_purchases_after_second_save
    end
  end

  describe "when given a an invalid file" do

    it "rejects purchases when a product doesn't exist" do
      file = File.new(Rails.root.join('test/fixtures/files/ISTC_March_2017_nonexistent_product.xlsx'))
      @purchase_import = PurchaseImport.new(file: file)

      num_purchases_before = CustomerPurchaseOrder.count 

      @purchase_import.save 
      num_purchases_after = CustomerPurchaseOrder.count

      num_purchases_after.must_be :==, num_purchases_before
    end

  end

end
