{ pkgs ? import <nixpkgs> { } }:

let
  unstable = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/ef355dde3c80e7ee30aa65aa5bf76e0b1b00bcc2.tar.gz") {};
in
pkgs.stdenv.mkDerivation {
  pname = "kotlin-editor";
  version = "0.0.1";

  buildInputs = with pkgs; [
    kotlin
    swift
  ];

  nativeBuildInputs = [
    unstable.godot_4
  ];

  src = ./.;
}
