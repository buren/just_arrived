# frozen_string_literal: true
class CreateCompanies < ActiveRecord::Migration
  def change
    create_table :companies do |t|
      t.string :name
      t.string :cin

      t.timestamps null: false
    end
  end
end
