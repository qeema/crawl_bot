require 'rubygems'
require 'active_record'
require 'yaml'

config = YAML.load_file('./database.yml')


ActiveRecord::Base.establish_connection(
  config["db"]["development"]
)

class Museum < ActiveRecord::Base
  has_many :sphabits
end

class Sphabit < ActiveRecord::Base
  belongs_to :museum
end

museum = Museum.where(:id => 1)
sphabit = Sphabit.new
sphabit.name = "tesn"
sphabit.museum_id = museum
sphabit.save
p sphabit.museum

=begin
p sphabit.museum.name
=end

=begin
museum = Museum.new(:name => "test")
museum.save

p Museum.all
=end


