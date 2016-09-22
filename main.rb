require 'rubygems'
require 'active_record'
require 'yaml'

config = YAML.load_file('./database.yml')


ActiveRecord::Base.establish_connection(
  config["db"]["development"]
)

class Museum < ActiveRecord::Base
end

museum = Museum.new(:name => "test")
museum.save

p Museum.all



