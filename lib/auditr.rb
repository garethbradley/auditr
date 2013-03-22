require "auditr/version"
require "auditr/controller"
require "auditr/has_audit"

module Auditr

  # Returns `true` if Auditr is enabled for the request, `false` otherwise.
  #
  # See `Auditr::Controller#auditr_enabled_for_controller`.
  def self.enabled_for_controller?
    !!auditr_store[:request_enabled_for_controller]
  end

  # Sets whether Auditr is enabled or disabled for the current request.
  def self.enabled_for_controller=(value)
    auditr_store[:request_enabled_for_controller] = value
  end

  # Returns who is reponsible for any changes that occur.
  def self.current_user
    auditr_store[:current_user]
  end

  # Sets who is responsible for any changes that occur.
  # You would normally use this in a migration or on the console,
  # when working with models directly.  In a controller it is set
  # automatically to the `current_user`.
  def self.current_user=(value)
    auditr_store[:current_user] = value
  end

  # Returns any information from the controller that you want
  # Auditr to store.
  #
  # See `Auditr::Controller#info_for_auditr`.
  def self.controller_info
    auditr_store[:controller_info]
  end

  # Sets any information from the controller that you want Auditr
  # to store.  By default this is set automatically by a before filter.
  def self.controller_info=(value)
    auditr_store[:controller_info] = value
  end

  private

  # Thread-safe hash to hold Auditr's data.
  # Initializing with needed default values.
  def self.auditr_store
    Thread.current[:auditr] ||= {
      :request_enabled_for_controller => true
    }
  end

end

ActiveSupport.on_load(:active_record) do
  include Auditr::Model
end

ActiveSupport.on_load(:action_controller) do
  include Auditr::Controller
end
