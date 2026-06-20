class PwaController < ApplicationController
  skip_before_action :require_login

  def service_worker
    response.headers["Service-Worker-Allowed"] = "/"
    render template: "pwa/service-worker", formats: [:js], layout: false, content_type: "application/javascript"
  end

  def manifest
    render template: "pwa/manifest", formats: [:json], layout: false, content_type: "application/manifest+json"
  end

  def offline
  end
end
