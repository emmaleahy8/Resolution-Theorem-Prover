/*
1. YES
2. YES
3. NO
4. YES
5. NO
6. YES
7. NO
8. YES
9. NO
10. NO
*/

% CS262 Coursework - Resolution Theorem Prover
% Resolution in Prolog

% Part 1: Conversion to Clause Form

    % Step 1: Eliminate implications
        % (A -> B) is equivalent to ((not A) or B)
        elim_imp(imp(A, B), or(neg(A2), B2)) :- 
            elim_imp(A, A2),
            elim_imp(B, B2).

        elim_imp(and(A, B), and(A2, B2)) :-
            elim_imp(A, A2),
            elim_imp(B, B2).

        elim_imp(or(A, B), or(A2, B2)) :-
            elim_imp(A, A2),
            elim_imp(B, B2).

        elim_imp(neg(A), neg(A2)) :-
            elim_imp(A, A2).

        elim_imp(forall(X, A), forall(X, A2)) :-
            elim_imp(A, A2).

        elim_imp(A, A). % atomic

    % Step 2: Remove universal quantifiers

        remove_forall(forall(_, F), F2) :-
            remove_forall(F, F2).

        remove_forall(and(A, B), and(A2, B2)) :-
            remove_forall(A, A2),
            remove_forall(B, B2).

        remove_forall(or(A, B), or(A2, B2)) :-
            remove_forall(A, A2),
            remove_forall(B, B2).

        remove_forall(neg(A), neg(A2)) :-
            remove_forall(A, A2).

        remove_forall(A, A). % atomic

    % Step 3: Convert to Conjunctive Normal Form 
        % Step 3a: Negation Normal Form

        % not(not A) is equivalent to A
        nnf(neg(neg(A)), A2) :-
            nnf(A, A2).

        % De Morgan's Laws - AND
        nnf(neg(and(A, B)), or(A2, B2)) :-
            nnf(neg(A), A2),
            nnf(neg(B), B2).

        % De Morgan's Laws - OR
        nnf(neg(or(A, B)), and(A2, B2)) :-
            nnf(neg(A), A2),
            nnf(neg(B), B2).

        nnf(and(A, B), and(A2, B2)) :-
            nnf(A, A2),
            nnf(B, B2).

        nnf(or(A, B), or(A2, B2)) :-
            nnf(A, A2),
            nnf(B, B2).

        nnf(neg(A), neg(A)). % atomic negation
        nnf(A, A). % atomic

        % Step 3b: Distributive Laws

        dist(and(A, B), and(A2, B2)) :-
            dist(A, A2),
            dist(B, B2).

        dist(or(A, B), D) :-
            dist(A, A2),
            dist(B, B2),
            distribute(A2, B2, D).

        dist(A, A). % atomic

        % (A or (B and C)) is equivalent to ((A or B) and (A or C))
        distribute(A, and(B, C), and(X, Y)) :-
            dist(or(A, B), X),
            dist(or(A, C), Y).

        % ((A and B) or C) is equivalent to ((A or C) and (B or C))
        distribute(and(A, B), C, and(X, Y)) :-
            dist(or(A, C), X),
            dist(or(B, C), Y).

        % Otherwise keep it as a disjunction
        distribute(A, B, or(A, B)).

        % Step 3.c: CNF form
        to_cnf(F, CNF) :-
            nnf(F, NNF),
            dist(NNF, CNF).

    % Step 4: Convert CNF expression into list of clauses

        % A conjunction becomes multiple clauses
        cnf_to_clauses(and(A, B), Clauses) :-
            cnf_to_clauses(A, ClausesA),
            cnf_to_clauses(B, ClausesB),
            append(ClausesA, ClausesB, Clauses).

        % Anything else is one clause
        cnf_to_clauses(F, [Clause]) :-
            F \= and(_, _),
            disjunction_to_clause(F, Clause).

        % A disjunction becomes one clause with multiple literals
        disjunction_to_clause(or(A, B), Clause) :-
            disjunction_to_clause(A, ClauseA),
            disjunction_to_clause(B, ClauseB),
            append(ClauseA, ClauseB, Clause).

        % A single literal becomes a singleton list
        disjunction_to_clause(Literal, [Literal]) :-
            Literal \= or(_, _).

    % Full conversion from first-order logic to clause form
        clauseform(Formula, Clauses) :-
            elim_imp(Formula, NoImp),
            remove_forall(NoImp, NoForall),
            to_cnf(NoForall, CNF),
            cnf_to_clauses(CNF, RawClauses),
            standardise_apart(RawClauses, Clauses).

% Part 2: Resolution Step 

    % Step 1: Unify inner atomic formulas of complementary literals

        complementary(neg(A), B) :-
            A = B.

        complementary(A, neg(B)) :-
            A = B.

    % Step 2: Resolve two clauses

        resolve(C1, C2, Resolvent) :-
            select(L1, C1, RestC1),
            select(L2, C2, RestC2),
            complementary(L1, L2),
            append(RestC1, RestC2, Resolvent).

% Part 3: Factoring

    % Step 1: Unify literals of the same polarity within a clause

        unify_literals(neg(A), neg(B)) :-
            A = B.

        unify_literals(A, B) :-
            A \= neg(_),
            B \= neg(_),
            A = B.
    
    % Step 2: Factoring

        factor(Clause, FactoredClause) :-
            select(L1, Clause, Rest1),
            select(L2, Rest1, Rest2),
            unify_literals(L1, L2),
            FactoredClause = [L1 | Rest2].

% Part 4: Resolution Procedure

    % Closed clauses: contains the empty clause
        closed_resolution(Clauses) :-
            member([], Clauses). % empty clause indicates contradiction

    % Factorising step: generates new clauses by factoring existing ones
        factorstep(Clauses, NewClauses) :-
            member(C, Clauses),
            copy_term(C, FreshC),
            factor(FreshC, Factored),
            normalise_clause(Factored, NormalFactored),
            new_clause(NormalFactored, Clauses),
            append(Clauses, [NormalFactored], NewClauses).
    
    % Resolution step: generates new clauses from existing ones
        resolutionstep(Clauses, NewClauses) :-
            select(C1, Clauses, Rest),
            member(C2, Rest),
            copy_term(C1, FreshC1),
            copy_term(C2, FreshC2),
            resolve(FreshC1, FreshC2, Resolvent),
            normalise_clause(Resolvent, NormalResolvent),
            new_clause(NormalResolvent, Clauses),
            append(Clauses, [NormalResolvent], NewClauses).

    % Single step  can be either resolution or factoring
        single_step_resolution(Clauses, NewClauses) :-
            factorstep(Clauses, NewClauses).
        
        single_step_resolution(Clauses, NewClauses) :-
            resolutionstep(Clauses, NewClauses).

    % Main resolution loop
        resolution(Clauses, true) :-
            closed_resolution(Clauses), !. % success if empty clause is derived
        
        resolution(Clauses, Result) :-
            single_step_resolution(Clauses, NewClauses), !,
            resolution(NewClauses, Result).

        resolution(_, false). % failure if no new clauses can be generated

% Helper Predicates
    
    % Make [p(a), q(a)] and [q(a), p(a)] the same clause
    normalise_clause(Clause, NormalClause) :-
        sort(Clause, NormalClause). % sort literals to avoid duplicates
    
    % Check if a clause is a variant of any clause in the list
    member_variant(Clause, [C | _]) :-
        Clause =@= C.
    member_variant(Clause, [_ | Rest]) :-
        member_variant(Clause, Rest).

    % A clause is new if no variant of it is already present
    new_clause(Clause, Clauses) :-
        \+ member_variant(Clause, Clauses).

    % Standardise apart and normalise clauses
    standardise_apart([], []).

    standardise_apart([C | Cs], [NewC | NewCs]) :-
        copy_term(C, FreshC),
        normalise_clause(FreshC, NewC),
        standardise_apart(Cs, NewCs).

% Part 5: Test Interface
    % Convert list of formulae to combined list of clauses
        clauses_from_list([], []).

        clauses_from_list([F | Rest], Clauses) :-
            clauseform(F, FClauses),
            clauses_from_list(Rest, RestClauses),
            append(FClauses, RestClauses, Clauses).

    % Main test predicate
        test(Premises, Conclusion) :-
            clauses_from_list(Premises, PremiseClauses),
            clauseform(neg(Conclusion), NegConclusionClauses),
            append(PremiseClauses, NegConclusionClauses, AllClauses),
            resolution(AllClauses, Result),
            print_result(Result).

     % Print YES if resolution found a contradiction, otherwise NO.
        print_result(true) :-
            write('YES'), nl.

        print_result(false) :-
            write('NO'), nl.