require 'test_helper'

include Dateable

describe Product, 'gusti_id' do 

  before do 
    @product = products(:faella_spaghetti) 
  end

  it 'should be unique' do
    duplicate_product = @product.dup
    duplicate_product.gusti_id.downcase!

    duplicate_product.wont_be :valid?
  end
end

describe Product, '#setup?' do 

  before do 
    @product = products(:faella_spaghetti) 
  end

  it 'detects if a product is setup with a next reorder date' do
    @product.must_be :setup?

    @product.next_reorder_date = nil
    
    @product.wont_be :setup?
  end
end

describe Product, '.existing_gusti_id?' do 

  before do 
    @product = products(:faella_spaghetti) 
  end

  it 'determines if a product exists by gusti id' do
    Product.existing_gusti_id?(@product.gusti_id).must_equal true
    Product.existing_gusti_id?('gustigusti').wont_equal true
  end
end

describe Product, '#actual_next_reorder_date' do

  before do
    @product = products(:faella_spaghetti)
    @product2 = products(:pianogrillo)
  end

  it "calculates reorder dates and accounts for different years" do
    @product.actual_next_reorder_date.year.must_equal (Date.today + 1.year).year
  end

  it "calculates next reorder date for before block interval" do
    normal_wait_months = (@product2.lead_time + @product2.travel_time).months

    @product2.actual_next_reorder_date.must_equal @product2.cant_travel_start - normal_wait_months - 1.day
  end

  it "calculates next reorder date for product that just went out of inventory" do
    @product2.current = 0

    @product2.actual_next_reorder_date.must_equal Date.today 
  end
end

describe Product, '#gap_days' do

  before do
    @product = products(:pianogrillo)
  end

  it 'finds dif for reorder after date in blocking interval and next possible reorder date' do
    @product.gap_days(@product.naive_reorder_after_next_yday).must_equal 47
  end
end
