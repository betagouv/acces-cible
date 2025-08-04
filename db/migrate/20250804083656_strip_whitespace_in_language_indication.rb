class StripWhitespaceInLanguageIndication < ActiveRecord::Migration[8.0]
  def up
    say_with_time "Strip whitespace in language indication" do
      Checks::LanguageIndication
        .where("data->>'indication' IS NOT NULL AND data->>'indication' != trim((data->>'indication'))")
        .update_all("data = jsonb_set(data, '{indication}', to_jsonb(trim((data->>'indication'))))")
    end
  end
end
