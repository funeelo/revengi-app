{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.cmake
    pkgs.pkg-config
    pkgs.gtk3
    pkgs.xz
    pkgs.cmake
    pkgs.gtk3
    pkgs.clang
    pkgs.ninja
    pkgs.libGLU
  ];
}
