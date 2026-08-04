require "rails_helper"

RSpec.describe PageSnapshot do
  subject(:page_snapshot) { build(:page_snapshot) }

  it { is_expected.to be_valid }

  describe "associations" do
    it { is_expected.to belong_to(:audit) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:kind).with_values(home: "home", accessibility: "accessibility").backed_by_column_of_type(:string) }
  end
end
