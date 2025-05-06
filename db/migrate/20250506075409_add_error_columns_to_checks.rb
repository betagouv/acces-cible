class AddErrorColumnsToChecks < ActiveRecord::Migration[8.0]
  def up
    change_table :checks, bulk: true do |t|
      t.string :error_type
      t.text   :error_message
      t.string :error_backtrace, array: true, default: []
    end

    say_with_time "Move Check error data to dedicated columns" do
      execute <<~SQL.squish
        UPDATE checks
        SET
          error_type = data->>'error_type',
          error_message = data->>'error',
          error_backtrace = CASE
            WHEN jsonb_typeof(data->'backtrace') = 'array'
            THEN ARRAY(SELECT jsonb_array_elements_text(data->'backtrace'))
            ELSE NULL
          END
        WHERE data ? 'error_type';
      SQL
      execute <<~SQL.squish
        UPDATE checks
        SET data = data - 'error_type' - 'error' - 'backtrace'
        WHERE data ? 'error_type' OR data ? 'error' OR data ? 'backtrace';
      SQL
    end
  end

  def down
    say_with_time "Move Check error data back into data column" do
      execute <<~SQL.squish
        UPDATE checks
        SET data = jsonb_build_object(
          'error_type', error_type,
          'error', error_message,
          'backtrace', to_jsonb(error_backtrace)
        )
        WHERE error_type IS NOT NULL;
      SQL
    end

    change_table :checks, bulk: true do |t|
      t.remove :error_type
      t.remove :error_message
      t.remove :error_backtrace
    end
  end
end
