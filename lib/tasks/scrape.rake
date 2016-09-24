# ex. bundle exec rake scrape:nmwa

require 'open-uri'
require 'nokogiri'
require 'kconv'
require 'date'

namespace :scrape do

  class Template
    def initialize(url:)
      @url            = url        # scrape用url
      @text_arr       = Array.new  # 特別展名
      @date_arr       = Array.new  # 日時配列（[foo~bar]の形で曜日が入っている場合）
      @start_date_arr = Array.new  # 開始日
      @end_date_arr   = Array.new  # 終了日付
      @input_date_arr = Array.new  # 挿入データ用配列
    end

    def exec
      doc = make_url_xml
      set_values(doc)
      insert_db
    end

=begin
    # 各サイトに応じてオーバーライドして実行
    # クラス変数にスクレイピング結果を設定する
    def set_text_arr(text_arr)
      @text_arr = text_arr
    end
    def set_date_arr(date_arr)
      @date_arr = date_arr
    end
    def set_start_date_arr(start_date_arr)
      @start_date_arr = start_date_arr
    end
    def set_end_date_arr(end_date_arr)
      @end_date_arr = end_date_arr
    end
=end

    def set_values(doc)
      @input_date_arr.push(@text_arr)
      @input_date_arr.push(@start_date_arr)
      @input_date_arr.push(@end_date_arr)
    end

    def make_url_xml
      html = open(@url, "r:binary").read
      doc  = Nokogiri::HTML(html.toutf8, nil, 'utf-8')
      return doc
    end

    def insert_db
    end

    def logger_output(task)
      logger = Logger.new('log/development.log')
      logger.info("#{task} が起動されました。")
    end
  end

  desc 'get 国立西洋美術館'
  task :nmwa => :environment do
    scrape = Template.new(url: 'http://192.168.1.124/nmwa/upcoming.html')
    scrape.exec


=begin
    i = 0
    html = open(url, "r:binary").read
    doc = Nokogiri::HTML(html.toutf8, nil, 'utf-8')
    # tagで抽出
    list = doc.css('ul.futureexhibitionlist')
    a_tag = list.css('a')
    span_tag = list.css('span')
    #p a_tag
    #p span_tag
=end
  end
end
