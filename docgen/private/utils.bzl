"""Utility functions for documentation processing."""

load("@bazel_lib//lib:copy_to_directory.bzl", "copy_to_directory_bin_action")
load("@bazel_lib//lib:paths.bzl", "to_repository_relative_path")

UNIQUE_FOLDER_NAME = "_bazel_docs"

def to_package_relative_path(file):
    """Returns the path of a file relative to its owning package.

    copy_to_directory strips the package prefix from files, so nav paths
    and config references must use package-relative paths to match.

    Args:
        file: A File object.

    Returns:
        The file's path relative to its owning package.
    """
    repo_path = to_repository_relative_path(file)
    pkg = file.owner.package if file.owner else ""
    if pkg and repo_path.startswith(pkg + "/"):
        return repo_path[len(pkg) + 1:]
    return repo_path

def collect_inputs(ctx, root = ""):
    """Collects and organizes documentation inputs into a directory structure.

    Args:
        ctx: Rule context
        root: Optional root navigation folder

    Returns:
        Tuple of (docs_folder, config_file)
    """
    docs_folder_path = ctx.label.name + "/" + ctx.attr.docs_dir
    docs_folder = ctx.actions.declare_directory(docs_folder_path)

    copy_to_directory_bin = ctx.toolchains["@bazel_lib//lib:copy_to_directory_toolchain_type"].copy_to_directory_info.bin

    replace_prefixes = {
        "**/{}".format(UNIQUE_FOLDER_NAME): "",
    }

    if (root != ""):
        replace_prefixes["**/{}".format(root)] = ""

    # Copy docs
    copy_to_directory_bin_action(
        ctx = ctx,
        copy_to_directory_bin = copy_to_directory_bin,
        name = "_" + ctx.label.name + "_docs",
        files = ctx.files.docs + ctx.files.data + [ctx.file.config],
        dst = docs_folder,
        replace_prefixes = replace_prefixes,
        include_external_repositories = ["*"],
        allow_overwrites = True,
    )

    return docs_folder
