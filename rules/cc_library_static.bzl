load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cpp_toolchain")

def cc_library_static(
        name,
        srcs = [],
        deps = [],
        hdrs = [],
        copts = [],
        includes = [],
        native_bridge_supported = False, # TODO: not supported yet.
        **kwargs):
    "Bazel macro to correspond with the cc_library_static Soong module."
    mainlib_name = "%s_mainlib" % name

    # Silently drop these attributes for now:
    # - native_bridge_supported
    native.cc_library(
        name = mainlib_name,
        srcs = srcs,
        hdrs = hdrs,
        deps = deps,
        copts = copts,
        includes = includes,
        **kwargs
    )

    # Safeguard target to handle the no-srcs no-deps case.
    # With no-srcs no-deps, this returns a stub. Otherwise, it's a passthrough no-op.
    _empty_library_safeguard(
        name = name,
        main_target = mainlib_name
    )

def _empty_library_safeguard_impl(ctx):
  if len(ctx.files.main_target) > 0:
      # This safeguard is a no-op, as a library was generated by the main target.
      return [ctx.attr.main_target[CcInfo], ctx.attr.main_target[DefaultInfo]]

  # The main library is empty; link a stub and propagate it to match Soong behavior.
  cc_toolchain = find_cpp_toolchain(ctx)
  CPP_LINK_STATIC_LIBRARY_ACTION_NAME = "c++-link-static-library"
  feature_configuration = cc_common.configure_features(
      ctx = ctx,
      cc_toolchain = cc_toolchain,
      requested_features = ctx.features,
      unsupported_features = ctx.disabled_features + ["linker_flags"],
  )

  output_file = ctx.actions.declare_file(ctx.label.name + ".a")
  linker_input = cc_common.create_linker_input(
      owner = ctx.label,
      libraries = depset(direct = [
          cc_common.create_library_to_link(
              actions = ctx.actions,
              feature_configuration = feature_configuration,
              cc_toolchain = cc_toolchain,
              static_library = output_file,
          ),
      ]),
  )
  compilation_context = cc_common.create_compilation_context()
  linking_context = cc_common.create_linking_context(linker_inputs = depset(direct = [linker_input]))

  archiver_path = cc_common.get_tool_for_action(
      feature_configuration = feature_configuration,
      action_name = CPP_LINK_STATIC_LIBRARY_ACTION_NAME,
  )
  archiver_variables = cc_common.create_link_variables(
    feature_configuration = feature_configuration,
    cc_toolchain = cc_toolchain,
    output_file = output_file.path,
    is_using_linker = False,
  )
  command_line = cc_common.get_memory_inefficient_command_line(
    feature_configuration = feature_configuration,
    action_name = CPP_LINK_STATIC_LIBRARY_ACTION_NAME,
    variables = archiver_variables,
  )
  args = ctx.actions.args()
  args.add_all(command_line)

  ctx.actions.run(
    executable = archiver_path,
    arguments = [args],
    inputs = depset(
        transitive = [
            cc_toolchain.all_files,
        ],
    ),
    outputs = [output_file],
  )
  cc_info = cc_common.merge_cc_infos(cc_infos = [
      ctx.attr.main_target[CcInfo],
      CcInfo(compilation_context = compilation_context, linking_context = linking_context),
  ])
  return [
      DefaultInfo(files = depset([output_file])),
      cc_info,
  ]

# A rule which depends on a single cc_library target. If the cc_library target
# has no outputs (indicating that it has no srcs or deps), then this safeguard
# rule creates a single stub .a file using llvm-ar. This mimics Soong's behavior
# in this regard. Otherwise, this safeguard is a simple passthrough for the providers
# of the cc_library.
_empty_library_safeguard = rule(
    implementation = _empty_library_safeguard_impl,
    attrs = {
        "main_target": attr.label(providers=[CcInfo]),
        "_cc_toolchain": attr.label(
            default = Label("@local_config_cc//:toolchain"),
            providers = [cc_common.CcToolchainInfo],
        ),
    },
    toolchains = ["@bazel_tools//tools/cpp:toolchain_type"],
    fragments = ["cpp"],
)

