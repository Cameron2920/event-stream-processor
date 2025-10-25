class CreateEventMetrics < ActiveRecord::Migration[7.2]
  def change
    create_table :event_metrics do |t|
      t.timestamps
    end
  end
end
