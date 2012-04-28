exception Error

open Event
open Boardstuffs
open Boardcomp
open Graphics

module type BOARD =
sig 
    (* Defines the type of the board *)
	type board

    (* Returns an empty board *)
	val empty : board

    (* Returns the color of a particular index *)
	val get : board -> index -> occupied

    (** Inserts a piece on the board of the color specified by the board *)
	val insert : board -> index -> board

    (** Inserts a piece on the board of the color specified by the user *)
	val insertspecial : board -> index -> occupied -> board

    (* Determines if the board has a winning configuration *)
	val isWin : board -> occupied option

    (* Gets the threats of the board *)
	val getThreats : board -> threat list

    (* Determines if the board has a win next turn *)
    val nextWin : board -> index option

    (* Draws the pieces *)
	val indices : board -> unit

end

(** The 4 BoardComps used by BOARD **)
module HorizontalBoard = BoardComp (HorizontalBoardArg)
module VerticalBoard = BoardComp (VerticalBoardArg)
module DiagRightBoard = BoardComp (DiagRightBoardArg)
module DiagLeftBoard = BoardComp (DiagLeftBoardArg)

(** Module for describing the entire board **)
module Myboard : BOARD =
struct

	(**Board will be an array of pieces, 4 miniboards, and who's turn it is **)
	type board = occupied*(occupied list list)*(HorizontalBoard.boardcomp)*
                        (VerticalBoard.boardcomp)*(DiagRightBoard.boardcomp)*
                        (DiagLeftBoard.boardcomp)

  	let empty : board = 
        let buildEmptyBoard () = 
            let rec build_board n b = match n with
                |0 -> b
                |_ -> (let rec build_row m r = match m with
                    |0 -> r
                    |_ -> build_row (m-1) (Unocc::r)
                    in build_board (n-1) ((build_row world_size [])::b ) )
            in(build_board world_size [])
        in let piecearray = buildEmptyBoard () in
  		let horboard = HorizontalBoard.empty in
  		let verboard = VerticalBoard.empty in
  		let dgrboard = DiagRightBoard.empty in
  		let dglboard = DiagLeftBoard.empty in
		(Black,piecearray,horboard,verboard,dgrboard,dglboard)

  	let get (b:board) ((x,y):index) : occupied = 
  		let (_,pa,_,_,_,_) = b in
      List.nth (List.nth pa x) y

  	let insert (b:board) (i:index) : board = 
  		let (p,pa,h,v,dr,dl) = b in
    	match (HorizontalBoard.insert h i p, VerticalBoard.insert v i p, 
          DiagRightBoard.insert dr i p, DiagLeftBoard.insert dl i p) with
        	|(Some h1,Some v1,Some dr1,Some dl1) -> 
        		(let newPieceArray = VerticalBoard.getPieceArray v1 in 
        			(if p = Black
        			 then (White,newPieceArray,h1,v1,dr1,dl1)
        			 else (Black,newPieceArray,h1,v1,dr1,dl1)) )
        	|_ -> b


    let insertspecial (b:board) (i:index) (c:occupied): board = 
  		let (p,pa,h,v,dr,dl) = b in
      match (HorizontalBoard.insert h i c, VerticalBoard.insert v i c, 
          DiagRightBoard.insert dr i c, DiagLeftBoard.insert dl i c) with
          |(Some h1,Some v1,Some dr1,Some dl1) -> 
            (let newPieceArray = VerticalBoard.getPieceArray v1 in 
              (p,newPieceArray,h1,v1,dr1,dl1)) 
          |_ -> b

    let isWin (b:board) : occupied option =
    	let (_,_,h,v,dr,dl) = b in
        match (HorizontalBoard.isWin h, VerticalBoard.isWin v, 
        DiagRightBoard.isWin dr, DiagLeftBoard.isWin dl) with
            |(None,None,None,None) -> None
            |(Some s,_,_,_) -> Some s
            |(_,Some s,_,_) -> Some s
            |(_,_,Some s,_) -> Some s
            |(_,_,_,Some s) -> Some s

    let getThreats (b:board) : threat list = 
        let (_,_,h,v,dr,dl) = b in
        (HorizontalBoard.getThreats h)@(VerticalBoard.getThreats v)@    
        (DiagRightBoard.getThreats dr)@(DiagLeftBoard.getThreats dl)

    let nextWin (b:board) : index option =
        let (_,_,h,v,dr,dl) = b in
        match HorizontalBoard.nextWin h with
            |Some s -> Some s
            |None -> match VerticalBoard.nextWin v with
                |Some s -> Some s
                |None -> match DiagRightBoard.nextWin dr with
                    |Some s -> Some s
                    |None -> DiagLeftBoard.nextWin dl

    (************************************)
    (*** Helper functions for indices ***)
    (************************************)

    (* Draws a circle *)
    let circle ((x,y):int*int) (width:int) (height:int)
             (bg:Graphics.color) : unit =
        Graphics.set_color bg ;
        Graphics.fill_circle ((x+2)*width) ((y+2)*height) 
                         (min width height / 2) 

    (* Draws a different color circle depending on the color of the piece *)
    let draw (occ: occupied) (i: index) = match occ with
        |Black -> circle i obj_width obj_width Graphics.black
        |White -> circle i obj_width obj_width Graphics.white
        |Unocc -> ()

    (* Draws a row *)
    let rec indices_row (lst: occupied list) (r: int) (n:int) = 
        match lst with
            |[] -> ()
            |hd::tl -> draw hd (r,n); indices_row tl r (n+1)

    (*********************************)
    (*********************************)

    (** Call a function for all pieces in the world. *)
    let indices (b:board) : unit =
        let (_,pa,_,_,_,_) = b in
        let rec traverseRows rows n = match rows with
            |[] -> ()
            |hd::tl -> indices_row hd n 0; traverseRows tl (n+1)
    in traverseRows pa 0
  
end
