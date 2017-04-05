require 'test_helper'

describe ProductImport, '#save' do

  describe 'when given valid products' do
    before do
      new_products = Rails.root.join('test/fixtures/files/product_import_new_test.csv') 

      @before_products_count = Product.count
      @imported_products = ProductImport.new(new_products).save
    end

    after do
      @imported_products.each(&:delete)
    end

    it 'imports new products' do
      Product.count.must_be :==, (@before_products_count + @imported_products.count)
    end

    describe 'when products already exist' do
      
      before do
        update_products = Rails.root.join('test/fixtures/files/product_import_update_test.csv') 
        @hazen_desc_before = Product.find_by(gusti_id: "ACE00150").description
        ProductImport.new(update_products).save
        @hazan_desc_after = Product.find_by(gusti_id: "ACE00150").description
      end

      it 'updates existing products' do
        @hazan_desc_after.wont_equal @hazen_desc_before
        @hazan_desc_after.must_equal 'Hazan!' 
      end
    end
  end 

  describe 'when given invalid products' do
    before do
      @before_products_count = Product.count
      @original_stdout = $stdout
      $stdout = StringIO.new

      invalid_products = Rails.root.join('test/fixtures/files/product_import_invalid_test.csv')
      ProductImport.new(invalid_products).save
      @after_products_count = Product.count
    end

    after do
      $stdout = @original_stdout
    end

    it 'rejects product' do
      @after_products_count.must_equal @before_products_count
    end
  end
end
