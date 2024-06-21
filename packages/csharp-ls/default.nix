{
  buildDotnetModule,
  dotnetCorePackages,
  fetchFromGitHub,
  lib,
}:
let
  version = "0.13.0";
in
buildDotnetModule rec {
  inherit version;
  pname = "csharp-ls";

  src = fetchFromGitHub {
    owner = "khaneliman";
    repo = "csharp-language-server";
    rev = "0a2d683cb41dd408bde4ffbb5d0f4107cd8af5cc";
    hash = "sha256-Uk3k15V56s9CdVPEiCVa0dnjcSBE4auNhgjhcQ/JZls=";
  };

  nugetDeps = ./deps.nix;

  packNupkg = true;

  projectFile = "csharp-language-server.sln";

  useDotnetFromEnv = true;

  executables = [ "csharp-ls" ];

  dotnet-sdk = dotnetCorePackages.sdk_8_0;
  dotnet-runtime = dotnetCorePackages.runtime_8_0;

  buildPhase = ''
    runHook preBuild

    dotnet build
    dotnet pack

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    dotnet tool install --add-source src/CSharpLanguageServer/nupkg/ --tool-path $out/lib/${pname} ${pname}

    # remove files that contain nix store paths to temp nuget sources we made
    find $out -name 'project.assets.json' -delete
    find $out -name '.nupkg.metadata' -delete

    runHook postInstall
  '';

  meta = with lib; {
    description = "Roslyn-based LSP language server for C#";
    mainProgram = "csharp-ls";
    homepage = "https://github.com/razzmatazz/csharp-language-server";
    changelog = "https://github.com/razzmatazz/csharp-language-server/releases/tag/v${version}";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
