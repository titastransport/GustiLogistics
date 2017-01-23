json.array!(@products) do |product|
  json.extract! product, :id, :item_id, :description, :current, :reorder_in
  json.url product_url(product, format: :json)
end
