class Museum < ActiveRecord::Base
  belongs_to :pref
  self.inheritance_column = :_type_disabled
end
