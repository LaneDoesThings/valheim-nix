{
  lib,
  stdenv,
  fetchSteam,
}:
stdenv.mkDerivation (finalAttrs: {
  name = "valheim-server";
  version = "1.0";
  src = fetchSteam {
    inherit (finalAttrs) name;
    appId = "896660";
    depotId = "896661";
    manifestId = "6242541463332331733";
    hash = "sha256-XuFpPUhdUPY1wq7Y3EEwhUtv4L+hENT0aV/Zd8BWg1M=";
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
