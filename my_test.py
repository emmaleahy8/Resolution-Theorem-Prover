from os.path import isfile
from shutil import copyfile
import re
import os

path = './'

descriptions = [
    "1.  bird->flies, bird(tweety) |- flies(tweety)             [YES - modus ponens]",
    "2.  p->q->r->s, p(a) |- s(a)                              [YES - 4-step chain]",
    "3.  p->q |- p(b)                                           [NO  - unknown p(b)]",
    "4.  cat->animal, cat(whiskers) |- animal(whiskers)         [YES - modus ponens]",
    "5.  neg(neg(p(a))) |- p(a)                                 [YES - double negation]",
    "6.  p&q->r, p(b), q(b) |- r(b)                            [YES - conjunction use]",
    "7.  p(a), q(a) |- p(b)                                     [NO  - wrong constant]",
    "8.  p->q, q(a) |- p(a)                                     [NO  - affirming consequent]",
    "9.  likes symmetric, likes(alice,bob) |- likes(bob,alice)  [YES - symmetry]",
    "10. p->q&r, p(a) |- q(a)                                   [YES - conjunction elim]",
    "11. [] |- or(p(a), neg(p(a)))                              [YES - tautology]",
    "12. p(a), neg(p(a)) |- q(b)                                [YES - ex falso]",
    "13. p->q, neg(q(a)) |- neg(p(a))                           [YES - modus tollens]",
    "14. p->q, neg(q(a)) |- r(a)                                [NO  - mt gives neg(p(a)) not r(a)]",
    "15. (p|q)->r, p(a) |- r(a)                                 [YES - disjunctive ant. left]",
    "16. (p|q)->r, q(a) |- r(a)                                 [YES - disjunctive ant. right]",
    "17. p->q |- imp(p(a), q(a))                                [YES - imp as conclusion]",
    "18. p->q |- q(a)                                           [NO  - denying antecedent]",
    "19. p(a) |- p(b)                                           [NO  - different constant]",
    "20. p->q, p->neg(q), p(a) |- r(a)                         [YES - contradiction in premises]",
]

solutions = ['YES','YES','NO','YES','YES','YES','NO','NO','YES','YES',
             'YES','YES','YES','NO','YES','YES','YES','NO','NO','YES']

formulas = [
    'flies(tweety)',
    's(a)',
    'p(b)',
    'animal(whiskers)',
    'p(a)',
    'r(b)',
    'p(b)',
    'p(a)',
    'likes(bob, alice)',
    'q(a)',
    'or(p(a), neg(p(a)))',
    'q(b)',
    'neg(p(a))',
    'r(a)',
    'r(a)',
    'r(a)',
    'imp(p(a), q(a))',
    'q(a)',
    'p(b)',
    'r(a)',
]

premises = [
    '[forall(X, imp(bird(X), flies(X))), bird(tweety)]',
    '[forall(X, imp(p(X), q(X))), forall(X, imp(q(X), r(X))), forall(X, imp(r(X), s(X))), p(a)]',
    '[forall(X, imp(p(X), q(X)))]',
    '[forall(X, imp(cat(X), animal(X))), cat(whiskers)]',
    '[neg(neg(p(a)))]',
    '[forall(X, imp(and(p(X), q(X)), r(X))), p(b), q(b)]',
    '[p(a), q(a)]',
    '[forall(X, imp(p(X), q(X))), q(a)]',
    '[forall(X, forall(Y, imp(likes(X,Y), likes(Y,X)))), likes(alice, bob)]',
    '[forall(X, imp(p(X), and(q(X), r(X)))), p(a)]',
    '[]',
    '[p(a), neg(p(a))]',
    '[forall(X, imp(p(X), q(X))), neg(q(a))]',
    '[forall(X, imp(p(X), q(X))), neg(q(a))]',
    '[forall(X, imp(or(p(X), q(X)), r(X))), p(a)]',
    '[forall(X, imp(or(p(X), q(X)), r(X))), q(a)]',
    '[forall(X, imp(p(X), q(X)))]',
    '[forall(X, imp(p(X), q(X)))]',
    '[p(a)]',
    '[forall(X, imp(p(X), q(X))), forall(X, imp(p(X), neg(q(X)))), p(a)]',
]

def run_tests():
    correct = 0
    for i in range(len(formulas)):
        copyfile(path + 'resolution.pl', 'test.pl')
        with open('test.pl', 'a') as file:
            file.write('\n\nmy_test:-test(' + premises[i] + ', ' + formulas[i] + ').')
        os.system("swipl -l test.pl -t my_test. > out.txt 2>/dev/null")
        with open('out.txt') as file:
            fstr = file.read()
        answers = re.findall(r'YES|NO', fstr, re.IGNORECASE)
        if not answers:
            print(f"Test {i+1}: WARNING - no answer  |  {descriptions[i]}")
            continue
        a = answers[-1].upper()
        ok = a == solutions[i]
        status = "OK   " if ok else "WRONG"
        print(f"Test {i+1}: {status} [{a}]  |  {descriptions[i]}")
        if ok:
            correct += 1
    return correct

print("Running 20 custom tests...\n")
t = run_tests()
print(f"\n#correct answers={t}/{len(formulas)}")