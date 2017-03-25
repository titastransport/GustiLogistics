require 'test_helper'
require 'roo'

include Dateable
include ActionDispatch::TestProcess::FixtureFile

describe 'Purchase Import Model' do

  describe 'when given a valid file' do

    before do 
      file = File.new(Rails.root.join('test/fixtures/files/ISTC_March_2017_basic_text.xlsx'))
      @purchase_import = PurchaseImport.new(file: file)
    end

    it 'creates new valid purchases' do
      num_purchases_before = CustomerPurchaseOrder.count 
      @purchase_import.save 
      num_purchases_after = CustomerPurchaseOrder.count
      assert_operator num_purchases_after, :>, num_purchases_before
    end
  end

end
