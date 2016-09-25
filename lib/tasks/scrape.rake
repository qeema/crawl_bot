# ex. bundle exec rake scrape:foo

require 'open-uri'
require 'nokogiri'
require 'kconv'
require 'date'

namespace :scrape do

  # テンプレート 各コマンドはこのclassを使用すること
  class Template
    def initialize(url:, current_dir:, museum_id:)
      @url            = url         # scrape用url
      @current_dir    = current_dir # 相対パス用カレントディレクトリ
      @text_arr       = Array.new   # 特別展名
      @start_date_arr = Array.new   # 開始日
      @end_date_arr   = Array.new   # 終了日
      @url_arr        = Array.new   # 特別展url
      @arr_count      = 0           # text_arr・start_date_arr・end_date_arrの数
      @museum         = String.new  # 対象博物館名
      @input_date_arr = Array.new   # 挿入データ用配列

      select_museum(museum_id)
    end

    # 実行関数 請勿override
    def exec
      doc = make_url_xml
      set_target_list(doc)
      is_values_count_correct?(@text_arr, @url_arr, @start_date_arr, @end_date_arr)
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
      @url_arr  = set_url_arr(list)
      @date_arr = set_date_arr(list)
    end

    # text=特別展名の取得  要override
    def set_text_arr(list)
      get_tag_css(list,tag)
    end

    # url=特別展urlの取得  要override
    def set_url_arr(list)
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
    def is_values_count_correct?(text_arr, url_arr, start_date_arr, end_date_arr)
      unless text_arr.count === start_date_arr.count && text_arr.count === url_arr.count && text_arr.count === end_date_arr.count
        logger_output("text_arr,url_arr,start_date_arr,end_date_arr count数不一致")
        exit()
      else
        @arr_count = text_arr.count
      end
    end

    def is_value_exists?(text, sp_start, sp_end)
      if Spexhabit.find_by(name: text, start_date: sp_start, end_date: sp_end)
        return true
      else
        return false
      end
    end

    # idから対象の博物館名を取得
    def select_museum(museum_id)
      @museum = Museum.find(museum_id)
    end

    # dbに挿入
    def insert_db
      @arr_count.times do |i|
        spexhabit         = Spexhabit.new
        spexhabit.museum  = @museum
        spexhabit.name    = @text_arr[i]
        spexhabit.url     = @url_arr[i]
        spexhabit.del_flg = false

        # 開始日・終了日を年月日に分割してDBに挿入する型にする
        # ["2016,10,15"] → ["year","month","day"]
        splited_date         = @start_date_arr[i].split(',')
        spexhabit.start_date = DateTime.new(splited_date[0].to_i, splited_date[1].to_i, splited_date[2].to_i)
        splited_date         = @end_date_arr[i].split(',')
        spexhabit.end_date   = DateTime.new(splited_date[0].to_i, splited_date[1].to_i, splited_date[2].to_i)

        # 重複データがない場合はdbにデータ挿入
        unless is_value_exists?(spexhabit.name, spexhabit.start_date, spexhabit.end_date)
          if spexhabit.save
            logger_output('下記ステータスにてinsert正常終了')
            logger_output(spexhabit.inspect)
          else
            logger_output('insert_dbでエラー')
          end
        end
      end
    end

    def logger_output(msg)
      logger = Logger.new('log/development.log')
      logger.info("========= #{msg} ==========")
    end
  end

  # 国立西洋美術館情報取得用コマンド
  desc 'get 国立西洋美術館'
  task :nmwa => :environment do
    class Nmwa < Template
      def set_target_list(doc)
        list = doc.css('ul.futureexhibitionlist')
        set_text_arr(list)
        set_url_arr(list)
        set_date_arr(list)
      end

      def set_text_arr(list)
        a_tag = get_tag_css(list, tag: 'a')
        a_tag.each do |a|
          @text_arr.push(a.inner_text)
        end
      end

      def set_url_arr(list)
        a_tag = get_tag_css(list, tag: 'a')
        #.match(/\//).nil?
        a_tag.each do |a|
          value = a.attribute('href').value
          # 相対パスの場合はカレントディレクトを追加
          if value.match(/\//).nil?
            @url_arr.push(@current_dir + value)
          else
            @url_arr.push(value)
          end
        end
      end

      def set_date_arr(list)
        # [開始日～終了日]という値で入る
        span_tag = get_tag_css(list, tag: 'span')
        regexp = /(\d+)\年(\d+)\月(\d+)\日/
        span_tag.each do |span|
          span.inner_text.scan(regexp).each_with_index do |value, key|
            # 偶数は開始日、奇数は終了日
            if key.even?
              @start_date_arr.push(value.join(','))
            else
              @end_date_arr.push(value.join(','))
            end
          end
        end
      end
    end

    # 処理実行
    scrape = Nmwa.new(
      url:         'http://www.nmwa.go.jp/jp/exhibitions/upcoming.html',
      current_dir: 'http://www.nmwa.go.jp/jp/exhibitions/',
      museum_id:   1
    )
    scrape.exec
  end
end
