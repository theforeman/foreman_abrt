class CreateAbrtReports < ActiveRecord::Migration
  def change
    create_table :abrt_reports do |t|
      t.references :host, :null => false
      t.text :json
      t.string :reason
      t.integer :count
      t.string :duphash
      t.timestamp :reported_at

      t.timestamp :forwarded_at
      t.string :response_message
      t.boolean :response_known
      t.string :response_bthash

      t.timestamps
    end

    create_table :abrt_report_response_destinations do |t|
      t.references :abrt_report, :null => false
      t.string :reporter
      t.string :desttype
      t.string :value
    end

    create_table :abrt_report_response_solutions do |t|
      t.references :abrt_report, :null => false
      t.string :cause
      t.text :note
      t.string :url
    end
  end
end
