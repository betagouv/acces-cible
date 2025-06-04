require 'rails_helper'

RSpec.describe Tag do
  subject(:tag) { build(:tag) }

  it { should be_valid }

  describe "associations" do
    it { should belong_to(:team) }
    it { should have_many(:site_tags).dependent(:destroy) }
    it { should have_many(:sites).through(:site_tags) }
  end
end
