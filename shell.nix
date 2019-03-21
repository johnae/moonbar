with import <nixpkgs> {};
stdenv.mkDerivation rec {
  name = "moonbar";
  buildInputs = [
    curl
    jq
    iw
    gnugrep
    gawk
    gsimplecal
    bind
    acpi
    notify-desktop
    pulseaudio
  ];
  shellHook = ''
    export LD_LIBRARY_PATH=${pkgs.systemd.lib}/lib
  '';
}
