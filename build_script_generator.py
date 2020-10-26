#!/usr/bin/env python3

import sys
import os
import subprocess
import uuid
import re

from collections import OrderedDict

import yaml

BLUEPRINT = {
    'windows': '',
    'ubuntu': '''build_{step_id}() {{
    step "{dependency}"
    trap "caught_error '{dependency}'" ERR
    ensure_dir {working_directory}

{script}
}}
''',
    'macos': '''build_{step_id}() {{
    step "{dependency}"
    trap "caught_error '{dependency}'" ERR
    ensure_dir {working_directory}

{script}
}}
''',
}

def un_indent(match):
    head = f'<<{match.group(1)} {match.group(2)}'
    unindented = '\n'.join([re.sub(r'^\s+(.+)$', '\\1', line) for line in match.group(3).splitlines()])

    fixed = f'{head}\n{unindented}\n{match.group(1)}'
    return fixed

def parse_macos_job(job_data, template, step_template, global_env):

    find_setenv_pattern = re.compile('echo "(.+?)=(.+?)" >> \$GITHUB_ENV')
    find_env_pattern = re.compile('\\${{ env.(.+?) }}')
    find_heredoc_pattern = re.compile('<<(.+?) (.+?)?\n(.+?)\\1', re.MULTILINE|re.DOTALL)
    # current_path = os.path.realpath('.')
    current_path = "${BASE_DIR}"
    environment = global_env
    environment.update(job_data.get('env', {}))
    environment.update(PATH="/usr/local/opt/ccache/libexec:${PATH}")

    scripts = OrderedDict()

    steps = job_data.get('steps')

    for i, step in enumerate(steps, start=1):

        step_id = str(uuid.uuid4())
        step_name = step.get('name', '')
        has_action = step.get('uses', '')
        step_shell = step.get('shell', '')
        script_content = step.get('run', '')
        action_work_dir = step.get('working-directory', '')
        work_dir = None

        if action_work_dir:
            work_dir = action_work_dir.replace('${{ github.workspace }}', current_path)
            work_dir = find_env_pattern.sub(lambda x: environment.get(x.group(1), ''), work_dir)
        else:
            work_dir = current_path

        if has_action:
            continue
        if step_name in ('Checkout',):
            continue

        if step_shell and script_content:
            print(f'  + Generating snippet for \'{step_name}\'')
            script_content = step.get('run', '')

            matches = find_setenv_pattern.findall(script_content)
            for match in matches:
                environment.update({match[0]: match[1]})

            script_content = find_setenv_pattern.sub('', script_content)
            script_content = script_content.replace('${{ github.workspace }}', current_path)
            script_content = find_env_pattern.sub('${\\1}', script_content)

            script_content_indent = '\n'.join([f'    {line}' for line in script_content.splitlines()])

            if 'EOF' in script_content:
                script_content_indent = find_heredoc_pattern.sub(un_indent, script_content_indent)

            step_script = step_template.format(
                step_id=step_id,
                dependency=step_name,
                working_directory=work_dir,
                script=script_content_indent
            )

            scripts[step_id] = step_script

    environment_vars = [f'export {key}="{var}"' for key, var in environment.items()]

    compiled_script = template.format(
        environment='\n'.join(environment_vars),
        build_steps='\n\n'.join(scripts.values()),
        workspace=current_path,
        call_build_steps='\n'.join([f'    build_{uuid}' for uuid in scripts.keys()]),
    )

    return compiled_script

def main() -> int:
    parsers = {
        'macos': parse_macos_job,
        'ubuntu': (lambda x: x),
        'windows': (lambda x: x),
    }
    arguments = sys.argv

    if len(sys.argv) > 1:
        file_name = sys.argv[1]
    else:
        file_name = ".github/workflows/main.yml"

    with open(file_name) as workflow_file:
        yaml_data = yaml.load(workflow_file, Loader=yaml.FullLoader)

        global_env = yaml_data.get('env', {})
        jobs = yaml_data.get('jobs', {}).values()
        job_items = [item for item in jobs if not item.get('needs', None)]

        for target_os in ['macos-latest', 'windows-latest', 'ubuntu-latest']:
            target_jobs = [item for item in job_items if target_os in item.get('runs-on', [])]
            os_name = target_os.split('-')[0]

            template_filename = f'./templates/build-script-{os_name}.tpl'

            with open(template_filename, 'r') as template_file:
                template = template_file.read()

            step_template = BLUEPRINT[os_name]

            for step_number, target_job in enumerate(target_jobs, start=1):
                compiled_script = parsers[os_name](
                    target_job, template, step_template,
                    global_env
                )
                file_name = f'build-script-{os_name}-{step_number:02d}.sh'

                print(f' + Writing compiled script to file {file_name}')
                with open(file_name, 'w') as script_file:
                    script_file.write(compiled_script)

    return 0

# Run main function if not run as a module
if __name__ == '__main__':
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print('Program interrupted by user input')

        sys.exit(1)
