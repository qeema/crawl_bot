require 'nokogiri'
require 'open-uri'
require 'kconv'
require 'date'

url = 'http://192.168.1.124/nmwa/upcoming.html'
#url = 'http://www.nmwa.go.jp/jp/exhibitions/upcoming.html'
#url = 'http://192.168.11.124/tohaku/rss.html'

html = open(url, "r:binary").read
doc = Nokogiri::HTML(html.toutf8, nil, 'utf-8')

# tagで抽出
list = doc.css('ul.futureexhibitionlist')
a_tag = list.css('a')
span_tag = list.css('span')

# 展示名・開催年月日
text_arr = Array.new
date_arr = Array.new
a_tag.each do |a|
  text_arr.push(a.inner_text)
end

i = 0

# 開始年月日と終了年月日を配列で取得
# [[["2016", "10", "15"], ["2017", "1", "15"]]
start_date_arr = Array.new
end_date_arr = Array.new
regexp = /(\d+)\年(\d+)\月(\d+)\日/
span_tag.each do |span|
  span.inner_text.scan(regexp).each do |date|
    if i.even?
      start_date_arr.push(date.join(','))
    else
      end_date_arr.push(date.join(','))
    end
    i += 1
  end
end



if text_arr.count && start_date_arr.count && end_date_arr.count
  text_arr.count.times do |i|
    p text_arr
    p start_date_arr
    p end_date_arr

# TODO datetime入れてdbに挿入すること
  end
else
  p '========== 不一致、エラー =========='
  p list
end

p start_date_arr[0]
p date = start_date_arr[0].split(',')
puts DateTime.new(date[0].to_i, date[1].to_i, date[2].to_i)


