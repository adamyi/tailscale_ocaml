open! Core
open! Async
open! Ctypes

let echo_server =
  Async.Command.async_or_error
    ~summary:"A TCP server that prints back requests"
    (let%map_open.Command () = return ()
     and port =
       flag_optional_with_default_doc
         "port"
         int
         [%sexp_of: int]
         ~default:1999
         ~doc:"PORT Port number to listen on within Tailscale network"
     in
     fun () ->
       let open Deferred.Or_error.Let_syntax in
       let%bind ts = Tailscale.start () ~ephemeral:true in
       let%bind () =
         Tailscale.serve_tcp ts ~port ~handler:(fun writer reader ->
           Reader.lines reader |> Pipe.iter_without_pushback ~f:(Writer.write_line writer))
       in
       Deferred.never ())
;;

let command =
  Command.group ~summary:"Various examples of libtailscale" [ "echo-server", echo_server ]
;;

let () = Command_unix.run command
