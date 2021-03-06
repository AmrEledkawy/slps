@contributor{Vadim Zaytsev - vadim@grammarware.net - SWAT, CWI}
module analyse::Mining

import analyse::Metrics;
import language::BGF;
import io::ReadBGF;
import String;
import List;
import Map;
import IO;
import lib::Rascalware;
import export::BNF;
import analyse::Naming;
import analyse::Terminals;

// TODO: just import mutate::type2::RetireSs ?
// import normal::BGF;
// 
// SGrammar RetireSs(SGrammar g)
// {
// 	ps = visit(g.prods) {case selectable(_,BGFExpression e) => e};
// 	return <g.roots, normalise(g.prods)>;
// }
BGFProduction RetireSs(BGFProduction p) = visit(p) {case selectable(_,BGFExpression e) => e};

alias classifier = set[str](SGrammar);
alias patternbag = map[str name,classifier fun];
alias dict = map[BGFExpression,int];
alias NPC = tuple[int ns, int clasns, int ps, int cx, dict patterns, map[str,int] counts, set[str] weird, map[str,set[str]] scores];
NPC Zero = <0,0,0,0,(),(),{},()>;

map[str,tuple[int,int,str]] mineEmAll(set[loc] zoos, classifier metric)
{
	int cx = 0;
	map[str,tuple[int,int,str]] ret = ();
	BGFGrammar g;
	SGrammar s;
	str buf = "";
	for
	(
		loc zoo <- zoos,
		str lang <- listEntries(zoo),
		!endsWith(lang,".html"),
		str s <- listEntries(zoo+"/<lang>"),
		endsWith(s,".bgf")
	)
	{
		str who = "<lang>::<s>";
		println(who);
		cx += 1;
		g = readBGF(zoo+"/<lang>/<s>");
		sg = splitGrammar(g);
		m = metric(sg);
		for (str t <- m)
			buf += "<pp(sg.prods[t])>\n";
		ret[who] = <len(m),len(domain(sg.prods)),buf>;
	}
	return ret;
}

map[str,tuple[int,int,int,str,str,str,str]] mineTwo(set[loc] zoos, classifier m1, classifier m2)
{
	int cx = 0;
	map[str,tuple[int i1,int i2,int i3,str a1,str a2,str a3,str a4]] ret = ();
	BGFGrammar g;
	SGrammar s;
	str buf = "";
	for
	(
		loc zoo <- zoos,
		str lang <- listEntries(zoo),
		!endsWith(lang,".html"),
		str s <- listEntries(zoo+"/<lang>"),
		endsWith(s,".bgf")
	)
	{
		str who = "<lang>::<s>";
		println(who);
		cx += 1;
		g = readBGF(zoo+"/<lang>/<s>");
		sg = splitGrammar(g);
		m1r = m1(sg);
		m2r = m2(sg);
		// for (str t <- m)
		// 	buf += "<pp(sg.prods[t])>\n";
		ret[who] = <len(m1r),len(m2r),len(domain(sg.prods)),"","","","">;
		for (str t <- sg.prods)
		{
			if (t in m1r && t in m2r)
				ret[who].a1 += "<pp(sg.prods[t])>\n";
			elseif (t in m1r && t notin m2r)
				ret[who].a2 += "<pp(sg.prods[t])>\n";
			elseif (t notin m1r && t in m2r)
				ret[who].a3 += "<pp(sg.prods[t])>\n";
			else
				ret[who].a4 += "<pp(sg.prods[t])>\n";
		}
	}
	return ret;
}

NPC getZoo(loc zoo, NPC npc, patternbag Patterns)
{
	dict patterns = npc.patterns;
	int n = npc.ns, pcx = npc.ps, cx = npc.cx, cns = npc.clasns;
	set[str] weird = npc.weird, newweird = {}, nonclas = {};
	map[str,int] counts = npc.counts;
	map[str,set[str]] scores = npc.scores;
	BGFGrammar g;
	SGrammar s;
	set[str] allNTs = {};
	for (str lang <- listEntries(zoo), !endsWith(lang,".html"), str s <- listEntries(zoo+"/<lang>"), endsWith(s,".bgf"))
	{
		println("<lang>::<s>");
		cx += 1;
		g = readBGF(zoo+"/<lang>/<s>");
		allNTs = allNs(g);
		newweird = allNTs;
		nonclas = allNTs;
		int VAR = len(allNTs);
		n += VAR;
		pcx += len(g.prods);

		sg = splitGrammar(g);
		if (domain(sg.prods) != allNTs)
			println("Nonterminal sets are not equal!\n<domain(sg.prods)>\n<allNTs>\n<domain(sg.prods)-allNTs>\n<allNTs-domain(sg.prods)>");
		
		for (metric <- Patterns)
		{
			// println("  Calculating <metric>...");
			res = Patterns[metric](sg);
			if ("<metric>" notin counts) counts["<metric>"] = 0;
			if ("<metric>" notin scores) scores["<metric>"] = {};
			counts["<metric>"] += len(res);
			if (len(res)==VAR)
				scores["<metric>"] += {"<lang>::<s>"};
			if ("<Patterns[metric]>" in Exclude)
				newweird -= res;
			else
				allNTs -= res;
			if ("<Patterns[metric]>" notin (Exclude+Metasyntax))
				nonclas -= res;
		}
		cns += len(allNTs);
		weird += {"<lang>::<s>::<nt>" | nt <- newweird};
		
		if (false && !isEmpty(nonclas))
		{
			// int sz;
			println("  Not classified:");
			for(str ncnt <- nonclas)
				println("    <pp(prodsOfN(ncnt,g))>");
		}
		
		g = abstractPattern(g);
		for (BGFProduction p <- abstractPattern(g).prods)
			if (p.rhs in domain(patterns))
				patterns[p.rhs] += 1;
			else
				patterns[p.rhs] = 1;
	}
	return <n,cns,pcx,cx,patterns,counts,weird,scores>;
}

BGFGrammar abstractPattern(BGFGrammar g)
	= visit(g)
	{
		case nonterminal(_) => nonterminal("N")
		case terminal(_) => nonterminal("T")
		case selectable(_, BGFExpression expr) => expr
	};

SGrammar splitGrammar(BGFGrammar g)
{
	map[str,BGFProdSet] ps = ();
	for (BGFProduction p <- g.prods)
		if (p.lhs in domain(ps))
			ps[p.lhs] += {p};
		else
			ps[p.lhs] = {p};
	for (str n <- bottomNs(g))
		ps[n] = {};
	for (str n <- g.roots, n notin ps)
		ps[n] = {};
	return <toSet(g.roots), ps>;
}

////////////////////////////
// GROUP: GlobalPosition  //
////////////////////////////
set[str] tops(SGrammar g)    = definedNs(g) - usedNs(g); // = {t | str t <- domain(g.prods), /nonterminal(t) !:= range(g.prods)};
// The following is also a good definition, but too coarse for us:
// set[str] bottoms(SGrammar g) = usedNs(g) - definedNs(g);
// so we use this one:
set[str] bottoms(SGrammar g) = {n | str n <- domain(g.prods), isEmpty(g.prods[n]) };
set[str] ifroots(SGrammar g) = g.roots & domain(g.prods);
// TODO: not _, but in fact [*nonterminal(_)]
// TODO: also account for vertical roots
set[str] multiroots(SGrammar g) = {n | str n<-g.roots, {production(_,n,choice(L))} := g.prods[n], allnonterminals(L)};
// TODO: actually, much more complicated: may not refer to _defined_ nonterminals
set[str] leafs(SGrammar g) = {n | str n <- domain(g.prods), !isEmpty(g.prods[n]), /nonterminal(_) !:= g.prods[n] };

//////////////////////
// GROUP: ProdForm  //
//////////////////////
set[str] horizontals(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,choice(L))} := g.prods[n] };
set[str] verticals(SGrammar g) = {n | str n <- domain(g.prods),len(g.prods[n])>1,/production(_,n,choice(L))!:=g.prods[n]};
set[str] zigzags(SGrammar g) = {n | str n <- domain(g.prods),  len(g.prods[n])>1,/production(_,n,choice(L)) :=g.prods[n]};
// TODO: covers too much?
set[str] singletons(SGrammar g) = {n | str n <- domain(g.prods),
	{production(_,n,BGFExpression e)} := g.prods[n],
	choice(_) !:= e,
	empty() !:= e
};
set[str] undefineds(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,empty())} := g.prods[n] };

///////////////////////////
// GROUP: YACCification  //
///////////////////////////
set[str] yaccPL(SGrammar g) = {x | str x <- domain(g.prods),
	(
	{production(_,x,sequence([nonterminal(x),nonterminal(_)])),production(_,x,nonterminal(_))} := g.prods[x]
	||
	{production(_,x,choice([sequence([nonterminal(x),nonterminal(_)]),nonterminal(_)]))} := g.prods[x]
	||
	{production(_,x,choice([nonterminal(_),sequence([nonterminal(x),nonterminal(_)])]))} := g.prods[x]
	)
};
set[str] yaccPR(SGrammar g) = {x | str x <- domain(g.prods),
	(
	{production(_,x,sequence([nonterminal(_),nonterminal(x)])),production(_,x,nonterminal(_))} := g.prods[x]
	||
	{production(_,x,choice([sequence([nonterminal(_),nonterminal(x)]),nonterminal(_)]))} := g.prods[x]
	||
	{production(_,x,choice([nonterminal(_),sequence([nonterminal(_),nonterminal(x)])]))} := g.prods[x]
	)
};
set[str] yaccSL(SGrammar g) = {x | str x <- domain(g.prods),
	(
	{production(_,x,sequence([nonterminal(x),nonterminal(_)])),production(_,x,epsilon())} := g.prods[x]
	||
	{production(_,x,choice([sequence([nonterminal(x),nonterminal(_)]),epsilon()]))} := g.prods[x]
	||
	{production(_,x,choice([epsilon(),sequence([nonterminal(x),nonterminal(_)])]))} := g.prods[x]
	)
};
set[str] yaccSR(SGrammar g) = {x | str x <- domain(g.prods),
	(
	{production(_,x,sequence([nonterminal(_),nonterminal(x)])),production(_,x,epsilon())} := g.prods[x]
	||
	{production(_,x,choice([sequence([nonterminal(_),nonterminal(x)]),epsilon()]))} := g.prods[x]
	||
	{production(_,x,choice([epsilon(),sequence([nonterminal(_),nonterminal(x)])]))} := g.prods[x]
	)
};

////////////////////////
// GROUP: Metasyntax  //
////////////////////////
bool anylabel(BGFProdSet ps) = ( false | it || (production(str lab,_,_) := p && lab!="") | p <- ps );
set[str] useslab(SGrammar g) = {n | str n <- domain(g.prods), anylabel(g.prods[n])};

set[str] usesstar(SGrammar g) = {n | str n <- domain(g.prods), /star(_) := g.prods[n]};
set[str] usesplus(SGrammar g) = {n | str n <- domain(g.prods), /plus(_) := g.prods[n]};
set[str] usesopt(SGrammar g) = {n | str n <- domain(g.prods), /optional(_) := g.prods[n]};
set[str] usesepsilon(SGrammar g) = {n | str n <- domain(g.prods), /epsilon() := g.prods[n]};
set[str] usesempty(SGrammar g) = {n | str n <- domain(g.prods), /empty() := g.prods[n]};
set[str] usesany(SGrammar g) = {n | str n <- domain(g.prods), /anything() := g.prods[n]};
set[str] usesint(SGrammar g) = {n | str n <- domain(g.prods), /val(integer()) := g.prods[n]};
set[str] usesstr(SGrammar g) = {n | str n <- domain(g.prods), /val(string()) := g.prods[n]};
set[str] abstracts(SGrammar g) = {n | str n <- domain(g.prods), !isEmpty(g.prods[n]), /terminal(_) !:= g.prods[n]};
set[str] usessel(SGrammar g) = {n | str n <- domain(g.prods), /selectable(_,_) := g.prods[n]};
set[str] usesneg(SGrammar g) = {n | str n <- domain(g.prods), /not(_) := g.prods[n]};
set[str] usesconj(SGrammar g) = {n | str n <- domain(g.prods), /allof(_) := g.prods[n]};
set[str] usesseq(SGrammar g) = {n | str n <- domain(g.prods), /sequence(_) := g.prods[n]};
// the next one is more complicated since we want to count only inner choices
set[str] usesdisj(SGrammar g) = {n | str n <- domain(g.prods), 
	(
		(
		{production(_,n,choice(_))} !:= g.prods[n]
		&&
		/choice(_) := g.prods[n]
		)
	||
		(
		{production(_,n,choice(L))} := g.prods[n]
		&&
		/choice(_) := L
		)
	)
	};
// the next one should return zero results if run on real grammars and not on intermediate transformation results
set[str] usesmarked(SGrammar g) = {n | str n <- domain(g.prods), /marked(_) := g.prods[n]};
set[str] usesSLP(SGrammar g) = {n | str n <- domain(g.prods), /seplistplus(_,_) := g.prods[n]};
set[str] usesSLS(SGrammar g) = {n | str n <- domain(g.prods), /sepliststar(_,_) := g.prods[n]};

////////////////
// UNGROUPED  //
////////////////
set[str] constructors(SGrammar g) = {n | str n <- domain(g.prods), 
	(
		(
			{production(_,n,choice(L))} := g.prods[n]
		&&
			allconstructors(L)
		)
	||
		(
			!isEmpty(g.prods[n])
		&&
			allconstructors(g.prods[n])
		)
	)
};
// We assume normalised grammars in the sense of non-empty selector labels
bool allconstructors(BGFExprList es) = ( true | it && selectable(_,epsilon()) := e | e <- es );
// Labels, on the other hand, can be empty, need to check explicitly
bool allconstructors(BGFProdSet ps) = ( true | it && production(str lab,_,epsilon()) := p && !isEmpty(lab) | p <- ps );

// A non-trivial sequence of terminals, nonterminals and builtins.
set[str] pureseqs(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,rhs:sequence(L))} := g.prods[n], pureseq(rhs)};
bool pureseq(epsilon()) = true; // does not mean anything as a part of a sequence
bool pureseq(empty()) = false;
bool pureseq(anything()) = false; // arguable
bool pureseq(val(_)) = true; // arguable
bool pureseq(terminal(_)) = true;
bool pureseq(nonterminal(_)) = true;
bool pureseq(sequence(L)) = ( true | it && pureseq(e) | e <- L );
default bool pureseq(BGFExpression rhs) = false;

// Chomsky normal form
// see http://dx.doi.org/10.1016/S0019-9958(59)90362-6
set[str] cnfs(SGrammar g) = {n | str n <- domain(g.prods), !isEmpty(g.prods[n]), allCNFs(g.prods[n]) };
bool allCNFs(BGFProdSet ps) = ( true | it && isCNF(p.rhs) | p <- ps );
bool isCNF(epsilon()) = true;
bool isCNF(terminal(_)) = true;
bool isCNF(sequence([nonterminal(_),nonterminal(_)])) = true;
default bool isCNF(BGFExpression e) = false;

// Greibach normal form
// see http://dx.doi.org/10.1145/321250.321254
set[str] gnfs(SGrammar g) = {n | str n <- domain(g.prods), !isEmpty(g.prods[n]), allGNFs(g.prods[n]) };
bool allGNFs(BGFProdSet ps) = ( true | it && isGNF(p.rhs) | p <- ps );	
bool isGNF(epsilon()) = true;
bool isGNF(selectable(_,epsilon())) = true;
bool isGNF(sequence([terminal(),*L])) = isEmpty(L) || allnonterminals(L);
default bool isGNF(BGFExpression e) = false;

// Abstract normal form
// see http://dx.doi.org/10.6084/m9.figshare.643391
set[str] anfs(SGrammar g) = {n | str n <- domain(g.prods),
	/terminal(_) !:= g.prods[n],
	(
	// N⊥
		isEmpty(g.prods[n])
	||
		(// rhs could be empty(), but should not be a choice
			{production(_,n,rhs)} := g.prods[n]
		&&
			choice(_) !:= rhs
		)
	||
		(
			{production(_,n,choice(L))} := g.prods[n]
		&&
			allnonterminals(L)
		)
	||
		(
			len(g.prods[n])>1
		&&
			areallchains(g.prods[n])
		)
	)};


// TODO: include other patterns?
set[str] fakeseplists(SGrammar g) = {n | str n <- domain(g.prods), {p} := g.prods[n], isfakeseplist(RetireSs(p))};
bool isfakeseplist(production(_,_,sequence([BGFExpression a,star(sequence([BGFExpression b, a]))]) )) = true;
bool isfakeseplist(production(_,str n,choice([BGFExpression a,sequence([nonterminal(n),BGFExpression b,a])]) )) = true;
default bool isfakeseplist(BGFProduction p) = false;

set[str] fakeopts(SGrammar g) = {n | str n <- domain(g.prods), 
	(
	{production(_,n,choice([nonterminal(_),epsilon()]))} := g.prods[n]
	||
	(len(g.prods[n])>1 && production("",n,epsilon()) in g.prods[n])
	)
	};

set[str] ntorts(SGrammar g) = {n | str n <- domain(g.prods),
	({production(_,n,choice([nonterminal(_),terminal(_)]))} := g.prods[n] ||
	 {production(_,n,choice([terminal(_),nonterminal(_)]))} := g.prods[n]) };

set[str] nsandts(SGrammar g) = {n | str n <- domain(g.prods), arensandts(g.prods[n])};
bool arensandts({production(_,_,choice(L1))}) = isanyt(L1) && isanyn(L1) && allsometerminals(toSet(L1));
// TODO think of a faster way
default bool arensandts(BGFProdSet ps) = isanyt([p.rhs | p <- ps]) && isanyn([p.rhs | p <- ps]) && allsometerminals({p.rhs | p <- ps});
bool isanyt([]) = false;
default bool isanyt(BGFExprList es) = terminal(_) := head(es) || isanyt(tail(es));
bool isanyn([]) = false;
default bool isanyn(BGFExprList es) = nonterminal(_) := head(es) || isanyn(tail(es));

set[str] ntsorts(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,choice([*L,terminal(_)]))} := g.prods[n], allnonterminals(L), len(L)>1};
set[str] ntortss(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,choice([nonterminal(_),*L]))} := g.prods[n], allterminals(L), len(L)>1};
set[str] tsornts(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,choice([*L,nonterminal(_)]))} := g.prods[n], allterminals(L), len(L)>1 };

set[str] empties(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,epsilon())} := g.prods[n]};
set[str] failures(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,empty())} := g.prods[n]};

set[str] justplusses(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,plus(nonterminal(_)))} := g.prods[n]};
set[str] juststars(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,star(nonterminal(_)))} := g.prods[n]};
set[str] justopts(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,optional(nonterminal(_)))} := g.prods[n]};

// TODO: include other patterns?
set[str] justseplistps(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,seplistplus(nonterminal(_),terminal(_)))} := g.prods[n]};
set[str] justseplistss(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,sepliststar(nonterminal(_),terminal(_)))} := g.prods[n]};

set[str] bracketedseplistps(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,sequence([terminal(_),seplistplus(nonterminal(_),terminal(_)),terminal(_)]))} := g.prods[n]};
set[str] bracketedseplistss(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,sequence([terminal(_),sepliststar(nonterminal(_),terminal(_)),terminal(_)]))} := g.prods[n]};

set[str] bracketedfakeseplist(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,sequence([terminal(_),nonterminal(_),star(sequence([terminal(_),nonterminal(_)])),terminal(_)]))} := g.prods[n]};

bool bracketpair("(",")") = true;
bool bracketpair("[","]") = true;
bool bracketpair("{","}") = true;
bool bracketpair("\<","\>") = true;
bool bracketpair("\<!--","--\>") = true; // !!!
default bool bracketpair(str x, str y) = false;

set[str] accesslayers(SGrammar g) = {n | str n <- domain(g.prods),
	{production(_,n,sequence([nonterminal(_),terminal(str x),nonterminal(_),terminal(str y)]))} := g.prods[n],
	bracketpair(x,y)}
;

// TODO?
// listLiteral ::= "[" (expressionList ","?)? "]" ;

set[str] bracketedopts(SGrammar g) = {n | str n <- domain(g.prods),
	{production(_,n,sequence([terminal(str x),optional(nonterminal(_)),terminal(str y)]))} := g.prods[n],
	bracketpair(x,y)}
;

set[str] bracketedstars(SGrammar g) = {n | str n <- domain(g.prods),
	{production(_,n,sequence([terminal(str x),star(nonterminal(_)),terminal(str y)]))} := g.prods[n],
	bracketpair(x,y)}
;

set[str] bracketedpluss(SGrammar g) = {n | str n <- domain(g.prods),
	{production(_,n,sequence([terminal(str x),plus(nonterminal(_)),terminal(str y)]))} := g.prods[n],
	bracketpair(x,y)}
;

set[str] bracketedfakesepliststar(SGrammar g) = {n | str n <- domain(g.prods),
	({production(_,n,sequence([terminal(str x),
		optional(sequence([
			nonterminal(str elem),
			star(sequence([terminal(str sep), nonterminal(elem)])),
			optional(terminal(sep))
		])),terminal(str y)]))} := g.prods[n]
	||
	{production(_,n,sequence([terminal(str x),
		optional(sequence([
			nonterminal(str elem),
			star(sequence([terminal(str sep), nonterminal(elem)]))
		])),terminal(str y)]))} := g.prods[n]),
	bracketpair(x,y)}
;

// TODO? ArrayInitializer ::= "{" (N ("," N)* ","?)? "}" ;

set[str] layers(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,choice([nonterminal(_),*L]))} := g.prods[n], !isEmpty(L), allNTNof(n,L)};
bool allNTNof(str x,BGFExprList xs) = ( true | it && sequence([nonterminal(x),terminal(_),nonterminal(_)]) := e | e <- xs );
set[str] lowlayers(SGrammar g) = {n | str n <- domain(g.prods),
	{production(_,n,choice(L1))} := g.prods[n],
	!isEmpty(L1),
	{sequence([terminal(str x),nonterminal(_),terminal(str y)]),*L2} := toSet(L1),
	!isEmpty(L2),
	bracketpair(x,y),
	allsometerminals(L2)
};

bool allsometerminals(BGFExprSet xs) = ( true | it && (nonterminal(_) := e || terminal(_) := e) | e <- xs );

// TODO: simple chain as an all chain where $m$ is used only once in the whole grammar

// 10% classified as JustPseudoChoice: 4354 (0 scores).
set[str] allchains(SGrammar g) = {n | str n <- domain(g.prods), 
	(
		(
			len(g.prods[n]) > 1
		&&
			areallchains(g.prods[n])
		)
	||
		(
			{production(_,n,choice(L))} := g.prods[n]
		&&
			allnonterminals(L)
		)
	)
	};
bool areallchains(BGFProdSet ps) = ( true | it && production(_,_,nonterminal(_)) := p  | p <- ps );	
// set[str] somechains(SGrammar g) = {n | str n <- domain(g.prods), {*P1,production(_,n,nonterminal(_)),*P2} := g.prods[n]};
// TODO DEBUG why {production(_,n,nonterminal(_)),*Ps1} := g.prods[n] hangs on bibtex::bibtex-1.bgf
set[str] somechains(SGrammar g) = {n | str n <- domain(g.prods),
	(
		/production(_,n,nonterminal(_)) := g.prods[n]
	||
		(/production(_,n,choice(L)) := g.prods[n] && isthereonenonterminal(L))
	)
};

bool isthereonenonterminal([]) = false;
default bool isthereonenonterminal(BGFExprList L) = nonterminal(_) := head(L) || isthereonenonterminal(tail(L));

set[str] onechains(SGrammar g) = {n | str n <- domain(g.prods), {production(_,n,nonterminal(_))} := g.prods[n]};
set[str] reflchains(SGrammar g) = {n | str n <- domain(g.prods),
	(
		{production(_,n,nonterminal(n)),*P2} := g.prods[n]
	||
		(
			{production(_,n,choice(L1))} := g.prods[n]
		&&
			nonterminal(n) in L1
		)
	)
	};

set[str] selfbrackets(SGrammar g) = {n | str n <- domain(g.prods),
	{production(_,n,sequence([terminal(str x),nonterminal(n),terminal(str y)])),*P2} := g.prods[n],
	bracketpair(x,y)}
;
set[str] brackets(SGrammar g) = {n | str n <- domain(g.prods),
	{production(_,n,sequence([terminal(str x),nonterminal(_),terminal(str y)])),*P2} := g.prods[n],
	bracketpair(x,y)}
;
set[str] delimiteds(SGrammar g) = {n | str n <- domain(g.prods),
	{production(_,n,sequence([terminal(str x),nonterminal(_),terminal(str y)])),*P2} := g.prods[n],
	!bracketpair(x,y)}
;

// lower level functions
set[str] definedNs(SGrammar g) = {n | n <- domain(g.prods), !isEmpty(g.prods[n]), {production(_,n,empty())} !:= g.prods[n] };
set[str] usedNs(SGrammar g) = {n | /nonterminal(n) := range(g.prods)};

bool allnonterminals(BGFExprList xs) = ( true | it && nonterminal(_) := e | e <- xs );
bool allnonterminals(BGFExprSet xs) = ( true | it && nonterminal(_) := e | e <- xs );

set[str] distinguished(SGrammar g) = {n | str n <- domain(g.prods),
	({production(_,n,choice(L))} := g.prods[n] || {production(_,n,star(choice(L)))} := g.prods[n]),
	allTNpairs(L)};
bool allTNpairs(BGFExprList xs) = ( true | it && (
		terminal(_) := e ||
		sequence([terminal(_),nonterminal(_)]) := e ||
		sequence([terminal(_),optional(nonterminal(_))]) := e
	) | e <- xs );

set[str] notimplemented(SGrammar _) = {};

patternbag MetaPatterns =
	// Metasyntax
	(
		"ContainsStar":			usesstar,				// uses star within the definitions
		"ContainsPlus":			usesplus,				// uses plus within the definitions
		"ContainsOptional":		usesopt,				// uses optional within the definitions
		//
		"ContainsEpsilon":		usesepsilon,			// uses epsilon within the definitions
		"ContainsFailure":		usesempty,				// uses the empty metasymbol within the definitions
		"ContainsUniversal":	usesany,				// uses the universal metasymbol within the definitions
		// 
		"ContainsInteger":		usesint,				// uses integer within the definitions
		"ContainsString":		usesstr,				// uses string within the definitions
		// 
		"ContainsSelectors":	usessel,				// uses selectors within the definitions
		"ContainsLabels":		useslab,				// uses labels within (some of) the definitions
		"ContainsSequence":		usesseq,				// uses sequential composition within the definitions
		"ContainsDisjunction":	usesdisj,				// uses disjunction within the definitions
		// "ContainsConjunction":	usesconj,				// uses conjunction within the definitions
		// "ContainsNegation":		usesneg,				// uses negation within the definitions
		// 
		"ContainsSepListPlus":	usesSLP,				// uses plus separator lists within the definitions
		"ContainsSepListStar":	usesSLS,				// uses star separator lists within the definitions
		// 
		// "ContainsMarked":		usesmarked,				// should be empty
		// 
		"AbstractSyntax":		abstracts				// abstract syntax (no terminal symbols)
	);

patternbag GlobalPatterns =
	(
		// GlobalPosition
		"Top":					tops,					// defined but not used
		"Bottom":				bottoms,				// used but not defined
		"Leaf":					leafs,					// not referring to any other nonterminal
		"Root":					ifroots,				// if it is a root
		"MultiRoot":			multiroots,				// a “fake” multiple root
		// ProdForm
		"Disallowed":			undefineds,				// explicitly defined with empty
		"Singleton":			singletons,				// nonterminal is defined with one non-horizontal production rule
		"Horizontal":			horizontals,			// top level choice
		"Vertical":				verticals,				// multiple production rules per nonterminal
		"ZigZag":				zigzags					// both vertical and horizontal
	);

// micropatterns about metasyntactic sugar
// (known tricks or boilerplate grammar fragments due to lack of metasyntax expressivity)
patternbag SugarPatterns = 
	(
		"FakeSepList":			fakeseplists,			// “fake” separator list
		"FakeOptional":			fakeopts,				// “fake” optional nonterminal
		"ExprMidLayer":			layers,					// middle expression layers
		"ExprLowLayer":			lowlayers,				// lower expression layers
		// YACCification
		"YaccifiedPlusLeft":	yaccPL,					// x defined as ( x y | z ) or ( z | x y ) ⇒ y+, with possibly z == y
		"YaccifiedPlusRight":	yaccPR,					// x defined as ( y x | z ) or ( z | y x ) ⇒ y+, with possibly z == y
		"YaccifiedStarLeft":	yaccSL,					// x defined as ( x y | ε ) or ( ε | x y ) ⇒ y*
		"YaccifiedStarRight":	yaccSR					// x defined as ( y x | ε ) or ( ε | y x ) ⇒ y*
	);

// micropatterns about folding (arguable for readability purposes)
patternbag FoldingPatterns = 
	(
		"JustSepListPlus":		justseplistps,			// x defined as {y ","}+
		"JustSepListStar":		justseplistss,			// x defined as {y ","}*
		"JustPlus":				justplusses,			// x defined as y+
		"JustStar":				juststars,				// x defined as y*
		"JustOptional":			justopts,				// x defined as y?
		"JustChains":			allchains,				// nonterminal defined only with chain production rules (right hand sides are nonterminals)
		"JustOneChain":			onechains,				// nonterminal defined with a single chain production rule (right hand side == nonterminal)
		"Empty":				empties,				// nonterminal defines an empty language (epsilon)
		"Failure":				failures,				// nonterminal explicitly or implicitly undefined
		"AChain":				somechains,				// one production rule is a chain production rule (right hand side == nonterminal)
		"ReflexiveChain":		reflchains,				// one production rule is a reflexive chain (left hand side == right hand side)
		"ChainOrTerminal":		ntorts,					// nonterminal or terminal
		// "NTSorT":				ntsorts,				// nonterminals or terminal
		// "NTorTS":				ntortss,				// nonterminal or terminals
		// "TSorNT":				tsornts					// terminals or nonterminal
		"ChainsAndTerminals":	nsandts					// mix of terminals and nonterminals
	);

// micropatterns about normal forms
patternbag NormalPatterns = 
	(
		"CNF":					cnfs,					// production rules in Chomsky normal form
		"GNF":					gnfs,					// production rules in Greibach normal form
		"ANF":					anfs					// production rules in abstract normal form
	);

// 
//                ADD OTHER CLASSIFIERS HERE!
// 

patternbag TemplatePatterns = 
	(
		"BracketSelf":			selfbrackets,			// nonterminals that have a bracketing production, e.g. E ::= "(" E ")"
		// Pattern
		"BracketedSepListPlus":	bracketedseplistps,		// x defined as ( "(" {y ","}+ ")" )
		"BracketedSepListStar":	bracketedseplistss,		// x defined as ( "(" {y ","}* ")" )
		"BracketedFakeSepList":	bracketedfakeseplist,	// x defined as ( "(" y ("," z)* ")" )
		"BracketedOptional":	bracketedopts,			// x defined as ( "[" y? "]" )
		"BracketedStar":		bracketedstars,			// x defined as ( "[" y* "]" )
		"BracketedPlus":		bracketedpluss,			// x defined as ( "[" y+ "]" )
		"BracketedFakeSLStar":	bracketedfakesepliststar,//x defined as ( "[" (N (T N)* T?)? "]" ) or ( "[" (N (T N)*)? "]" )
		"Bracket":				brackets,				// nonterminals that have a bracketing production, e.g. E ::= "(" x ")"
		"ElementAccess":		accesslayers,			// x defined as ( y "(" z ")" )
		"Delimited":			delimiteds,				// x defined as ( T1 E T2 ) where T1 and T2 are not a bracketing pair
		"Constructor":			constructors,			// defined with labelled epsilons
		// the rest
		"PureSequence":			pureseqs,				// pure sequential composition
		"DistinguishByTerm":	distinguished,			// T N | T N | … | T N? | T N? | … | T | T | … or star thereof
		// Not implemented
		"No":					notimplemented
	);
// too popular or exhaustive
set[str] Exclude = {"<singletons>", "<horizontals>", "<verticals>", "<undefineds>"};
set[str] Metasyntax = {"<abstracts>", "<usesstar>", "<usesplus>", "<usesopt>", "<usesepsilon>", "<usesint>", "<usesstr>", "<usessel>", "<usesneg>", "<usesconj>", "<usesdisj>", "<usesSLP>", "<usesSLS>"};
// set[str]

void analyseBag(loc zoo, loc tank, patternbag mybag)
{
	NPC npc = getZoo(zoo,Zero,mybag);
	str buf = "";
	npc = getZoo(tank,npc,mybag);
	println("Total: <npc.cx> grammars, <npc.ps> production rules, <npc.ns> nonterminals (<npc.ns-npc.clasns> thereof classified).");
	for (metric <- mybag)
	{
		println("<100*npc.counts["<metric>"]/npc.ns>% classified as <metric>: <npc.counts["<metric>"]> (<len(npc.scores["<metric>"])> scores).");
		if (len(npc.scores["<metric>"])>0 && len(npc.scores["<metric>"])<30)
			println("  Scores: <joinStrings(npc.scores["<metric>"])>");
		buf += "<metric>\t<npc.counts["<metric>"]>\n";
	}
	writeFile(|cwd:///result.csv|,buf);
}

// void analyseNaming(loc zoo, loc tank) = analyseBag(zoo,tank,NamingPatterns);
// void analyseMeta(loc zoo, loc tank) = analyseBag(zoo,tank,MetaPatterns);
// void analyseGlobal(loc zoo, loc tank) = analyseBag(zoo,tank,GlobalPatterns);
// 
// MAIN
public void main(list[str] args)
{
	list[str] buf = ["","","",""];
	r = mineTwo({|home:///projects/webslps/zoo|,|home:///projects/webslps/tank|},accesslayers,distinguished);
	// r = mineTwo({|home:///projects/webslps/zoo|,|home:///projects/webslps/tank|},modifiers,modifiers2);
	// r = mineTwo({|home:///projects/webslps/microzoo|,|home:///projects/webslps/microzoo|},names3,notimplemented);
	// r = mineTwo({|home:///projects/webslps/zoo|,|home:///projects/webslps/tank|},allnames,allknown);
	// r = mineEmAll({|home:///projects/webslps/zoo|,|home:///projects/webslps/tank|},preterminals);
	for (str k <- r)
	{
		int a = r[k]<0>;
		int b = r[k]<1>;
		int c = r[k]<2>;
		if (a+b>2 && c>10)
			// println("<k>\t<100*a/b>\t% is <a> out of <b>");
			println("<k>\t<a>\t<b>\t<c>");
		// println("<k>\t<100*r[k]<0>/r[k]<1>>\t% is <r[k]<0>> out of <r[k]<1>>");
		// if (a!=0)
		// 	buf += "----------<k>----------\n<r[k]<2>>\n";
		if (r[k]<3>!="") buf[0] += "----------<k>----------\n<r[k]<3>>\n";
		if (r[k]<4>!="") buf[1] += "----------<k>----------\n<r[k]<4>>\n";
		if (r[k]<5>!="") buf[2] += "----------<k>----------\n<r[k]<5>>\n";
		if (r[k]<6>!="") buf[3] += "----------<k>----------\n<r[k]<6>>\n";
	}
	writeFile(|cwd:///lists0.bnf|,buf[0]);
	writeFile(|cwd:///lists1.bnf|,buf[1]);
	writeFile(|cwd:///lists2.bnf|,buf[2]);
	writeFile(|cwd:///lists3.bnf|,buf[3]);
	// writeFile(|cwd:///examples.bnf|,buf);
	return;
	analyseBag(|home:///projects/webslps/zoo|,|home:///projects/webslps/tank|,
		// NamingPatterns
		// MetaPatterns
		// GlobalPatterns
		// ConcretePatterns
		// SugarPatterns
		FoldingPatterns
		// NormalPatterns
		// TemplatePatterns
		// TODO idea: template "contains keyword"
	);
	return;
	// dead code that treats "the other kind of patterns" and "weird nonterminals"
	loc zoo = |home:///projects/webslps/zoo|;
	NPC npc = getZoo(|home:///projects/webslps/zoo|,Zero);
	str buf = "";
	npc = getZoo(|home:///projects/webslps/tank|,npc);
	println("Total: <npc.cx> grammars, <npc.ps> production rules, <npc.ns> nonterminals (<npc.ns-npc.clasns> thereof classified), <len(npc.patterns)> patterns.");
	for (metric <- AllMetrics)
	{
		println("<100*npc.counts["<metric>"]/npc.ns>% classified as <metric>: <npc.counts["<metric>"]> (<len(npc.scores["<metric>"])> scores).");
		if (len(npc.scores["<metric>"])>0 && len(npc.scores["<metric>"])<30)
			println("  Scores: <joinStrings(npc.scores["<metric>"])>");
		buf += "<metric>\t<npc.counts["<metric>"]>\n";
	}
	writeFile(|cwd:///result.csv|,buf);
	for (w <- npc.weird)
		println("Weird: <w>");
	// Just the Zoo:
	//              Total: 42 grammars, 8927 production rules, 8277 nonterminals.
	// Zoo + Tank:
	//              Total: 99 grammars, 11570 production rules, 10943 nonterminals.
	// After including the Atlantic, the Relax, etc:
	// Zoo + Tank:
	//              Total: 533 grammars, 55342 production rules, 41038 nonterminals (35021 thereof classified), 3403 patterns.
	// TODO: only report unclassified ones
	// for (BGFExpression e <- domain(npc.patterns))
	// 	println("<pp(e)>: <npc.patterns[e]>");
}

