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

      def logger_output
        logger = Logger.new('log/development.log')
        logger.info('task morning が起動されました。')
      end

    end

    def hello
      p "hello"
    end
  end

  desc 'get 国立西洋美術館'
  task :nmwa => :environment do
    test = Template.new(url: 'http://192.168.1.124/nmwa/upcoming.html')
    test.get_url

    i = 0

    html = open(url, "r:binary").read
    doc = Nokogiri::HTML(html.toutf8, nil, 'utf-8')
    # tagで抽出
    list = doc.css('ul.futureexhibitionlist')
    a_tag = list.css('a')
    span_tag = list.css('span')
    #p a_tag
    #p span_tag

  end
end
