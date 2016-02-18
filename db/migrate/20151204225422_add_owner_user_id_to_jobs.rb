# frozen_string_literal: true
class AddOwnerUserIdToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :owner_user_id, :integer
  end
end
