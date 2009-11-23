% See slide 174

term(X) :- value(X).
term(var(X)) :- variable(X).
term(app(T1,T2)) :- term(T1), term(T2).

% Extension to deal with Prolog numbers and Booleans

term(succ(T)) :- term(T).
term(pred(T)) :- term(T).
term(iszero(T)) :- term(T).
term(if(T1,T2,T3)) :- term(T1),term(T2),term(T3).

% Normal forms

value(lam(X,T)) :- variable(X), term(T).

% Extension to deal with Prolog numbers and Booleans

value(true).
value(false).
value(X) :- number(X).

/*
 We use atomic/1 so that we can use numbers for "generated" vars.
 This is needed for alpha conversion in substitution.
*/

variable(X) :- atomic(X).
