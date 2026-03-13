# frozen_string_literal: true

After do
  clear_enqueued_jobs
end

Quand("les tâches de fond sont terminées") do
  perform_enqueued_jobs
end

# ce step sert à délencher et épuiser toutes les tâches qu'une tâche
# elle-même peut programmer, ex : ProcessAuditJob déclenche plusieurs
# RunCheckJobs.
Quand("toutes les tâches de fond sont terminées") do
  while queue_adapter.enqueued_jobs.any?
    step("les tâches de fond sont terminées")
  end
end
