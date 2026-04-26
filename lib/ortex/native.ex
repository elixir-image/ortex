defmodule Ortex.Native do
  @moduledoc false

  mix_config = Mix.Project.config()
  version = mix_config[:version]
  github_url = mix_config[:package][:links]["GitHub"]

  # When set to "1" or "true", forces a source build via Rustler instead
  # of downloading a precompiled NIF. Useful when the precompiled
  # artifact is unavailable for the user's target tuple, or when
  # debugging the NIF build itself.
  force_build = System.get_env("ORTEX_BUILD") in ["1", "true"]

  # The set of target triples for which we publish prebuilt NIF
  # artifacts. Targets not in this list fall through to source build
  # automatically — RustlerPrecompiled handles that fallback.
  precompiled_targets = ~w(
    aarch64-apple-darwin
    x86_64-apple-darwin
    x86_64-unknown-linux-gnu
    aarch64-unknown-linux-gnu
    x86_64-pc-windows-msvc
  )

  if force_build do
    # Source-build path. The `ort` Rust crate downloads the
    # `libonnxruntime` shared library during `cargo build`, so we have
    # to compile the crate explicitly *before* `use Rustler`, then copy
    # the downloaded shared library into `priv/native/` where the NIF's
    # rpath will find it. This is the same dance that has shipped in
    # Ortex since 0.1.x — kept intact for the source-build path only.
    @rustler_version Application.spec(:rustler, :vsn) |> to_string() |> Version.parse!()

    if Version.compare(@rustler_version, "0.30.0") in [:gt, :eq] do
      Rustler.Compiler.compile_crate(:ortex, Application.compile_env(:ortex, __MODULE__, []),
        otp_app: :ortex,
        crate: :ortex
      )
    else
      Rustler.Compiler.compile_crate(__MODULE__, otp_app: :ortex, crate: :ortex)
    end

    Ortex.Util.copy_ort_libs()

    use Rustler,
      otp_app: :ortex,
      crate: :ortex,
      skip_compilation?: true
  else
    # Precompiled path. RustlerPrecompiled downloads the matching
    # tarball from the project's GitHub release and extracts it into
    # `priv/native/`. Each tarball contains both `libortex.<ext>` (the
    # NIF) and `libonnxruntime.<ext>` (the runtime it links against),
    # so no separate `copy_ort_libs/0` step is required on this path.
    use RustlerPrecompiled,
      otp_app: :ortex,
      crate: :ortex,
      version: version,
      base_url: "#{github_url}/releases/download/v#{version}",
      targets: precompiled_targets,
      force_build: force_build,
      nif_versions: ["2.16", "2.17"]
  end

  # NIF dummies — required so calls compile cleanly before the NIF
  # is loaded. Real implementations are provided by the loaded NIF.
  def init(_model_path, _execution_providers, _optimization_level),
    do: :erlang.nif_error(:nif_not_loaded)

  def run(_model, _inputs), do: :erlang.nif_error(:nif_not_loaded)
  def from_binary(_bin, _shape, _type), do: :erlang.nif_error(:nif_not_loaded)
  def to_binary(_reference, _bits, _limit), do: :erlang.nif_error(:nif_not_loaded)
  def show_session(_model), do: :erlang.nif_error(:nif_not_loaded)

  def slice(_tensor, _start_indicies, _lengths, _strides),
    do: :erlang.nif_error(:nif_not_loaded)

  def reshape(_tensor, _shape), do: :erlang.nif_error(:nif_not_loaded)

  def concatenate(_tensors_refs, _type, _axis), do: :erlang.nif_error(:nif_not_loaded)
end
