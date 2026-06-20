require "application_system_test_case"

class HobbyItemsTest < ApplicationSystemTestCase
  setup do
    @hobby_item = hobby_items(:one)
  end

  test "visiting the index" do
    visit hobby_items_url
    assert_selector "h1", text: "Hobby items"
  end

  test "should create hobby item" do
    visit hobby_items_url
    click_on "New hobby item"

    fill_in "Body", with: @hobby_item.body
    fill_in "Category", with: @hobby_item.category
    fill_in "Cost", with: @hobby_item.cost
    fill_in "Item type", with: @hobby_item.item_type
    fill_in "Location", with: @hobby_item.location
    fill_in "Rating", with: @hobby_item.rating
    fill_in "Scheduled on", with: @hobby_item.scheduled_on
    fill_in "Status", with: @hobby_item.status
    fill_in "Title", with: @hobby_item.title
    fill_in "Url", with: @hobby_item.url
    click_on "Create Hobby item"

    assert_text "Hobby item was successfully created"
    click_on "Back"
  end

  test "should update Hobby item" do
    visit hobby_item_url(@hobby_item)
    click_on "Edit this hobby item", match: :first

    fill_in "Body", with: @hobby_item.body
    fill_in "Category", with: @hobby_item.category
    fill_in "Cost", with: @hobby_item.cost
    fill_in "Item type", with: @hobby_item.item_type
    fill_in "Location", with: @hobby_item.location
    fill_in "Rating", with: @hobby_item.rating
    fill_in "Scheduled on", with: @hobby_item.scheduled_on
    fill_in "Status", with: @hobby_item.status
    fill_in "Title", with: @hobby_item.title
    fill_in "Url", with: @hobby_item.url
    click_on "Update Hobby item"

    assert_text "Hobby item was successfully updated"
    click_on "Back"
  end

  test "should destroy Hobby item" do
    visit hobby_item_url(@hobby_item)
    click_on "Destroy this hobby item", match: :first

    assert_text "Hobby item was successfully destroyed"
  end
end
