# Resolution Theorem Prover

A resolution-based theorem prover written in Prolog. Given a list of premises and a conclusion, it decides whether the conclusion follows logically from the premises. It does this by converting everything to clause form and searching for a refutation. Built as coursework for CS262 Logic and Verification at the University of Warwick.

```prolog
?- test([forall(X, imp(man(X), mortal(X))), man(socrates)], mortal(socrates)).
YES

?- test([forall(X, imp(p(X), q(X)))], q(a)).
NO
```

## How it works

To prove that a conclusion follows from some premises, the prover negates the conclusion, adds it to the premises, and tries to derive a contradiction (the empty clause). If it finds one, the conclusion follows.

**1. Clause form conversion** (`clauseform/2`)

Each formula goes through a pipeline:

1. **Eliminate implications:** `A → B` becomes `¬A ∨ B`.
2. **Drop universal quantifiers:** `forall(X, F)` becomes `F`, leaving `X` as a free Prolog variable.
3. **Negation normal form:** double negations are removed and De Morgan's laws push negations down to the atoms.
4. **Distribute ∨ over ∧** to reach conjunctive normal form.
5. **Flatten** the CNF into a list of clauses, each a list of literals.
6. **Standardise apart:** every clause gets fresh variables, and its literals are sorted into a canonical order.

```prolog
?- clauseform(imp(and(a, b), c), C).
C = [[c, neg(a), neg(b)]].
```

**2. Resolution with unification** (`resolve/3`)

Two clauses resolve when one contains a literal `L` and the other contains `neg(L')` where `L` and `L'` unify. Prolog's built-in unification does the matching, so first-order terms like `p(f(X))` and `p(f(a))` work directly. Both clauses are copied with `copy_term/2` first, so bindings made in one inference never leak into the clause set.

**3. Factoring** (`factor/2`)

Two literals of the same polarity within one clause can be unified and merged. For example, `[p(X), p(Y)]` factors to `[p(X)]`. Without factoring, resolution is incomplete for first-order logic.

**4. Saturation loop** (`resolution/2`)

At each step the prover tries to add one new clause by factoring or resolution. It stops with `true` as soon as the empty clause appears, or with `false` once no new clause can be generated. Clauses are normalised by sorting, and duplicates are rejected using variant checking (`=@=`), so the clause set doesn't fill up with renamed copies of the same clause.

## Input syntax

Formulas are ordinary Prolog terms:

| Connective | Syntax |
|---|---|
| ¬A | `neg(A)` |
| A ∧ B | `and(A, B)` |
| A ∨ B | `or(A, B)` |
| A → B | `imp(A, B)` |
| ∀X. A | `forall(X, A)` |

Atoms are Prolog terms such as `p`, `p(a)` or `loves(X, f(Y))`. Variables bound by `forall` must be Prolog variables (capitalised).

## Running it

Requires [SWI-Prolog](https://www.swi-prolog.org/).

```bash
swipl resolution.pl
```

```prolog
?- test([imp(a, b), imp(b, c)], imp(a, c)).
YES
```

## Limitations

- **Universal quantifiers only.** There is no existential quantifier and no Skolemisation. One consequence is that a universally quantified *conclusion* is handled unsoundly: negating `forall(X, p(X))` should introduce a Skolem constant, but the prover instead treats `X` as universal. So `test([p(a)], forall(X, p(X)))` incorrectly prints `YES`.
- **Limited connectives.** Only `neg`, `and`, `or` and `imp` are supported. There is no equivalence, XOR or NAND/NOR, and no infix operator syntax.
- **Not a decision procedure.** First-order logic is only semi-decidable, so on some non-theorems the search may run for a very long time instead of answering `NO`.
- **Naive search.** Clauses are combined in list order with no subsumption checking or set-of-support strategy, so larger problems can be slow.

## Academic integrity

This was assessed coursework. If you're currently taking CS262 or a similar module, please don't copy it.
