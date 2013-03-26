module Auditr
  module Model

    def self.included(base)
      base.send :extend, ClassMethods
    end


    module ClassMethods
      # Declare this in your model to track every create, update, and destroy.  Each version of
      # the model is available in the `audit_entries` association.
      #
      # Options:
      # :on            the events to track (optional; defaults to all of them).  Set to an array of
      #                `:create`, `:update`, `:destroy` as desired.
      # :class_name    the name of a custom AuditEntry class.  This class should inherit from AuditEntry.
      # :ignore        an array of attributes for which a new `Version` will not be created if only they change.
      # :if, :unless   Procs that allow to specify conditions when to save versions for an object
      # :only          inverse of `ignore` - a new `Version` will be created only for these attributes if supplied
      # :skip          fields to ignore completely.  As with `ignore`, updates to these fields will not create
      #                a new `Version`.  In addition, these fields will not be included in the serialized versions
      #                of the object whenever a new `Version` is created.
      # :meta          a hash of extra data to store.  You must add a column to the `versions` table for each key.
      #                Values are objects or procs (which are called with `self`, i.e. the model with the paper
      #                trail).  See `PaperTrail::Controller.info_for_paper_trail` for how to store data from
      #                the controller.
      # :audit_entries the name to use for the versions association.  Default is `:audit_entries`.

      def has_audit(options = {})
        # Lazily include the instance methods so we don't clutter up
        # any more ActiveRecord models than we have to.
        send :include, InstanceMethods

        class_attribute :audit_entry_class_name
        self.audit_entry_class_name = options[:class_name] || '::AuditEntry'

        class_attribute :auditr_options
        self.auditr_options = options.dup

        [:ignore, :skip, :only].each do |k|
          auditr_options[k] =
            ([auditr_options[k]].flatten.compact || []).map &:to_s
        end

        auditr_options[:meta] ||= {}


        class_attribute :auditr_enabled_for_model
        self.auditr_enabled_for_model = true

        class_attribute :audit_entries_association_name
        self.audit_entries_association_name = options[:audit_entries] || :audit_entries

        has_many self.audit_entries_association_name,
                 :class_name => audit_entry_class_name,
                 :as         => :item,
                 :order      => "created_at ASC"

        after_create  :record_create, :if => :save_entry? if !options[:on] || options[:on].include?(:create)
        before_update :record_update, :if => :save_entry? if !options[:on] || options[:on].include?(:update)
        after_destroy :record_destroy, :if => :save_entry? if !options[:on] || options[:on].include?(:destroy)

      end

    end

    # Wrap the following methods in a module so we can include them only in the
    # ActiveRecord models that declare `has_paper_trail`.
    module InstanceMethods

      def create_audit_entry(severity, event, options = {})
        data = {
          :event     => event ||= 'other',
          :entry     => options.has_key?(:entry) ? options[:entry] : nil,
          :severity  => severity ||= 'info',
          :user      => Auditr.current_user
        }

        send(self.class.audit_entries_association_name).create merge_metadata(data)
      end

      def child_audit_entries
        # this would return a hash of all `belongs_to` reflections, in this case:
        # { :foo => (the Foo Reflection), :bar => (the Bar Reflection) }
        associations = self.reflections.select{|s,r| [:has_many, :has_one].include? r.macro}
        child_audit_entries = self.audit_entries.scoped

        associations.each do |association|
          begin
        #    child_audit_entries << send(association.last.plural_name).audit_entries
            send(association.last.plural_name).each do |child_record|
              child_audit_entries |= child_record.audit_entries.scoped
            end
          rescue
          end
        end

        return child_audit_entries
        #child_audit_entries.sort{|ae1,ae2| ae1.id <=> ae2.id}
      end

      def self_and_child_audit_entries
        #self_and_child_audit_entries = audit_entries
        #self_and_child_audit_entries << child_audit_entries

        #self_and_child_audit_entries.sort{|ae1,ae2| ae1.id <=> ae2.id}
        child_audit_entries
      end

      private

      def audit_entry_class
        audit_entry_class_name.constantize
      end

      def record_create
        if switched_on?
          data = {
            :event     => 'create',
            :entry     => 'Record created',
            :severity  => 'info',
            :user      => Auditr.current_user
          }

          send(self.class.audit_entries_association_name).create merge_metadata(data)
        end
      end

      def record_update
        if switched_on?
          data = {
            :event     => 'update',
            :entry     => 'Record updated',
            :severity  => 'info',
#           :object    => object_to_string(item_before_change),
#           :object_changes   => Auditr.serializer.dump(changes_for_paper_trail)
            :user      => Auditr.current_user
          }

          send(self.class.audit_entries_association_name).build merge_metadata(data)
        end
      end

      def record_destroy
        if switched_on? and not new_record?
          audit_entry_class.create merge_metadata(:item_id   => self.id,
                                              :item_type => self.class.base_class.name,
                                              :event     => 'destroy',
                                              :entry     => 'Record destroyed',
                                              :severity  => 'warning',
#                                              :object    => object_to_string(item_before_change),
                                              :user      => Auditr.current_user)
        end

        send(self.class.audit_entries_association_name).send :load_target
      end     

      def merge_metadata(data)
        # First we merge the model-level metadata in `meta`.
        auditr_options[:meta].each do |k,v|
          data[k] =
            if v.respond_to?(:call)
              v.call(self)
            elsif v.is_a?(Symbol) && respond_to?(v)
              # if it is an attribute that is changing, be sure to grab the current version
              if has_attribute?(v) && send("#{v}_changed?".to_sym)
                send("#{v}_was".to_sym)
              else
                send(v)
              end
            else
              v
            end
        end
        # Second we merge any extra data from the controller (if available).
        data.merge(Auditr.controller_info || {})
      end

      def switched_on?
        Auditr.enabled? && Auditr.enabled_for_controller? && self.class.auditr_enabled_for_model
      end

      def save_entry?
        if_condition     = self.class.auditr_options[:if]
        unless_condition = self.class.auditr_options[:unless]
        (if_condition.blank? || if_condition.call(self)) && !unless_condition.try(:call, self)
      end


    end

  end
end
