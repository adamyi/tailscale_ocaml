open! Core
open! Async

type t

val start
  :  ?dir:string
  -> ?hostname:string
  -> ?authkey:string
  -> ?control_url:string
  -> ?ephemeral:bool
  -> unit
  -> t Or_error.t Deferred.t

val serve_tcp
  :  t
  -> port:int
  -> handler:(Writer.t -> Reader.t -> unit Deferred.t)
  -> unit Or_error.t Deferred.t
