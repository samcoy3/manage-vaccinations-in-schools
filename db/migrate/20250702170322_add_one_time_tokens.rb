# frozen_string_literal: true

class AddOneTimeTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :one_time_tokens, id: false do |t|
      t.references :user, foreign_key: true, null: false
      t.string :token, null: false, primary_key: true
      t.jsonb :cis2_info, :jsonb, null: true
      t.timestamps

      t.index :token, unique: true
      t.index :created_at
    end
    # we have to  remove the default index added by 'references'
    # and explicitly add our own, to make it unique
    remove_index :one_time_tokens, :user_id
    add_index :one_time_tokens, :user_id, unique: true
  end
end
