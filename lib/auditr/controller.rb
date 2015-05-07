module Auditr
  module Controller

    def self.included(base)
      base.before_filter :set_auditr_current_user
    end

    protected

    # Returns the user who is responsible for any changes that occur.
    # By default this calls `current_user` and returns the result.
    #
    # Override this method in your controller to call a different
    # method, e.g. `current_person`, or anything you like.
    def user_for_auditr
      current_user rescue nil
    end

    # Returns any information about the controller or request that you
    # want Auditr to store alongside any changes that occur.  By
    # default this returns an empty hash.
    #
    # Override this method in your controller to return a hash of any
    # information you need.  The hash's keys must correspond to columns
    # in your `versions` table, so don't forget to add any new columns
    # you need.
    #
    # For example:
    #
    #     {:ip => request.remote_ip, :user_agent => request.user_agent}
    #
    # The columns `ip` and `user_agent` must exist in your `versions` # table.
    #
    # Use the `:meta` option to `Auditr::Model::ClassMethods.has_audit`
    # to store any extra model-level data you need.
    def info_for_auditr
      {}
    end

    # Returns `true` (default) or `false` depending on whether Auditr should
    # be active for the current request.
    #
    # Override this method in your controller to specify when Auditr should
    # be off.
    def auditr_enabled_for_controller
      true
    end

    private

    def audit_params
      params.require(:audit_entry).permit(:item_type, :item_id, :event, :entry, :user, :object, :changes, :severity)
    end

    # Tells Auditr whether versions should be saved in the current request.
    def set_auditr_enabled_for_controller
      ::Auditr.enabled_for_controller = auditr_enabled_for_controller
    end

    def set_auditr_current_user
      ::Auditr.current_user = user_for_auditr if auditr_enabled_for_controller
    end

    # Tells Auditr any information from the controller you want
    # to store alongside any changes that occur.
    def set_auditr_controller_info
      ::Auditr.controller_info = info_for_auditr if auditr_enabled_for_controller
    end

  end
end
