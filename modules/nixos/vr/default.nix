{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    xrizer
    #opencomposite
  ];

  systemd.user.services.monado.environment = {
    STEAMVR_LH_ENABLE = "1";
    XRT_COMPOSITOR_COMPUTE = "1";
    U_PACING_APP_USE_MIN_FRAME_PERIOD = "1";
  };

  environment.sessionVariables = {
    PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
    #VR_OVERRIDE = "${pkgs.xrizer}/";
    XR_RUNTIME_JSON = "${pkgs.monado}/share/openxr/1/openxr_monado.json";
    # passing stuff to steam args
    NS_MONADO = "${pkgs.monado}";
    NS_XRIZER = "${pkgs.xrizer}";
    NS_OPENCOMPOSITE = "${pkgs.opencomposite}";
  };

  services = {
    ratbagd.enable = true;
    #wivrn = {
    #  enable = true;
    #  autoStart = true;
    #  steam.importOXRRuntimes = true;
    #  highPriority = true;
    #};
    monado = {
      enable = true;
      defaultRuntime = true;
      forceDefaultRuntime = true;
      highPriority = true;
    };
  };

  # https://wiki.nixos.org/wiki/VR#Patching_bubblewrap_to_allow_capabilities
  # https://github.com/containers/bubblewrap/issues/653
  #programs.steam.package = let
  #  bubblecaps = pkgs.bubblewrap
  #  .overrideAttrs (orig: {
  #    patches =
  #      (orig.patches or [])
  #      ++ [
  #        ./bubblewrap-caps.patch
  #      ];
  #  });
  #in
  #  pkgs.steam.override {
  #    buildFHSEnv = args: ((pkgs.buildFHSEnv.override {
  #        bubblewrap = bubblecaps;
  #      }) (args
  #        // {
  #          extraBwrapArgs = (args.extraBwrapArgs or []) ++ ["--cap-add CAP_SYS_NICE"];
  #        }));
  #  };
}
