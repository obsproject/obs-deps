import sys
import os
import re

import yaml


def main() -> int:
    if len(sys.argv) > 1:
        file_name = sys.argv[1]
    else:
        file_name = ".github/workflows/main.yml"
    try:
        with open(file_name) as workflow_file:
            yaml_data = yaml.load(workflow_file, Loader=yaml.FullLoader)

            global_env = yaml_data.get("env", {})
            jobs = yaml_data.get("jobs", {})

            for target_os in ["macos"]:
                build_script = f"./CI/build-deps-{target_os}.sh"
                environment_data = jobs.get(f"{target_os}-deps-build", {}).get(
                    "env", {}
                )

                filtered_data = {
                    key: value
                    for key, value in environment_data.items()
                    if key
                    not in [
                        "CACHE_REVISION",
                        "MACOSX_DEPLOYMENT_TARGET",
                        "MACOSX_DEPLOYMENT_TARGET_ARM64",
                        "MACOSX_DEPLOYMENT_TARGET_X86_64",
                        "FFMPEG_REVISION",
                        "BLOCKED_FORMULAS",
                    ]
                }

                # Use preserved item order in dicts with Py 3.7
                dependencies = dict.fromkeys(
                    [key.split("_")[0] for key in filtered_data.keys()]
                ).keys()
                dependency_strings = [
                    f"    \"{key.lower()} {environment_data.get(f'{key}_VERSION', '')}"
                    f" {environment_data.get(f'{key}_HASH', '')}\""
                    for key in dependencies
                ]

                try:
                    with open(build_script, "r+") as build_script_file:
                        script_content = build_script_file.read()

                        pattern = re.compile(
                            "REQUIRED_DEPS=\\(\n.+?\n\\)", re.MULTILINE | re.DOTALL
                        )

                        dependency_string = "\n".join(dependency_strings)
                        script_content = pattern.sub(
                            f"REQUIRED_DEPS=(\n{dependency_string}\n)", script_content
                        )

                        build_script_file.seek(0)
                        build_script_file.write(script_content)

                except FileNotFoundError as e:
                    print(e)

    except FileNotFoundError as e:
        print(e)

    return 0


# Run main function if not run as a module
if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("Program interrupted by user input")

        sys.exit(1)
