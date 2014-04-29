class CreateAbrtReports < ActiveRecord::Migration
  def change
    create_table :abrt_reports do |t|
      t.references :host, :null => false
      t.text :json
      t.string :reason
      t.integer :count
      t.string :duphash
      t.timestamp :reported_at

      t.timestamps
    end
  end
end
