let () =
  let fmt file = Format.formatter_of_out_channel (open_out file) in
  let fmt_c = fmt "tailscale_stubs.c" in
  Format.fprintf fmt_c {|#include "tailscale.h"@.|};
  Cstubs.write_c
    ~concurrency:Cstubs.unlocked
    fmt_c
    ~prefix:"caml_"
    (module Tailscale_bindings.C);
  let fmt_ml = fmt "tailscale_generated.ml" in
  Cstubs.write_ml fmt_ml ~prefix:"caml_" (module Tailscale_bindings.C);
  flush_all ()
;;
