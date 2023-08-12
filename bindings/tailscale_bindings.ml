open! Ctypes

module C (F : Ctypes.FOREIGN) = struct
  open F

  let tailscale_new = foreign "tailscale_new" (void @-> returning int)
  let tailscale_start = foreign "tailscale_start" (int @-> returning int)
  let tailscale_up = foreign "tailscale_up" (int @-> returning int)
  let tailscale_close = foreign "tailscale_close" (int @-> returning int)
  let tailscale_set_dir = foreign "tailscale_set_dir" (int @-> string @-> returning int)

  let tailscale_set_hostname =
    foreign "tailscale_set_hostname" (int @-> string @-> returning int)
  ;;

  let tailscale_set_authkey =
    foreign "tailscale_set_authkey" (int @-> string @-> returning int)
  ;;

  let tailscale_set_control_url =
    foreign "tailscale_set_control_url" (int @-> string @-> returning int)
  ;;

  let tailscale_set_ephemeral =
    foreign "tailscale_set_ephemeral" (int @-> int @-> returning int)
  ;;

  let tailscale_set_logfd = foreign "tailscale_set_logfd" (int @-> int @-> returning int)

  let tailscale_listen =
    foreign "tailscale_listen" (int @-> string @-> string @-> ptr int @-> returning int)
  ;;

  let tailscale_accept = foreign "tailscale_accept" (int @-> ptr int @-> returning int)
end
