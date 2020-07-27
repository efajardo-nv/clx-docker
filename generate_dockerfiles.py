#!/usr/bin/env python3
"""
Python script to generate Dockerfiles
"""

import os
from datetime import datetime
from jinja2 import Environment, FileSystemLoader
import yaml

file_loader = FileSystemLoader("templates")
env = Environment(loader=file_loader, lstrip_blocks=True, trim_blocks=True)
OUTPUT_DIR = "generated-dockerfiles"


def load_settings():
    """Loads settings.yaml and sets default variables on necessary RAPIDS_LIBS entries"""
    with open("settings.yaml") as settings_file:
        settings = yaml.load(settings_file, Loader=yaml.FullLoader)
    # Set default RAPIDS_LIBS values
    for lib in settings["RAPIDS_LIBS"]:
        if "branch" not in lib.keys():
            lib["branch"] = f'branch-{settings["RAPIDS_VERSION"]}'
        if "update_submodules" not in lib.keys():
            lib["update_submodules"] = True
    return settings


def initialize_output_dir():
    """Creates or empties the OUTPUT_DIR directory"""
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
        return
    filelist = [f for f in os.listdir(OUTPUT_DIR) if f.endswith(".Dockerfile")]
    for dockerfile in filelist:
        os.remove(os.path.join(OUTPUT_DIR, dockerfile))
    return


def main():
    """Generates Dockerfiles using Jinja2"""
    initialize_output_dir()
    settings = load_settings()
    for docker_os in ["centos7", "ubuntu18.04"]:
        # for image_type in ["Base", "Devel", "Runtime", "Quick"]:
        for image_type in ["Base", "Devel", "Runtime"]:
            dockerfile_name = f"{docker_os}-{image_type.lower()}.Dockerfile"
            template = env.get_template(f"{image_type}.dockerfile.j2")
            output = template.render(
                os=docker_os, image_type=image_type, now=datetime.utcnow(), **settings,
            )
            with open(f"{OUTPUT_DIR}/{dockerfile_name}", "w") as dockerfile:
                dockerfile.write(output)
    print(f"Dockerfiles successfully written to the '{OUTPUT_DIR}' directory.")


if __name__ == "__main__":
    main()
