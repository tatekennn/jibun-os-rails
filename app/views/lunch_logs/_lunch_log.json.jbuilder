json.extract! lunch_log, :id, :visited_on, :shop_name, :area, :price, :rating, :crowdedness, :solo_friendly, :repeat, :memo, :created_at, :updated_at
json.url lunch_log_url(lunch_log, format: :json)
