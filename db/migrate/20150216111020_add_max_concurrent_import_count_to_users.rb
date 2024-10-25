Sequel.migration do
  up do
    add_column :users, :max_concurrent_import_count, :integer, null: false, default: 5
  end
  down do
    drop_column :users, :max_concurrent_import_count
  end
end
