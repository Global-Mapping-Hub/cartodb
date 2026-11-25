Sequel.migration do
  # Long public sync URLs (including query strings) were stored in
  # character varying(255) and truncated. data_imports.service_item_id is
  # already text.
  up do
    run 'ALTER TABLE synchronizations ALTER COLUMN service_item_id TYPE text'
  end

  down do
    run 'ALTER TABLE synchronizations ALTER COLUMN service_item_id TYPE character varying(255)'
  end
end
