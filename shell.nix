with import <nixpkgs> {};
stdenv.mkDerivation rec {
  name = "moonbar";
  shellHook = ''
    export LD_LIBRARY_PATH=${pkgs.systemd.lib}/lib
  '';
}
