require "test_helper"

class HobbyItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @hobby_item = hobby_items(:one)
  end

  test "should get index" do
    get hobby_items_url
    assert_response :success
  end

  test "should get new" do
    get new_hobby_item_url
    assert_response :success
  end

  test "should create hobby_item" do
    assert_difference("HobbyItem.count") do
      post hobby_items_url, params: { hobby_item: { body: @hobby_item.body, category: @hobby_item.category, cost: @hobby_item.cost, item_type: @hobby_item.item_type, location: @hobby_item.location, rating: @hobby_item.rating, scheduled_on: @hobby_item.scheduled_on, status: @hobby_item.status, title: @hobby_item.title, url: @hobby_item.url } }
    end

    assert_redirected_to hobby_items_url
  end

  test "should show hobby_item" do
    get hobby_item_url(@hobby_item)
    assert_response :success
  end

  test "should get edit" do
    get edit_hobby_item_url(@hobby_item)
    assert_response :success
  end

  test "should update hobby_item" do
    patch hobby_item_url(@hobby_item), params: { hobby_item: { body: @hobby_item.body, category: @hobby_item.category, cost: @hobby_item.cost, item_type: @hobby_item.item_type, location: @hobby_item.location, rating: @hobby_item.rating, scheduled_on: @hobby_item.scheduled_on, status: @hobby_item.status, title: @hobby_item.title, url: @hobby_item.url } }
    assert_redirected_to hobby_items_url
  end

  test "should destroy hobby_item" do
    assert_difference("HobbyItem.count", -1) do
      delete hobby_item_url(@hobby_item)
    end

    assert_redirected_to hobby_items_url
  end
end
