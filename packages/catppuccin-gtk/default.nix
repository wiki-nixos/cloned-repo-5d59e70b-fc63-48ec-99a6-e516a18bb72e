{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  gtk3,
  git,
  python3,
  sassc,
  accents ? [ "blue" ],
  size ? "standard",
  tweaks ? [ ],
  variant ? "macchiato",
}:
let
  pname = "catppuccin-gtk";
  version = "1.0.3";
in

stdenvNoCC.mkDerivation {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "gtk";
    rev = "v${version}";
    fetchSubmodules = true;
    hash = "sha256-q5/VcFsm3vNEw55zq/vcM11eo456SYE5TQA3g2VQjGc=";
  };

  nativeBuildInputs = [
    gtk3
    sassc
    # git is needed here since "git apply" is being used for patches
    # see <https://github.com/catppuccin/gtk/blob/4173b70b910bbb3a42ef0e329b3e98d53cef3350/build.py#L465>
    git
    (python3.withPackages (ps: [ ps.catppuccin ]))
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/themes

    python3 build.py ${variant} \
      --accent ${builtins.toString accents} \
      ${lib.optionalString (size != [ ]) "--size " + size} \
      ${lib.optionalString (tweaks != [ ]) "--tweaks " + builtins.toString tweaks} \
      --dest $out/share/themes

    runHook postInstall
  '';
}
