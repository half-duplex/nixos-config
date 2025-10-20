{lib, ...}: let
  inherit (builtins) filter isString mapAttrs;
  inherit (lib.attrsets) mapAttrsToList recursiveUpdate;
  inherit (lib.lists) toList;
  inherit (lib.strings) concatStringsSep toJSON;

  nginxDefaultHeaders = {
    Content-Security-Policy = {
      default-src = "'self'";
      frame-ancestors = "'none'";
    };
    Strict-Transport-Security = {
      max-age = 31536000;
      includeSubdomains = true;
      preload = true;
    };
    X-Content-Type-Options = "nosniff";
    Referrer-Policy = "same-origin";
    Permissions-Policy = {
      join-ad-interest-group = null;
      run-ad-auction = null;
      interest-cohort = null;
    };
  };

  # https://datatracker.ietf.org/doc/html/rfc8941#dictionary
  # probably doesn't handle =false properly?
  buildRFC8941Dictionary = data:
    concatStringsSep "," (
      mapAttrsToList (
        key: value:
          if value == null
          then "${key}=()"
          else if value == true
          then key
          else if isString value
          then "${key}=${toString value}"
          else "${key}=(${concatStringsSep " " (toString value)})"
      )
      data
    );

  nginxHeaderBuilders = {
    Content-Security-Policy = headerValue:
      concatStringsSep "; " (
        mapAttrsToList (
          srcType: sources: "${srcType} ${concatStringsSep " " (toList sources)}"
        )
        headerValue
      );

    Permissions-Policy = buildRFC8941Dictionary;

    Strict-Transport-Security = headerValue:
      concatStringsSep "; " (
        filter (i: i != null) (
          mapAttrsToList (
            key: value:
              if value == null || value == false
              then null
              else if value == true
              then "${key}"
              else "${key}=${toString value}"
          )
          headerValue
        )
      );

    default = v: concatStringsSep " " (toList v);
  };

  buildHeader = name: nginxHeaderBuilders.${name} or nginxHeaderBuilders.default;
in {
  nginxHeaders = headers:
    concatStringsSep "\n" (
      mapAttrsToList (name: value: "add_header ${name} ${toJSON value} always;") (
        mapAttrs buildHeader (recursiveUpdate nginxDefaultHeaders headers)
      )
    );
}
