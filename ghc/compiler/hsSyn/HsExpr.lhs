%
% (c) The GRASP/AQUA Project, Glasgow University, 1992-1994
%
\section[HsExpr]{Abstract Haskell syntax: expressions}

\begin{code}
#include "HsVersions.h"

module HsExpr where

IMP_Ubiq(){-uitous-}

-- friends:
#if defined(__GLASGOW_HASKELL__) && __GLASGOW_HASKELL__ <= 201
IMPORT_DELOOPER(HsLoop) ( pprMatches, pprMatch, Match )
#else
import {-# SOURCE #-} HsMatches ( pprMatches, pprMatch, Match )
#endif

import HsBinds		( HsBinds )
import HsBasic		( HsLit )
import BasicTypes	( Fixity(..), FixityDirection(..) )
import HsTypes		( HsType )

-- others:
import Id		( SYN_IE(DictVar), GenId, SYN_IE(Id) )
import Outputable	( pprQuote, interppSP, interpp'SP, ifnotPprForUser, 
			  PprStyle(..), userStyle, Outputable(..) )
import PprType		( pprGenType, pprParendGenType, GenType{-instance-} )
import Pretty
import SrcLoc		( SrcLoc )
import Usage		( GenUsage{-instance-} )
#if __GLASGOW_HASKELL__ >= 202
import Name
#endif
\end{code}

%************************************************************************
%*									*
\subsection{Expressions proper}
%*									*
%************************************************************************

\begin{code}
data HsExpr tyvar uvar id pat
  = HsVar	id				-- variable
  | HsLit	HsLit				-- literal
  | HsLitOut	HsLit				-- TRANSLATION
		(GenType tyvar uvar)		-- (with its type)

  | HsLam	(Match  tyvar uvar id pat)	-- lambda
  | HsApp	(HsExpr tyvar uvar id pat)	-- application
		(HsExpr tyvar uvar id pat)

  -- Operator applications:
  -- NB Bracketed ops such as (+) come out as Vars.

  -- NB We need an expr for the operator in an OpApp/Section since
  -- the typechecker may need to apply the operator to a few types.

  | OpApp	(HsExpr tyvar uvar id pat)	-- left operand
		(HsExpr tyvar uvar id pat)	-- operator
		Fixity				-- Renamer adds fixity; bottom until then
		(HsExpr tyvar uvar id pat)	-- right operand

  -- We preserve prefix negation and parenthesis for the precedence parser.
  -- They are eventually removed by the type checker.

  | NegApp	(HsExpr tyvar uvar id pat)	-- negated expr
		(HsExpr tyvar uvar id pat)	-- the negate id (in a HsVar)

  | HsPar	(HsExpr tyvar uvar id pat)	-- parenthesised expr

  | SectionL	(HsExpr tyvar uvar id pat)	-- operand
		(HsExpr tyvar uvar id pat)	-- operator
  | SectionR	(HsExpr tyvar uvar id pat)	-- operator
		(HsExpr tyvar uvar id pat)	-- operand
				
  | HsCase	(HsExpr tyvar uvar id pat)
		[Match  tyvar uvar id pat]	-- must have at least one Match
		SrcLoc

  | HsIf	(HsExpr tyvar uvar id pat)	--  predicate
		(HsExpr tyvar uvar id pat)	--  then part
		(HsExpr tyvar uvar id pat)	--  else part
		SrcLoc

  | HsLet	(HsBinds tyvar uvar id pat)	-- let(rec)
		(HsExpr  tyvar uvar id pat)

  | HsDo	DoOrListComp
		[Stmt tyvar uvar id pat]	-- "do":one or more stmts
		SrcLoc

  | HsDoOut	DoOrListComp
		[Stmt   tyvar uvar id pat]	-- "do":one or more stmts
		id				-- id for return
		id				-- id for >>=
		id				-- id for zero
		(GenType tyvar uvar)		-- Type of the whole expression
		SrcLoc

  | ExplicitList		-- syntactic list
		[HsExpr tyvar uvar id pat]
  | ExplicitListOut		-- TRANSLATION
		(GenType tyvar uvar)	-- Gives type of components of list
		[HsExpr tyvar uvar id pat]

  | ExplicitTuple		-- tuple
		[HsExpr tyvar uvar id pat]
				-- NB: Unit is ExplicitTuple []
				-- for tuples, we can get the types
				-- direct from the components

	-- Record construction
  | RecordCon	id
		(HsRecordBinds tyvar uvar id pat)

  | RecordConOut id				-- The constructor
		 (HsExpr tyvar uvar id pat)	-- The constructor applied to type/dict args
		 (HsRecordBinds tyvar uvar id pat)

	-- Record update
  | RecordUpd	(HsExpr tyvar uvar id pat)
		(HsRecordBinds tyvar uvar id pat)

  | RecordUpdOut (HsExpr tyvar uvar id pat)	-- TRANSLATION
		 (GenType tyvar uvar)		-- Type of *result* record (may differ from
						-- type of input record)
		 [id]				-- Dicts needed for construction
		 (HsRecordBinds tyvar uvar id pat)

  | ExprWithTySig		-- signature binding
		(HsExpr tyvar uvar id pat)
		(HsType id)
  | ArithSeqIn			-- arithmetic sequence
		(ArithSeqInfo tyvar uvar id pat)
  | ArithSeqOut
		(HsExpr       tyvar uvar id pat) -- (typechecked, of course)
		(ArithSeqInfo tyvar uvar id pat)

  | CCall	FAST_STRING	-- call into the C world; string is
		[HsExpr tyvar uvar id pat]	-- the C function; exprs are the
				-- arguments to pass.
		Bool		-- True <=> might cause Haskell
				-- garbage-collection (must generate
				-- more paranoid code)
		Bool		-- True <=> it's really a "casm"
				-- NOTE: this CCall is the *boxed*
				-- version; the desugarer will convert
				-- it into the unboxed "ccall#".
		(GenType tyvar uvar)	-- The result type; will be *bottom*
				-- until the typechecker gets ahold of it

  | HsSCC	FAST_STRING	-- "set cost centre" (_scc_) annotation
		(HsExpr tyvar uvar id pat) -- expr whose cost is to be measured
\end{code}

Everything from here on appears only in typechecker output.

\begin{code}
  | TyLam			-- TRANSLATION
		[tyvar]
		(HsExpr tyvar uvar id pat)
  | TyApp			-- TRANSLATION
		(HsExpr  tyvar uvar id pat) -- generated by Spec
		[GenType tyvar uvar]

  -- DictLam and DictApp are "inverses"
  |  DictLam
		[id]
		(HsExpr tyvar uvar id pat)
  |  DictApp
		(HsExpr tyvar uvar id pat)
		[id]

  -- ClassDictLam and Dictionary are "inverses" (see note below)
  |  ClassDictLam
		[id]		-- superclass dicts
		[id]		-- methods
		(HsExpr tyvar uvar id pat)
  |  Dictionary
		[id]		-- superclass dicts
		[id]		-- methods

  |  SingleDict			-- a simple special case of Dictionary
		id		-- local dictionary name

type HsRecordBinds tyvar uvar id pat
  = [(id, HsExpr tyvar uvar id pat, Bool)]
	-- True <=> source code used "punning",
	-- i.e. {op1, op2} rather than {op1=e1, op2=e2}
\end{code}

A @Dictionary@, unless of length 0 or 1, becomes a tuple.  A
@ClassDictLam dictvars methods expr@ is, therefore:
\begin{verbatim}
\ x -> case x of ( dictvars-and-methods-tuple ) -> expr
\end{verbatim}

\begin{code}
instance (NamedThing id, Outputable id, Outputable pat,
	  Eq tyvar, Outputable tyvar, Eq uvar, Outputable uvar) =>
		Outputable (HsExpr tyvar uvar id pat) where
    ppr sty expr = pprQuote sty $ \ sty -> pprExpr sty expr
\end{code}

\begin{code}
pprExpr :: (NamedThing id, Outputable id, Outputable pat, 
	    Eq tyvar, Outputable tyvar, Eq uvar, Outputable uvar)
        => PprStyle -> HsExpr tyvar uvar id pat -> Doc

pprExpr sty (HsVar v) = ppr sty v

pprExpr sty (HsLit    lit)   = ppr sty lit
pprExpr sty (HsLitOut lit _) = ppr sty lit

pprExpr sty (HsLam match)
  = hsep [char '\\', nest 2 (pprMatch sty True match)]

pprExpr sty expr@(HsApp e1 e2)
  = let (fun, args) = collect_args expr [] in
    (pprExpr sty fun) <+> (sep (map (pprExpr sty) args))
  where
    collect_args (HsApp fun arg) args = collect_args fun (arg:args)
    collect_args fun		 args = (fun, args)

pprExpr sty (OpApp e1 op fixity e2)
  = case op of
      HsVar v -> pp_infixly v
      _	      -> pp_prefixly
  where
    pp_e1 = pprParendExpr sty e1		-- Add parens to make precedence clear
    pp_e2 = pprParendExpr sty e2

    pp_prefixly
      = hang (pprExpr sty op) 4 (sep [pp_e1, pp_e2])

    pp_infixly v
      = sep [pp_e1, hsep [ppr sty v, pp_e2]]

pprExpr sty (NegApp e _)
  = (<>) (char '-') (pprParendExpr sty e)

pprExpr sty (HsPar e)
  = parens (pprExpr sty e)

pprExpr sty (SectionL expr op)
  = case op of
      HsVar v -> pp_infixly v
      _	      -> pp_prefixly
  where
    pp_expr = pprParendExpr sty expr

    pp_prefixly = hang (hsep [text " \\ x_ ->", ppr sty op])
		       4 (hsep [pp_expr, ptext SLIT("x_ )")])
    pp_infixly v = parens (sep [pp_expr, ppr sty v])

pprExpr sty (SectionR op expr)
  = case op of
      HsVar v -> pp_infixly v
      _	      -> pp_prefixly
  where
    pp_expr = pprParendExpr sty expr

    pp_prefixly = hang (hsep [text "( \\ x_ ->", ppr sty op, ptext SLIT("x_")])
		       4 ((<>) pp_expr rparen)
    pp_infixly v
      = parens (sep [ppr sty v, pp_expr])

pprExpr sty (HsCase expr matches _)
  = sep [ sep [ptext SLIT("case"), nest 4 (pprExpr sty expr), ptext SLIT("of")],
	    nest 2 (pprMatches sty (True, empty) matches) ]

pprExpr sty (HsIf e1 e2 e3 _)
  = sep [hsep [ptext SLIT("if"), nest 2 (pprExpr sty e1), ptext SLIT("then")],
	   nest 4 (pprExpr sty e2),
	   ptext SLIT("else"),
	   nest 4 (pprExpr sty e3)]

-- special case: let ... in let ...
pprExpr sty (HsLet binds expr@(HsLet _ _))
  = sep [hang (ptext SLIT("let")) 2 (hsep [ppr sty binds, ptext SLIT("in")]),
	   ppr sty expr]

pprExpr sty (HsLet binds expr)
  = sep [hang (ptext SLIT("let")) 2 (ppr sty binds),
	   hang (ptext SLIT("in"))  2 (ppr sty expr)]

pprExpr sty (HsDo do_or_list_comp stmts _)            = pprDo do_or_list_comp sty stmts
pprExpr sty (HsDoOut do_or_list_comp stmts _ _ _ _ _) = pprDo do_or_list_comp sty stmts

pprExpr sty (ExplicitList exprs)
  = brackets (fsep (punctuate comma (map (pprExpr sty) exprs)))
pprExpr sty (ExplicitListOut ty exprs)
  = hcat [ brackets (fsep (punctuate comma (map (pprExpr sty) exprs))),
	   ifnotPprForUser sty ((<>) space (parens (pprGenType sty ty))) ]

pprExpr sty (ExplicitTuple exprs)
  = parens (sep (punctuate comma (map (pprExpr sty) exprs)))

pprExpr sty (RecordCon con rbinds)
  = pp_rbinds sty (ppr sty con) rbinds
pprExpr sty (RecordConOut con_id con_expr rbinds)
  = pp_rbinds sty (ppr sty con_expr) rbinds

pprExpr sty (RecordUpd aexp rbinds)
  = pp_rbinds sty (pprParendExpr sty aexp) rbinds
pprExpr sty (RecordUpdOut aexp _ _ rbinds)
  = pp_rbinds sty (pprParendExpr sty aexp) rbinds

pprExpr sty (ExprWithTySig expr sig)
  = hang ((<>) (nest 2 (pprExpr sty expr)) (ptext SLIT(" ::")))
	 4 (ppr sty sig)

pprExpr sty (ArithSeqIn info)
  = brackets (ppr sty info)
pprExpr sty (ArithSeqOut expr info)
  | userStyle sty = brackets (ppr sty info)
  | otherwise     = brackets (hcat [parens (ppr sty expr), space, ppr sty info])

pprExpr sty (CCall fun args _ is_asm result_ty)
  = hang (if is_asm
	    then hcat [ptext SLIT("_casm_ ``"), ptext fun, ptext SLIT("''")]
	    else (<>)  (ptext SLIT("_ccall_ ")) (ptext fun))
	 4 (sep (map (pprParendExpr sty) args))

pprExpr sty (HsSCC label expr)
  = sep [ (<>) (ptext SLIT("_scc_ ")) (hcat [char '"', ptext label, char '"']),
	    pprParendExpr sty expr ]

pprExpr sty (TyLam tyvars expr)
  = hang (hsep [ptext SLIT("/\\"), interppSP sty tyvars, ptext SLIT("->")])
	 4 (pprExpr sty expr)

pprExpr sty (TyApp expr [ty])
  = hang (pprExpr sty expr) 4 (pprParendGenType sty ty)

pprExpr sty (TyApp expr tys)
  = hang (pprExpr sty expr)
	 4 (brackets (interpp'SP sty tys))

pprExpr sty (DictLam dictvars expr)
  = hang (hsep [ptext SLIT("\\{-dict-}"), interppSP sty dictvars, ptext SLIT("->")])
	 4 (pprExpr sty expr)

pprExpr sty (DictApp expr [dname])
  = hang (pprExpr sty expr) 4 (ppr sty dname)

pprExpr sty (DictApp expr dnames)
  = hang (pprExpr sty expr)
	 4 (brackets (interpp'SP sty dnames))

pprExpr sty (ClassDictLam dicts methods expr)
  = hang (hsep [ptext SLIT("\\{-classdict-}"),
		   brackets (interppSP sty dicts),
		   brackets (interppSP sty methods),
		   ptext SLIT("->")])
	 4 (pprExpr sty expr)

pprExpr sty (Dictionary dicts methods)
  = parens (sep [ptext SLIT("{-dict-}"),
		   brackets (interpp'SP sty dicts),
		   brackets (interpp'SP sty methods)])

pprExpr sty (SingleDict dname)
  = hsep [ptext SLIT("{-singleDict-}"), ppr sty dname]

\end{code}

Parenthesize unless very simple:
\begin{code}
pprParendExpr :: (NamedThing id, Outputable id, Outputable pat,
		  Eq tyvar, Outputable tyvar, Eq uvar, Outputable uvar)
	      => PprStyle -> HsExpr tyvar uvar id pat -> Doc

pprParendExpr sty expr
  = let
	pp_as_was = pprExpr sty expr
    in
    case expr of
      HsLit l		    -> ppr sty l
      HsLitOut l _	    -> ppr sty l

      HsVar _		    -> pp_as_was
      ExplicitList _	    -> pp_as_was
      ExplicitListOut _ _   -> pp_as_was
      ExplicitTuple _	    -> pp_as_was
      HsPar _		    -> pp_as_was

      _			    -> parens pp_as_was
\end{code}

%************************************************************************
%*									*
\subsection{Record binds}
%*									*
%************************************************************************

\begin{code}
pp_rbinds :: (NamedThing id, Outputable id, Outputable pat,
		  Eq tyvar, Outputable tyvar, Eq uvar, Outputable uvar)
	      => PprStyle -> Doc 
	      -> HsRecordBinds tyvar uvar id pat -> Doc

pp_rbinds sty thing rbinds
  = hang thing 
	 4 (braces (hsep (punctuate comma (map (pp_rbind sty) rbinds))))
  where
    pp_rbind sty (v, _, True) | userStyle sty = ppr sty v
    pp_rbind sty (v, e, _)    		      = hsep [ppr sty v, char '=', ppr sty e]
\end{code}

%************************************************************************
%*									*
\subsection{Do stmts and list comprehensions}
%*									*
%************************************************************************

\begin{code}
data DoOrListComp = DoStmt | ListComp | Guard

pprDo DoStmt sty stmts
  = hang (ptext SLIT("do")) 2 (vcat (map (ppr sty) stmts))
pprDo ListComp sty stmts
  = brackets $
    hang (pprExpr sty expr <+> char '|')
       4 (interpp'SP sty quals)
  where
    ReturnStmt expr = last stmts	-- Last stmt should be a ReturnStmt for list comps
    quals	    = init stmts
\end{code}

\begin{code}
data Stmt tyvar uvar id pat
  = BindStmt	pat
		(HsExpr  tyvar uvar id pat)
		SrcLoc

  | LetStmt	(HsBinds tyvar uvar id pat)

  | GuardStmt	(HsExpr  tyvar uvar id pat)		-- List comps only
		SrcLoc

  | ExprStmt	(HsExpr  tyvar uvar id pat)		-- Do stmts only
		SrcLoc

  | ReturnStmt	(HsExpr  tyvar uvar id pat)		-- List comps only, at the end
\end{code}

\begin{code}
instance (NamedThing id, Outputable id, Outputable pat,
	  Eq tyvar, Outputable tyvar, Eq uvar, Outputable uvar) =>
		Outputable (Stmt tyvar uvar id pat) where
    ppr sty stmt = pprQuote sty $ \ sty -> pprStmt sty stmt

pprStmt sty (BindStmt pat expr _)
 = hsep [ppr sty pat, ptext SLIT("<-"), ppr sty expr]
pprStmt sty (LetStmt binds)
 = hsep [ptext SLIT("let"), ppr sty binds]
pprStmt sty (ExprStmt expr _)
 = ppr sty expr
pprStmt sty (GuardStmt expr _)
 = ppr sty expr
pprStmt sty (ReturnStmt expr)
 = hsep [ptext SLIT("return"), ppr sty expr]    
\end{code}

%************************************************************************
%*									*
\subsection{Enumerations and list comprehensions}
%*									*
%************************************************************************

\begin{code}
data ArithSeqInfo  tyvar uvar id pat
  = From	    (HsExpr tyvar uvar id pat)
  | FromThen 	    (HsExpr tyvar uvar id pat)
		    (HsExpr tyvar uvar id pat)
  | FromTo	    (HsExpr tyvar uvar id pat)
		    (HsExpr tyvar uvar id pat)
  | FromThenTo	    (HsExpr tyvar uvar id pat)
		    (HsExpr tyvar uvar id pat)
		    (HsExpr tyvar uvar id pat)
\end{code}

\begin{code}
instance (NamedThing id, Outputable id, Outputable pat,
	  Eq tyvar, Outputable tyvar, Eq uvar, Outputable uvar) =>
		Outputable (ArithSeqInfo tyvar uvar id pat) where
    ppr sty (From e1)		= hcat [ppr sty e1, pp_dotdot]
    ppr sty (FromThen e1 e2)	= hcat [ppr sty e1, comma, space, ppr sty e2, pp_dotdot]
    ppr sty (FromTo e1 e3)	= hcat [ppr sty e1, pp_dotdot, ppr sty e3]
    ppr sty (FromThenTo e1 e2 e3)
      = hcat [ppr sty e1, comma, space, ppr sty e2, pp_dotdot, ppr sty e3]

pp_dotdot = ptext SLIT(" .. ")
\end{code}
