# Evaluation validity integration

The report now carries the small set of validity fields needed before treating
an evaluation as release evidence:

- `evaluationCount`: how many scenarios were scored.
- `repeatRunCount`: how many administrations were compared.
- `repeatedRunSpread`: the largest score movement between administrations.
- `allowedSpread`: the declared variance threshold.
- `decisionConsistency`: whether both administrations reached the same gate state.

This is the runtime bridge to the deeper statistical work in
[LLM Eval Validity](https://github.com/julie-elkins/llm-eval-validity). The
Apple lab does not copy that repository's full analysis engine. It carries the
decision-critical fields in the product report and leaves the deeper questions
visible:

- A green point estimate is not enough without repeatability.
- A pooled score can hide a failing family.
- A judge or evaluator must be checked as an instrument, not treated as truth.
- A release gate must distinguish `FAIL` from `RERUN REQUIRED`.

The current deterministic scenarios repeat exactly, so the observed spread is
`0.0`. The live Foundation Models probe is deliberately not used as the
release gate because a variable model response needs a larger, repeated
evaluation design before it can support that decision.
