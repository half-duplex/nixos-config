{
  pname,
  pkgs,
}: let
  inherit (pkgs) fetchFromGitHub fetchPnpmDeps lib pnpmConfigHook stdenv;
  version = "2.2.2";
in
  stdenv.mkDerivation (finalAttrs: {
    inherit pname version;

    meta = {
      description = "Discord app for managing and sending custom stickers";
      homepage = "https://fantastick.went.tf/";
      license = lib.licenses.mit;
    };

    src = fetchFromGitHub {
      owner = "WentTheFox";
      repo = "Fantastick";
      rev = "v" + version;
      hash = "sha256-IpU5tpnncZoNbcBuITlp97N17jad6TorIIdSdAK2ocE=";
    };

    pnpmDeps = fetchPnpmDeps {
      inherit (finalAttrs) pname version src;
      pnpm = pkgs.pnpm;
      fetcherVersion = 5;
      hash = "sha256-aGUv+aVaKdhoGVtVSezKi7eKPqTsN412YuqpsXDPxkc=";
    };

    nativeBuildInputs = with pkgs; [
      nodejs
      pnpm
      pnpmConfigHook
      pnpmBuildHook
      prisma
    ];

    buildPhase = with pkgs; ''
      runHook preBuild

      export PRISMA_SCHEMA_ENGINE_BINARY="${prisma-engines}/bin/schema-engine"
      export PRISMA_QUERY_ENGINE_BINARY="${prisma-engines}/bin/query-engine"
      export PRISMA_QUERY_ENGINE_LIBRARY="${prisma-engines}/lib/libquery_engine.node"
      export PRISMA_FMT_BINARY="${prisma-engines}/bin/prisma-fmt"

      pnpm run prepare # for typia hooks
      prisma generate
      pnpmBuildPhase
      # This removes prisma/config, which is needed at deploy time
      #pnpm prune --prod --ignore-scripts

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/src"
      cp -r prisma.config.ts prisma/ node_modules/ build/ "$out/"
      cp -r src/locales "$out/src/"
      rm "$out/node_modules/.modules.yaml" "$out/node_modules/.pnpm-workspace-state-v1.json"

      runHook postInstall
    '';
  })
