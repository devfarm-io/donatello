# frozen_string_literal: true

require "rails"
module Donatello
  # Railtie for incorporating into a rails app
  class Railtie < Rails::Railtie
    initializer "donatello.configure" do |_app|
      Donatello.setup
    end
  end
end
