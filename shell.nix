{ pkgs ? import <nixpkgs> { } }:
with pkgs; mkShell {
  buildInputs = [ sqlite lean4 clang ];
}
