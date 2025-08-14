FactoryBot.define do
  factory :check do
    audit { association :audit }

    Check.types.each do |type, klass|
      trait(type) do
        initialize_with { klass.new(attributes) }
      end
    end

    # we could try and emulate the complete logic of going through the
    # chain of states (pending -> ready -> running, etc) but it would
    # require a lot of heavy machinery since Checks have requirements
    # + runtime logic (like running browser things). Instead, insert
    # the last transition as STATE and run with it: it might be
    # exactly the right kind of dumb we want for testing.
    CheckStateMachine.states.each do |state|
      trait(state) do
        after(:create) do |check, _eval|
          CheckTransition.create!(
            to_state: state,
            check: check,
            most_recent: true,
            sort_key: 0
          )
        end
      end
    end
  end
end
