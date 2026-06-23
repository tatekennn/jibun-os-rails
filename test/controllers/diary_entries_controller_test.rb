require "test_helper"

class DiaryEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as_owner
    @diary_entry = diary_entries(:one)
  end

  test "should get index" do
    get diary_entries_url
    assert_response :success
  end

  test "should get new" do
    get new_diary_entry_url
    assert_response :success
  end

  test "should create diary_entry" do
    assert_difference("DiaryEntry.count") do
      post diary_entries_url, params: { diary_entry: { wrote_on: "2026-06-23", title: "火曜メモ", mood: "tired", weather: "雨", body: "少し疲れたので早めに休む。", tags: "休息" } }
    end

    assert_redirected_to diary_entries_url
  end

  test "should show diary_entry" do
    get diary_entry_url(@diary_entry)
    assert_response :success
  end

  test "should get edit" do
    get edit_diary_entry_url(@diary_entry)
    assert_response :success
  end

  test "should update diary_entry" do
    patch diary_entry_url(@diary_entry), params: { diary_entry: { title: "更新メモ", body: @diary_entry.body, wrote_on: @diary_entry.wrote_on, mood: @diary_entry.mood, weather: @diary_entry.weather, tags: @diary_entry.tags } }

    assert_redirected_to diary_entries_url
    @diary_entry.reload
    assert_equal "更新メモ", @diary_entry.title
  end

  test "should destroy diary_entry" do
    assert_difference("DiaryEntry.count", -1) do
      delete diary_entry_url(@diary_entry)
    end

    assert_redirected_to diary_entries_url
  end
end
