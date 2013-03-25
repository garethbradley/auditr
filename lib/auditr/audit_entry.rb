class AuditEntry < ActiveRecord::Base
  belongs_to :item, :polymorphic => true

  validates_presence_of :event, :severity
  attr_accessible :item_type, :item_id, :event, :entry, :user, :object, :changes, :severity

  def self.with_item_keys(item_type, item_id)
    where :item_type => item_type, :item_id => item_id
  end

  def self.creates
    where :event => 'create'
  end

  def self.updates
    where :event => 'update'
  end

  def self.destroys
    where :event => 'destroy'
  end
end
