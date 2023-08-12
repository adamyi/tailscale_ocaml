open! Core
open! Async
module Raw = Tailscale_bindings.C (Tailscale_generated)

type t = int

let wrap_return ret =
  if ret = 0
  then Ok ()
  else (* TODO: Get error *) error_s [%message "Tailscale operation failed" (ret : int)]
;;

let start ?dir ?hostname ?authkey ?control_url ?ephemeral () =
  let open Deferred.Or_error.Let_syntax in
  let t = Raw.tailscale_new () in
  let maybe_set f value ~map =
    match value with
    | Some value -> map value |> f t |> wrap_return |> Deferred.return
    | None -> return ()
  in
  let%bind () = maybe_set Raw.tailscale_set_dir dir ~map:Fn.id in
  let%bind () = maybe_set Raw.tailscale_set_hostname hostname ~map:Fn.id in
  let%bind () = maybe_set Raw.tailscale_set_authkey authkey ~map:Fn.id in
  let%bind () = maybe_set Raw.tailscale_set_control_url control_url ~map:Fn.id in
  let%bind () = maybe_set Raw.tailscale_set_ephemeral ephemeral ~map:Bool.to_int in
  let%map () = In_thread.run (fun () -> Raw.tailscale_up t |> wrap_return) in
  t
;;

module Expert = struct
  module Listener = struct
    type t = int

    let accept t =
      let open Deferred.Or_error.Let_syntax in
      let fd_ptr = Ctypes.(allocate int 0) in
      let%map () =
        In_thread.run (fun () -> Raw.tailscale_accept t fd_ptr |> wrap_return)
      in
      let fd = Ctypes.( !@ ) fd_ptr |> Core_unix.File_descr.of_int in
      (* TODO: Figure out a way to get client address *)
      Async_unix.Fd.create Fifo fd (Info.create_s [%message "Tailscale accepted"])
    ;;
  end

  let listen_tcp t ~port : Listener.t Or_error.t Deferred.t =
    let open Deferred.Or_error.Let_syntax in
    let listener_ptr = Ctypes.(allocate int 0) in
    let%map () =
      In_thread.run (fun () ->
        Raw.tailscale_listen t "tcp" [%string ":%{port#Int}"] listener_ptr |> wrap_return)
    in
    Ctypes.( !@ ) listener_ptr
  ;;
end

let handle_conn fd handler =
  let writer = Writer.create fd in
  let reader = Reader.create fd in
  Monitor.protect
    (fun () -> handler writer reader)
    ~name:"Tailscale TCP connection handler"
    ~finally:(fun () ->
      let%bind () = Reader.close reader in
      Writer.close writer)
;;

let serve_tcp t ~port ~handler =
  let open Deferred.Or_error.Let_syntax in
  let%map listener = Expert.listen_tcp t ~port in
  (* TODO: Limit number of concurrent connections. *)
  (* TODO: Offer way to shutdown server. Perhaps create [Server.t]. *)
  Deferred.Or_error.repeat_until_finished () (fun () ->
    let%map fd = Expert.Listener.accept listener in
    handle_conn fd handler |> don't_wait_for;
    `Repeat ())
  |> Deferred.Or_error.ok_exn
  |> don't_wait_for
;;
