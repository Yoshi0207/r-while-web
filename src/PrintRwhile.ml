(* pretty-printer generated by the BNF converter *)

open AbsRwhile
open Printf

(* We use string buffers for efficient string concatenation.
   A document takes a buffer and an indentation, has side effects on the buffer
   and returns a new indentation. The indentation argument indicates the level
   of indentation to be used if a new line has to be started (because of what is
   already in the buffer) *)
type doc = Buffer.t -> int -> int

let rec printTree (printer : int -> 'a -> doc) (tree : 'a) : string = 
    let buffer_init_size = 16 (* you may want to change this *)
    in let buffer = Buffer.create buffer_init_size
    in 
        let _ = printer 0 tree buffer 0 in (* discard return value *)
        Buffer.contents buffer

let indent_width = 4

let indent (i: int) : string = 
    let s = String.make (i+1) ' ' in
    String.set s 0 '\n';
    s

(* this render function is written for C-style languages, you may want to change it *)
let render (s : string) : doc = fun buf i -> 
    (* invariant: last char of the buffer is never whitespace *)
    let n = Buffer.length buf in
    let last = if n = 0 then None else Some (Buffer.nth buf (n-1)) in
    let whitespace = match last with
        None -> "" 
      | Some '{' -> indent i
      | Some '}' -> (match s with
            ";" -> ""
          | _ -> indent i)
      | Some ';' -> indent i
      | (Some '[') |  (Some '(') -> ""
      | Some _ -> (match s with
            "," | ")" | "]" -> ""
           | _ -> " ") in
    let newindent = match s with
        "{" -> i + indent_width
      | "}" -> i - indent_width
      | _ -> i in
    Buffer.add_string buf whitespace;
    Buffer.add_string buf s;
    newindent

let emptyDoc : doc = fun buf i -> i

let concatD (ds : doc list) : doc = fun buf i -> 
    List.fold_left (fun accIndent elemDoc -> elemDoc buf accIndent) (emptyDoc buf i) ds

let parenth (d:doc) : doc = concatD [render "("; d; render ")"]

let prPrec (i:int) (j:int) (d:doc) : doc = if j<i then parenth d else d


let rec prtChar (_:int) (c:char) : doc = render ("'" ^ Char.escaped c ^ "'")



let rec prtInt (_:int) (i:int) : doc = render (string_of_int i)



let rec prtFloat (_:int) (f:float) : doc = render (sprintf "%f" f)



let rec prtString (_:int) (s:string) : doc = render ("\"" ^ String.escaped s ^ "\"")




let rec prtRIdent _ (RIdent i) : doc = render i
and prtRIdentListBNFC i es : doc = match (i, es) with
    (_,[]) -> (concatD [])
  | (_,[x]) -> (concatD [prtRIdent 0 x])
  | (_,x::xs) -> (concatD [prtRIdent 0 x ; render "," ; prtRIdentListBNFC 0 xs])

let rec prtAtom _ (Atom i) : doc = render i



let rec prtProgram (i:int) (e:program) : doc = match e with
       Prog (macros, rident1, com, rident2) -> prPrec i 0 (concatD [prtMacroListBNFC 0 macros ; render "read" ; prtRIdent 0 rident1 ; render ";" ; prtCom 0 com ; render ";" ; render "write" ; prtRIdent 0 rident2])


and prtMacro (i:int) (e:macro) : doc = match e with
       Mac (rident, ridents, com) -> prPrec i 0 (concatD [render "macro" ; prtRIdent 0 rident ; render "(" ; prtRIdentListBNFC 0 ridents ; render ")" ; prtCom 0 com])

and prtMacroListBNFC i es : doc = match (i, es) with
    (_,[]) -> (concatD [])
  | (_,x::xs) -> (concatD [prtMacro 0 x ; prtMacroListBNFC 0 xs])
and prtCom (i:int) (e:com) : doc = match e with
       CSeq (com1, com2) -> prPrec i 0 (concatD [prtCom 0 com1 ; render ";" ; prtCom 1 com2])
  |    CMac (rident, ridents) -> prPrec i 1 (concatD [prtRIdent 0 rident ; render "(" ; prtRIdentListBNFC 0 ridents ; render ")"])
  |    CAss (rident, exp) -> prPrec i 1 (concatD [prtRIdent 0 rident ; render "^=" ; prtExp 0 exp])
  |    CRep (pat1, pat2) -> prPrec i 1 (concatD [prtPat 0 pat1 ; render "<=" ; prtPat 0 pat2])
  |    CCond (exp1, thenbranch, elsebranch, exp2) -> prPrec i 1 (concatD [render "if" ; prtExp 0 exp1 ; prtThenBranch 0 thenbranch ; prtElseBranch 0 elsebranch ; render "fi" ; prtExp 0 exp2])
  |    CLoop (exp1, dobranch, loopbranch, exp2) -> prPrec i 1 (concatD [render "from" ; prtExp 0 exp1 ; prtDoBranch 0 dobranch ; prtLoopBranch 0 loopbranch ; render "until" ; prtExp 0 exp2])
  |    CShow exp -> prPrec i 1 (concatD [render "show" ; prtExp 0 exp])


and prtThenBranch (i:int) (e:thenBranch) : doc = match e with
       BThen com -> prPrec i 0 (concatD [render "then" ; prtCom 0 com])
  |    BThenNone  -> prPrec i 0 (concatD [])


and prtElseBranch (i:int) (e:elseBranch) : doc = match e with
       BElse com -> prPrec i 0 (concatD [render "else" ; prtCom 0 com])
  |    BElseNone  -> prPrec i 0 (concatD [])


and prtDoBranch (i:int) (e:doBranch) : doc = match e with
       BDo com -> prPrec i 0 (concatD [render "do" ; prtCom 0 com])
  |    BDoNone  -> prPrec i 0 (concatD [])


and prtLoopBranch (i:int) (e:loopBranch) : doc = match e with
       BLoop com -> prPrec i 0 (concatD [render "loop" ; prtCom 0 com])
  |    BLoopNone  -> prPrec i 0 (concatD [])


and prtExp (i:int) (e:exp) : doc = match e with
       ECons (exp1, exp2) -> prPrec i 0 (concatD [render "cons" ; prtExp 1 exp1 ; prtExp 1 exp2])
  |    EHd exp -> prPrec i 0 (concatD [render "hd" ; prtExp 1 exp])
  |    ETl exp -> prPrec i 0 (concatD [render "tl" ; prtExp 1 exp])
  |    EEq (exp1, exp2) -> prPrec i 0 (concatD [render "=?" ; prtExp 1 exp1 ; prtExp 1 exp2])
  |    EVar variable -> prPrec i 1 (concatD [prtVariable 0 variable])
  |    EVal val_ -> prPrec i 1 (concatD [prtValT 0 val_])


and prtPat (i:int) (e:pat) : doc = match e with
       PCons (pat1, pat2) -> prPrec i 0 (concatD [render "cons" ; prtPat 1 pat1 ; prtPat 1 pat2])
  |    PVar variable -> prPrec i 1 (concatD [prtVariable 0 variable])
  |    PVal val_ -> prPrec i 1 (concatD [prtValT 0 val_])


and prtValT (i:int) (e:valT) : doc = match e with
       VNil  -> prPrec i 0 (concatD [render "nil"])
  |    VAtom atom -> prPrec i 0 (concatD [prtAtom 0 atom])
  |    VCons (val_1, val_2) -> prPrec i 0 (concatD [render "(" ; prtValT 0 val_1 ; render "." ; prtValT 0 val_2 ; render ")"])


and prtVariable (i:int) (e:variable) : doc = match e with
       Var rident -> prPrec i 0 (concatD [prtRIdent 0 rident])



