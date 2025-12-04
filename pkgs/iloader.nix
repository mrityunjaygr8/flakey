{
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  wrapGAppsHook3,
  webkitgtk_4_1,
  gtk3,
  openssl,
  libappindicator-gtk3,
  librsvg,
  libsoup_3,
  glib-networking,
  xdotool,
}: let
  pname = "iloader";
  version = "1.1.4";

  src = fetchurl {
    url = "https://github.com/nab138/iloader/releases/download/v${version}/iloader-linux-amd64.deb";
    sha256 = "sha256:898dcb5f8835536e0d0e88f024c8bad12cc71e04cc51f29541e9a1a17524e4f1";
  };
in
  stdenv.mkDerivation {
    inherit pname version src;

    nativeBuildInputs = [
      dpkg
      autoPatchelfHook
      wrapGAppsHook3
    ];

    buildInputs = [
      gtk3
      webkitgtk_4_1
      openssl
      libappindicator-gtk3
      librsvg
      libsoup_3
      glib-networking
      xdotool
    ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      dpkg -x $src $out
      cp -r $out/usr/share $out/share
      cp -r $out/usr/bin $out/bin
      rm -rf $out/usr
      runHook postInstall
    '';

    meta = {
      description = "User friendly sideloader";
      homepage = "https://github.com/nab138/iloader";
      platforms = ["x86_64-linux"];
    };
  }
