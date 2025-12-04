{
  appimageTools,
  fetchurl,
}: let
  pname = "iloader";
  version = "1.1.4";

  src = fetchurl {
    url = "https://github.com/nab138/iloader/releases/download/v${version}/iloader-linux-amd64.AppImage";
    hash = "";
  };
in
  appimageTools.wrapType2 {inherit pname version src;}
