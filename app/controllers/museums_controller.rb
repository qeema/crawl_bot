class MuseumsController < ApplicationController
  @museum = Museum.all
  p @museum
end
