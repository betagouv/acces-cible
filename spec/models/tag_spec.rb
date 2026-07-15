require "rails_helper"

RSpec.describe Tag do
  subject(:tag) { build(:tag) }

  it { is_expected.to be_valid }

  describe "associations" do
    it { is_expected.to belong_to(:team) }
    it { is_expected.to have_many(:site_tags).dependent(:destroy) }
    it { is_expected.to have_many(:sites).through(:site_tags) }
  end
end
