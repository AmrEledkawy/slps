% Read, typecheck and evaluate

main(Input)
 :-
    see(Input),
    read(Term),
    seen,
    format('Input term: ~w~n',[Term]),
    welltyped(Term, Type),    
    format('Type of term: ~w~n',[Type]),
    manysteps(Term,X),
    show(X,Y),
    format('Value of term: ~w~n',[Y]).

:- ensure_loaded('../show.pro').

