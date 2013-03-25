class CreateAuditEntries < ActiveRecord::Migration
  def self.up
    create_table :audit_entries do |t|
      t.string   :item_type, :null => false
      t.integer  :item_id,   :null => false
      t.string   :event,     :null => false
      t.string   :entry
      t.string   :user
      t.string   :severity
      t.text     :object
      t.text     :object_changes
      t.datetime :created_at
    end
    add_index :audit_entries, [:item_type, :item_id]
  end

  def self.down
    remove_index :audit_entries, [:item_type, :item_id]
    drop_table :audit_entries
  end
end
