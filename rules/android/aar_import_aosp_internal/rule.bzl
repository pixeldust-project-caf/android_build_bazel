# Copyright (C) 2023 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""aar_import rule."""

load(":attrs.bzl", _ATTRS = "ATTRS")
load("@rules_android//rules/aar_import:impl.bzl", _impl = "impl")
load("@rules_android//rules/aar_import:rule.bzl", "RULE_DOC")

aar_import = rule(
    attrs = _ATTRS,
    fragments = ["android"],
    implementation = _impl,
    doc = RULE_DOC,
    provides = [
        AndroidIdeInfo,
        AndroidLibraryResourceClassJarProvider,
        AndroidNativeLibsInfo,
        JavaInfo,
    ],
    toolchains = ["@rules_android//toolchains/android:toolchain_type"],
)
