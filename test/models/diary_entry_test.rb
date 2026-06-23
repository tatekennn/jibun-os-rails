require "test_helper"

class DiaryEntryTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert diary_entries(:one).valid?
  end

  test "requires body and wrote_on" do
    diary_entry = DiaryEntry.new(mood: "normal")

    assert_not diary_entry.valid?
    assert_includes diary_entry.errors[:wrote_on], "can't be blank"
    assert_includes diary_entry.errors[:body], "can't be blank"
  end

  test "requires supported mood" do
    diary_entry = DiaryEntry.new(wrote_on: Date.current, body: "test", mood: "unknown")

    assert_not diary_entry.valid?
    assert_includes diary_entry.errors[:mood], "is not included in the list"
  end
end
