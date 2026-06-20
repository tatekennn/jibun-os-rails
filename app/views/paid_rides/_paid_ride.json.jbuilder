json.extract! paid_ride, :id, :used_on, :line_name, :direction, :fare, :reason, :fatigue_level, :memo, :created_at, :updated_at
json.url paid_ride_url(paid_ride, format: :json)
