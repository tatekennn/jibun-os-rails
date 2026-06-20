module ApplicationHelper
  def yen(value)
    number_to_currency(value || 0, unit: "円", precision: 0, format: "%n%u")
  end

  def short_date(date)
    return "-" unless date

    date.strftime("%-m/%-d")
  end

  def status_chip(confirmed)
    confirmed ? "OK" : "未確認"
  end

  def active_nav_class(controller_name)
    current_page = params[:controller]
    current_page == controller_name ? "bottom-nav__item bottom-nav__item--active" : "bottom-nav__item"
  end

  def active_nav_aria(controller_name)
    params[:controller] == controller_name ? { current: "page" } : {}
  end

  def rating_stars(value)
    "★" * value.to_i
  end
end
