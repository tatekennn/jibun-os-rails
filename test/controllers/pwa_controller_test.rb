require "test_helper"

class PwaControllerTest < ActionDispatch::IntegrationTest
  test "should get service worker" do
    get pwa_service_worker_url
    assert_response :success
    assert_includes @response.body, "showNotification"
  end

  test "should get manifest" do
    get pwa_manifest_url
    assert_response :success
    assert_includes @response.media_type, "manifest+json"
  end

  test "should get offline" do
    get offline_url
    assert_response :success
  end
end
