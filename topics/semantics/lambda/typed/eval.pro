:- ['../applied/eval.pro'].

% We add the fix construct.

eval(fix(T1),fix(T2)) :- eval(T1,T2).
eval(fix(lam(X,T1)),T2) :- substitute(fix(lam(X,T1)),X,T1,T2).
substitute(N,X,fix(T1),fix(T2)) :- substitute(N,X,T1,T2).
freevars(fix(T),FV) :- freevars(T,FV).

