{
  lib,
  stdenv,
  fetchSteam,
}:
stdenv.mkDerivation (finalAttrs: {
  name = "valheim-server";
  version = "1.0.15";
  src = fetchSteam {
    inherit (finalAttrs) name;
    appId = "896660";
    depotId = "896661";
    manifestId = "6686760496212527200";
    hash = "sha256-nfhqtCGvUW52iGcsBZ0wiOPZLUn0vgHezZ/GPrHaDRM=";
  };

  # Skip phases that don't apply to prebuilt binaries.
  dontBuild = true;
  dontConfigure = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r \
      *.so \
      *.debug \
      valheim_server.x86_64 \
      valheim_server_Data \
      $out

    chmod +x $out/valheim_server.x86_64

    runHook postInstall
  '';

  meta = with lib; {
    description = "Valheim dedicated server";
    homepage = "https://steamdb.info/app/896660/";
    changelog = "https://store.steampowered.com/news/app/892970?updates=true";
    sourceProvenance = with sourceTypes; [
      binaryBytecode
      binaryNativeCode
    ];
    license = licenses.unfree;
    maintainers = with maintainers; [ LaneDoesThings ];
    platforms = [ "x86_64-linux" ];
  };
})
