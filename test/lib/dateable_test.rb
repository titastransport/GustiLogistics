require 'test_helper'
include Dateable

describe Dateable, 'days_till' do
   
  it 'calculate days till for this year' do
    date = Date.today + 10.days

    days_till(date).must_equal 10
  end
  
  it "calculates days till for next year" do
    date = Date.today + 1.year + 5.days
    
    days_till(date).must_equal 370
  end
end 

describe Dateable, 'months_back' do
  it "finds the date n months back" do
    month_back(2).must_equal(Date.today.beginning_of_month - 2.months) 
    month_back(13).must_equal(Date.today.beginning_of_month - 13.months)
  end
end
