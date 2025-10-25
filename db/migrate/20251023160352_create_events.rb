class CreateEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :events do |t|
      t.string :event_id, null: false, index: { unique: true }
      t.string :event_type, null: false
      t.jsonb :payload, default: {}
      t.string :source
      t.datetime :occurred_at, null: false
      t.datetime :processed_at

      t.timestamps
    end

    add_index :events, :event_type
    add_index :events, :occurred_at
    add_index :events, :processed_at
  end
end
