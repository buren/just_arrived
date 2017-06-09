# frozen_string_literal: true

class CreateFrilansFinansApiLogs < ActiveRecord::Migration[4.2]
  def change
    create_table :frilans_finans_api_logs do |t|
      t.integer :status
      t.string :status_name
      t.string :verb
      t.text :params
      t.text :response_body
      t.string :uri, limit: 2083

      t.timestamps null: false
    end
  end
end
