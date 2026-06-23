json.extract! diary_entry, :id, :wrote_on, :title, :mood, :weather, :body, :tags, :created_at, :updated_at
json.url diary_entry_url(diary_entry, format: :json)
