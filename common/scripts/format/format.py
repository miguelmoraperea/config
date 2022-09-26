"""Reformat file names."""
import argparse
import subprocess
import os
from datetime import datetime
from PIL import Image, UnidentifiedImageError
from natsort import natsorted

CWD = os.getcwd()
IS_DRY_RUN = False
IS_TO_LOWER = False
IS_RECURSIVE = False
IS_FILE_ONLY = False
EXCLUDE_DIRS = []
SUBSTITUTE = None
NAME = ''
IMAGE_EXTENSIONS = ['jpg']


def get_date_taken(path):
    try:
        return datetime.strptime(str(Image.open(path)._getexif()[36867]), '%Y:%m:%d %H:%M:%S')
    except (UnidentifiedImageError, TypeError, KeyError):
        stat = os.stat(path)
        try:
            return datetime.fromtimestamp(stat.st_birthtime)
        except AttributeError:
            return datetime.fromtimestamp(stat.st_mtime)


class Rename:

    def __init__(self):
        self._counter = 1
        self._last_dir = ''

    def run(self, path):
        full_path = os.path.join(CWD, path)
        dir_name = os.path.dirname(full_path)
        name = os.path.basename(full_path)
        is_file = os.path.isfile(full_path)
        if NAME and IS_RECURSIVE:
            raise RuntimeError(
                'Do not use the recursive option when renaming  batch files')
        if NAME and is_file:
            if self._last_dir != os.path.dirname(full_path):
                self._counter = 1
            if '.' in name:
                extension = get_extension(name)
                tmp = f'{NAME}_{self._counter}.{extension}'
            else:
                tmp = f'{NAME}_{self._counter}'
            self._counter += 1
            self._last_dir = os.path.dirname(full_path)
            return os.path.join(dir_name, tmp)
        tmp = name.lower() if IS_TO_LOWER else name
        tmp2 = tmp.replace(' ', '_')
        old = new = ''
        if SUBSTITUTE:
            old, new = SUBSTITUTE[0].split('/', maxsplit=1)
        return os.path.join(dir_name, tmp2.replace(old, new)) if SUBSTITUTE else os.path.join(dir_name, tmp2)

    def reset(self):
        self._counter = 1


def main():
    global IS_DRY_RUN
    global IS_TO_LOWER
    global IS_RECURSIVE
    global IS_FILE_ONLY
    global EXCLUDE_DIRS
    global SUBSTITUTE
    global NAME

    parser = argparse.ArgumentParser(description='Reformat file names')
    parser.add_argument('targets', nargs='+', help='Targets to rename')
    parser.add_argument('-d', '--dry-run', action='store_true',
                        help='Only show what it would do.')
    parser.add_argument('-r', '--recursive', action='store_true',
                        help='Apply reformatting recursively')
    parser.add_argument('-l', '--lower', action='store_true',
                        help='Change to all lower case')
    parser.add_argument('-f', '--files', action='store_true',
                        help='Change files only, ignore dirs')
    parser.add_argument('-e', '--exclude_dirs', nargs=1, default=[],
                        help='Exclude the directories that match')
    parser.add_argument('-s', '--substitute', nargs=1,
                        help='Substitute with matching sequence')
    parser.add_argument('-n', '--name', nargs=1,
                        help='Rename appending a numeric sequence')

    args = parser.parse_args()

    IS_DRY_RUN = args.dry_run
    IS_TO_LOWER = args.lower
    IS_RECURSIVE = args.recursive
    IS_FILE_ONLY = args.files
    EXCLUDE_DIRS = args.exclude_dirs
    SUBSTITUTE = args.substitute
    NAME = args.name[0] if args.name else ''

    process(args.targets)


def process(targets):
    rename = Rename()
    rename_cnt = 0
    renamed_targets = targets

    if IS_DRY_RUN:
        print('DRY-RUN', end='\n\n')

    if not IS_FILE_ONLY:
        # Rename dirs
        dirs, renamed_targets = find_dirs_to_rename(targets)
        for old_path in dirs:
            new_path = rename.run(old_path)
            rename_cnt += move_file(old_path, new_path)
            if old_path in renamed_targets:
                renamed_targets.remove(old_path)
                renamed_targets.append(new_path)

    # Rename files
    files = find_files_to_rename(renamed_targets)
    if NAME:
        files.sort(key=lambda x: get_date_taken(x))
    else:
        natsorted(files)
    for old_path in files:
        new_path = rename.run(old_path)
        rename_cnt += move_file(old_path, new_path)
        extension = get_extension(old_path)
        if extension is not None and extension in IMAGE_EXTENSIONS:
            pp3_path = f'{old_path}.pp3'
            if os.path.exists(pp3_path):
                rename_cnt += move_file(pp3_path, f'{new_path}.pp3')
                files.remove(pp3_path)

    if rename_cnt == 0:
        print('Not items found that need formatting.')


def get_extension(path):
    if '.' in path:
        return path.rsplit('.', 1)[-1].lower()
    return None


def find_dirs_to_rename(targets):
    dirs_ = []
    targets_ = []

    for target in targets:
        if target in EXCLUDE_DIRS:
            continue
        if IS_RECURSIVE:
            for root, dirs, _ in os.walk(os.path.join(CWD, target), topdown=False):
                dirs[:] = [dir for dir in dirs if dir not in EXCLUDE_DIRS]
                for dir in dirs:
                    full_path = os.path.join(root, dir)
                    dirs_.append(full_path)
        target_path = os.path.join(CWD, target)
        if os.path.isdir(target_path) and target not in EXCLUDE_DIRS:
            dirs_.append(target_path)
        targets_.append(target_path)

    return dirs_, targets_


def find_files_to_rename(targets):
    files_ = []

    for target in targets:
        if target in EXCLUDE_DIRS:
            continue
        if IS_RECURSIVE:
            if os.path.isfile(target):
                files_.append(target)
            for root, dirs, files in os.walk(os.path.join(CWD, target)):
                dirs[:] = [dir for dir in dirs if dir not in EXCLUDE_DIRS]
                for file in files:
                    full_path = os.path.join(root, file)
                    files_.append(full_path)
        elif os.path.isfile(target):
            files_.append(target)

    return files_


def move_file(src, dest):
    escaped_chars = str.maketrans(
        {"(": r"\(", ")": r"\)", " ": r"\ ", "'": r"\'", "&": r"\&"})
    escaped_src = src.translate(escaped_chars)
    escaped_dest = dest.translate(escaped_chars)
    if src == dest:
        return 0
    if not IS_DRY_RUN:
        move(escaped_src, escaped_dest)
    print_message(os.path.basename(src), os.path.basename(dest))
    return 1


def move(src, dest):
    cmd = f'mv {src} {dest}'
    subprocess.call(cmd, shell=True)


def print_message(old_path, new_path):
    word = '-->'
    if IS_DRY_RUN:
        word = '~~>'
    old_name = os.path.basename(old_path)
    new_name = os.path.basename(new_path)
    print(f'{old_name:<50} {word:} {new_name}')


if __name__ == '__main__':
    main()
