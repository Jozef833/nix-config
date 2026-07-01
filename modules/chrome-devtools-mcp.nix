_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.chrome-devtools-mcp = pkgs.callPackage (
        {
          fetchurl,
          lib,
          makeWrapper,
          nodejs,
          stdenv,
        }:
        stdenv.mkDerivation (finalAttrs: {
          dontBuild = true;
          installPhase = ''
            runHook preInstall
            mkdir -p $out/lib/node_modules/chrome-devtools-mcp $out/bin
            cp -r . $out/lib/node_modules/chrome-devtools-mcp
            makeWrapper ${nodejs}/bin/node $out/bin/chrome-devtools-mcp \
              --add-flags "$out/lib/node_modules/chrome-devtools-mcp/build/src/bin/chrome-devtools-mcp.js"
            makeWrapper ${nodejs}/bin/node $out/bin/chrome-devtools \
              --add-flags "$out/lib/node_modules/chrome-devtools-mcp/build/src/bin/chrome-devtools.js"
            runHook postInstall
          '';
          meta = {
            description = "Chrome DevTools for coding agents (MCP server + CLI)";
            homepage = "https://github.com/ChromeDevTools/chrome-devtools-mcp";
            license = lib.licenses.asl20;
            mainProgram = "chrome-devtools-mcp";
            platforms = lib.platforms.all;
          };
          nativeBuildInputs = [ makeWrapper ];
          pname = "chrome-devtools-mcp";
          src = fetchurl {
            url = "https://registry.npmjs.org/chrome-devtools-mcp/-/chrome-devtools-mcp-${finalAttrs.version}.tgz";
            hash = "sha256-0tRNmnPaSZIILB8WhfvEoTaUF2cNSplI0w7L70FBmZk=";
          };
          version = "1.4.0";
        })
      ) { };
    };
}
