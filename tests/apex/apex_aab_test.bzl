# Copyright (C) 2022 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

load("//build/bazel/rules/apex:apex_aab.bzl", "apex_aab")

def apex_aab_test(name, apex, golden):
    """Diff the .aab generated by Bazel and Soong"""

    aab_name = name + "_apex_aab"
    apex_aab(
        name = aab_name,
        mainline_module = apex,
    )

    native.sh_library(
        name = name + "_wrapper_sh_lib",
        data = [
            ":" + aab_name,
            golden,
        ],
    )

    args = [
        "$(location //build/bazel/tests/apex:" + aab_name + ")",
        "$(location %s)" % golden,
    ]

    native.sh_test(
        name = name,
        srcs = ["apex_aab_test.sh"],
        deps = ["@bazel_tools//tools/bash/runfiles"],
        data = [
            ":" + name + "_wrapper_sh_lib",
            "@bazel_tools//tools/zip:zipper",
            ":" + aab_name,
            golden,
        ],
        args = args,
        target_compatible_with = ["//build/bazel/platforms/os:android"],
    )
