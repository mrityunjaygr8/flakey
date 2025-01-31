{ stdenv
, rustPlatform
, fetchFromGitHub
, lib
, pkg-config
, dbus
, xorg
# , inputs
# , callPackage
# , fetchurl
# , nixosTests
# , commandLineArgs ? ""
# , useVSCodeRipgrep ? stdenv.hostPlatform.isLinux
, ...
}: rustPlatform.buildRustPackage rec {
  pname = "goose";
  version = "1.0.3";

  src = fetchFromGitHub {
    owner = "block";
    repo = "goose";
    rev = "v${version}";
    hash = "sha256-82IhLhw0TdaMh21phBxcUZ5JI5xOXb0DrwnBmPwyfAQ=";
  };

  cargoHash = "sha256-Sfks9NkADsHkTe9Uz5HipxR7bqC9OCKua0yRiuMECd4=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    dbus
    xorg.libxcb.dev
  ];


  meta = with lib; {
    description = "an open-source, extensible AI agent that goes beyond code suggestions - install, execute, edit, and test with any LLM";
    homepage = "https://github.com/block/goose";
    license = with licenses; [
      asl20 # or
    ];
    mainProgram = "goose";
    maintainers = with maintainers; [
      mrityunjaygr8
    ];
  };
}
