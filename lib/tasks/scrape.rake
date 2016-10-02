# webスクレイピングコマンドファイル
# taskに各博物館・美術館を定義してコマンドを実行する
# ex. bundle exec rake scrape:foo
# Templateクラスを継承して、execメソッドで実行するように実装を行うこと
# TODO urlとかをconfに持たせる
# TODO tmn追加

require 'open-uri'
require 'nokogiri'
require 'kconv'
require 'date'

# 環境指定 config.ymlの読み込みに使用
#env    = 'production'
env    = 'development'
config = YAML.load_file('lib/tasks/config.yml')

# コマンド定義
namespace :scrape do

  # テンプレート 各コマンドはこのclassを使用すること
  class Template
    def initialize(url:, current_dir:, museum_id:)
      @url            = url         # スクレイピング対象url
      @current_dir    = current_dir # 相対パス用カレントディレクトリ
      @text_arr       = Array.new   # 特別展名
      @url_arr        = Array.new   # 特別展url
      @start_date_arr = Array.new   # 特別展開始日
      @end_date_arr   = Array.new   # 特別展終了日
      @arr_count      = 0           # text_arr・url_arr・start_date_arr・end_date_arrのカウント数
      @museum         = String.new  # 対象博物館名

      set_museum_info(museum_id)      # 挿入用museumデータ取得
    end

    # 実行関数 請勿override
    def exec
      doc = make_url_xml      # url解析xml化
      set_target_list(doc)    # text,start,end設定
      set_values_count_correct?(@text_arr, @url_arr, @start_date_arr, @end_date_arr) # 取得データの整合性チェック
      @start_date_arr = change_string_to_datetime(@start_date_arr)         # datetime型に修正
      @end_date_arr   = change_string_to_datetime(@end_date_arr)           # datetime型に修正
      del_existed_spexhabit   # DBに存在するデータは削除
      is_update_db?           # クラス変数に値が設定されているか確認
      insert_db               # DB挿入
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
    def set_values_count_correct?(text_arr, url_arr, start_date_arr, end_date_arr)
      unless text_arr.count === start_date_arr.count && text_arr.count === url_arr.count && text_arr.count === end_date_arr.count
        logger_output("method : set_values_count_correct? \n message : text_arr,start_date_arr,end_date_arr count数不一致")
        exit()
      else
        @arr_count = text_arr.count
        return true
      end
    end

    # idから対象のmuseum情報を設定
    def set_museum_info(museum_id)
      @museum = Museum.find(museum_id)
    end

    # DBのdatetime型に合わせる
    def change_string_to_datetime(date_arr)
      date_time_arr = date_arr.map do |value|
        # ['year', 'month', 'day']に変換
        value_ymd = value.split(',')
        DateTime.new(value_ymd[0].to_i, value_ymd[1].to_i, value_ymd[2].to_i)
      end
    end

    # DBに存在するデータを配列から削除
    def del_existed_spexhabit
      @arr_count.times do |i|
        start_date = @start_date_arr[i] + Rational(9, 24)
        end_date   = @end_date_arr[i]   + Rational(9, 24)
        if Spexhabit.find_by(name: @text_arr[i], start_date: start_date, end_date: end_date)
          @text_arr[i]       = nil
          @start_date_arr[i] = nil
          @end_date_arr[i]   = nil
        end
      end
      @text_arr.compact!
      @start_date_arr.compact!
      @end_date_arr.compact!
      self.set_values_count_correct?(@text_arr,  @url_arr, @start_date_arr, @end_date_arr)
    end

    # クラス変数の値が入っているかを確認する
    def is_update_db?
      unless @text_arr.count && @start_date_arr.count && @end_date_arr.count
        logger_output("method : is_update_db \n message : text_arr,start_date_arr,end_date_arr count数不一致")
        exit()
      end

      if @text_arr == [] && @start_date_arr == [] && @end_date_arr == []
        logger_output("method : is_update_db \n message : all nil. insert必要なし")
        exit()
      end
    end

    # DB挿入実行
    def insert_db
      if @arr_count.times do |i|
          spexhabit            = Spexhabit.new
          spexhabit.name       = @text_arr[i]
          spexhabit.url        = @url
          spexhabit.start_date = @start_date_arr[i]
          spexhabit.end_date   = @end_date_arr[i]
          spexhabit.del_flg    = 0
          spexhabit.status     = 0
          spexhabit.museum     = @museum
          spexhabit.save
          logger_output("method : insert_db \n message : insert完了 #{spexhabit.name}")
        end
      else
        logger_output("method : insert_db \n message : insert失敗！！！")
      end
    end

    # logger出力
    def logger_output(msg)
      logger = Logger.new('log/development.log')
      logger.info("========= #{msg}  ==========")
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
      url:         config[env]['nmwa']['url'],
      current_dir: config[env]['nmwa']['current_dir'],
      museum_id:   config[env]['nmwa']['museum_id']
    )
    scrape.exec
  end

  # 東京国立博物館情報取得
  desc 'get 東京国立博物館'
  task :tnm => :environment do
    p "test"
  end
end
