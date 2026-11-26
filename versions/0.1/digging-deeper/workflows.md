---
title: Workflows
description: State machines and workflows with guards, events and diagrams.
---
# Workflows

Inspired by the Symfony Workflow component.

```yaml
# config/workflows.yml
article_publishing:
  type: state_machine            # or "workflow" (several places at once, stored as JSON)
  marking_property: status
  initial_marking: draft
  places: [draft, review, published, rejected]
  transitions:
    submit:  { from: draft, to: review }
    publish: { from: review, to: published, guard: editor }
    reject:  { from: review, to: rejected }
```

```crystal
Silth::Workflow.guard("article_publishing", "editor") { |article, user| user.as?(User).try(&.editor?) || false }
Silth::Workflow.on("article_publishing", :entered, "published") { |e| PublishedMail.new(e.subject.as(Article)).deliver_later }

wf = Silth::Workflow.get("article_publishing")
wf.can?(article, "publish", current_user)
wf.apply(article, "publish", current_user)     # updates `status` and saves
wf.enabled_transitions(article)                # ["publish", "reject"]
wf.blockers(article, "publish", current_user)  # why not?
```

A guard name can also be a [gate](/docs/security/authorization). Phases: `guard`, `leave`, `transition`, `enter`, `entered`, `completed`; a `Silth::Workflow::Transitioned` event is dispatched after each transition.

Define workflows in Crystal with `Silth::Workflow.define("name") { |w| w.transition("go", from: "a", to: "b") }`.

## Diagrams

```bash
silth workflow:dump article_publishing                 # Mermaid
silth workflow:dump article_publishing --format=dot    # Graphviz
silth workflow:dump article_publishing --format=svg
```

The profiler's *Workflows* tab renders every definition as an SVG diagram.
