today = Date.current

WorkDay.find_or_create_by!(date: today) do |work_day|
  work_day.memo = "発表準備の日。打刻だけは忘れない。"
end

5.times do |index|
  date = today - index - 1
  WorkDay.find_or_create_by!(date: date) do |work_day|
    work_day.check_in_confirmed = true
    work_day.check_out_confirmed = index.even?
    work_day.check_in_confirmed_at = date.in_time_zone.change(hour: 9, min: 21)
    work_day.check_out_confirmed_at = date.in_time_zone.change(hour: 18, min: 48) if index.even?
    work_day.memo = index.even? ? "通常運転。" : "退勤確認が怪しい日。"
  end
end

[
  [today, "京王ライナー", "新宿方面", 410, "疲れていた", 4, "座って帰る判断。"],
  [today - 5, "京王ライナー", "南大沢方面", 410, "雨", 3, "雨の日は体力優先。"],
  [today - 10, "京王ライナー", "新宿方面", 410, "帰りが遅かった", 5, "かなり助かった。"],
  [today - 16, "京王ライナー", "南大沢方面", 410, "寝たかった", 4, ""]
].each do |used_on, line_name, direction, fare, reason, fatigue_level, memo|
  PaidRide.find_or_create_by!(used_on:, line_name:, direction:, fare:) do |ride|
    ride.reason = reason
    ride.fatigue_level = fatigue_level
    ride.memo = memo
  end
end

[
  [today, "兆楽", "道玄坂", 900, 4, "普通", true, true, "迷ったらここ。回転が早い。"],
  [today - 1, "カリーカイラス", "渋谷", 950, 5, "普通", true, true, "午後が少し元気になる。"],
  [today - 3, "魚力", "神山町", 1200, 5, "混んでる", false, true, "魚の日として強い。"],
  [today - 6, "喜楽", "道玄坂", 1000, 4, "混んでる", false, true, "たまに行きたい。"],
  [today - 8, "小さな定食屋", "会社近く", 850, 3, "空いてる", true, false, "静かに食べられる。"]
].each do |visited_on, shop_name, area, price, rating, crowdedness, solo_friendly, repeat, memo|
  LunchLog.find_or_create_by!(visited_on:, shop_name:) do |log|
    log.area = area
    log.price = price
    log.rating = rating
    log.crowdedness = crowdedness
    log.solo_friendly = solo_friendly
    log.repeat = repeat
    log.memo = memo
  end
end

[
  ["ライブ", "ライブ", "event", today + 5, "大阪", 9800, "", "移動込みで体力配分する。", nil, "planned"],
  ["家DJでJuice=Juice曲をつなぐ案", "DJ", "memo", nil, "", 0, "", "BPM近い曲を3曲つないで、途中で少し跳ねる感じにする。", 4, "planned"],
  ["LTネタ: 自分専用PWA", "技術", "memo", nil, "", 0, "", "誰にも刺さらないけど自分には刺さる、を軸に話す。", 5, "planned"],
  ["読書メモ: 小さい道具の良さ", "読書", "memo", today - 2, "", 0, "", "毎日使うものは派手さより入口の近さが大事。", 4, "done"]
].each do |title, category, item_type, scheduled_on, location, cost, url, body, rating, status|
  HobbyItem.find_or_create_by!(title:) do |item|
    item.category = category
    item.item_type = item_type
    item.scheduled_on = scheduled_on
    item.location = location
    item.cost = cost
    item.url = url
    item.body = body
    item.rating = rating
    item.status = status
  end
end
