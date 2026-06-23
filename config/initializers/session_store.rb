# Keep the owner login usable as a daily PWA.
#
# Without an explicit expiry, Rails sends a browser-session cookie. Mobile Safari
# and installed PWAs often discard those after the app/browser has been idle,
# which makes the app ask for the password again. Give the encrypted session
# cookie a long-lived expiry while keeping the explicit logout path available.
Rails.application.config.session_store :cookie_store,
  key: "_jibun_os_session",
  expire_after: 1.year,
  same_site: :lax,
  secure: Rails.env.production?
