json.extract! hobby_item, :id, :title, :category, :item_type, :scheduled_on, :location, :cost, :url, :body, :rating, :status, :created_at, :updated_at
json.url hobby_item_url(hobby_item, format: :json)
