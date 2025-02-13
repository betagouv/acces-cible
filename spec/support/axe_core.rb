# frozen_string_literal: true

# Override the default matcher to add a `description`
# Otherwise, Rspec spits a lengthy warning for every test
RSpec::Matchers.define :be_accessible do
  match do |page|
    expect(page).to be_axe_clean.according_to(:wcag21aa)
  end

  description do
    "be accessible according to aXe standards"
  end
end
