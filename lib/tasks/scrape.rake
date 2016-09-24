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
      @start_date_arr = Array.new  # 開始日
      @end_date_arr   = Array.new  # 終了日
      @arr_count      = 0          # text_arr・start_date_arr・end_date_arrの数
      @input_date_arr = Array.new  # 挿入データ用配列
    end

    # 実行関数 請勿override
    def exec
      doc = make_url_xml
      set_target_list(doc)
      is_values_count_correct?(@text_arr, @start_date_arr, @end_date_arr)
      insert_db
    end

    # nokogiriでurlを解析してxmlにする(nokogiri XML<HTML)
    def make_url_xml
      html = open(@url, "r:binary").read
      doc  = Nokogiri::HTML(html.toutf8, nil, 'utf-8')
      return doc
    end

    # targetのtagリスト設定,特別展名と終了開始日を含んだリスト 要override
    def set_target_list(doc)
      @text_arr = set_text_arr(list)
      @date_arr = set_date_arr(list)
    end

    # text=特別展名の取得  要override
    def set_text_arr(list)
      get_tag_css(list,tag)
    end

    # 終了開始日の取得  要override
    def set_date_arr(list)
      get_tag_css(list,tag)
      @start_date_arr = start_date_arr
      @end_date_arr = end_date_arr
    end

    # nokogiriで解析したxml nodeからcssで選択して値を取得
    def get_tag_css(list, tag:)
      return list.css(tag)
    end

    # 特別展名・開始日・終了日が正しく取得できていることを確認する
    def is_values_count_correct?(text_arr, start_date_arr, end_date_arr)
      unless text_arr.count === start_date_arr.count && text_arr.count === end_date_arr.count
        logger_output("text_arr,start_date_arr,end_date_arr count数不一致")
        exit()
      else
        @arr_count = text_arr.count
      end
    end

    # dbに挿入
    def insert_db
      p @text_arr
      p @start_date_arr
      p @end_date_arr
      p @arr_count
    end

    def logger_output(msg)
      logger = Logger.new('log/development.log')
      logger.info("========= #{msg} エラー ==========")
    end
  end

  desc 'get 国立西洋美術館'
  task :nmwa => :environment do
    class Nmwa < Template
      def set_target_list(doc)
        list = doc.css('ul.futureexhibitionlist')
        set_text_arr(list)
        set_date_arr(list)
      end

      def set_text_arr(list)
        a_tag = get_tag_css(list, tag: 'a')
        a_tag.each do |a|
          @text_arr.push(a.inner_text)
        end
      end

      def set_date_arr(list)
        # [開始日～終了日]という値で入る
        span_tag = get_tag_css(list, tag: 'span')
        regexp = /(\d+)\年(\d+)\月(\d+)\日/
        i = 0
        span_tag.each do |span|
          span.inner_text.scan(regexp).each do |date|
            # 偶数は開始日、奇数は終了日
            if i.even?
              @start_date_arr.push(date.join(','))
            else
              @end_date_arr.push(date.join(','))
            end
            i += 1
          end
        end
      end
    end

    scrape = Nmwa.new(url: 'http://192.168.1.124/nmwa/upcoming.html')
    scrape.exec
  end
end
