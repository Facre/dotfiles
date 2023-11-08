#!/usr/bin/env python3
import os
import sys
from os.path import join, split

import art


class Project(object):

    def __init__(self, home, project, name):
        self.project = project
        self.book = join(".", name)
        self.home = home

    @staticmethod
    def check_suffix(name, suffix):
        for s in suffix:
            if name.endswith(s):
                return True
        return False

    def write_book(self, paths, entries):
        print("Collecting source codes: ", end="")
        with open(self.book, mode="w") as book:
            if self.project != "":
                book.write("\n\n\n\n\n")
                book.write(art.text2art(self.project))
                book.write("\n\n\n\n\n")
            for path in paths:
                print(".", end="")
                entry = entries[path]
                if entry is None:
                    continue
                book.writelines(["\n\n\n===== " + path + " =====\n\n"])
                with open(entry, mode="r") as file:
                    lines = file.readlines()
                    book.writelines(lines)
                    book.flush()
        print("Done")


class CppProject(Project):

    def __init__(self, home, project, name):
        Project.__init__(self, home, project, name)
        self.benchmark = join(home, "benchmark")
        self.test = join(home, "test")
        self.src = join(home, "src")
        self.book = join(".", name)
        self.ignored = [".txt", ".png", ".cfg"]
        self.headers = [".h"]
        self.sources = [".cpp"]

    def __ignored(self, name):
        return Project.check_suffix(name, self.ignored)

    def __is_header(self, name):
        return Project.check_suffix(name, self.headers)

    def __is_source(self, name):
        return Project.check_suffix(name, self.sources)

    def extract(self):
        paths = []
        entries = {}
        print("Scanning source codes...")
        self.__scan_files(self.benchmark, split(
            self.benchmark)[-1], paths, entries)
        self.__scan_files(self.test, split(self.test)[-1], paths, entries)
        self.__scan_files(self.src, split(self.src)[-1], paths, entries)
        paths = sorted(paths)
        self.__swap_header_with_src(paths)
        self.write_book(paths, entries)

    def __scan_files(self, cur: str, path: str, paths, entries, is_include=False):
        """
        Scan the source code files from the project base directory
        """
        for entry in os.scandir(cur):
            if entry.is_dir():
                child = ""
                if path != "":
                    child = path
                if entry.name == "include":
                    self.__scan_files(join(cur, entry.name),
                                      child, paths, entries, is_include=True)
                else:
                    child = join(child, entry.name)
                    self.__scan_files(join(cur, entry.name),
                                      child, paths, entries)
            if entry.is_file():
                if self.__ignored(entry.name):
                    continue
                paths.append(join(path, entry.name))
                entries[join(path, entry.name)] = join(cur, entry.name)

    def __swap_header_with_src(self, paths):
        idx = 0
        last_name = ""
        while idx < len(paths):
            cur = split(paths[idx])[-1]
            name = cur.split(".")[0]
            if name == last_name and self.__is_header(cur):
                tmp = paths[idx - 1]
                paths[idx - 1] = paths[idx]
                paths[idx] = tmp
            last_name = name
            idx += 1


class RustProject(Project):

    def __init__(self, home, project, name):
        Project.__init__(self, home, project, name)
        self.src = join(home, "src")

    def extract(self):
        paths = []
        entries = {}
        print("Scanning source codes...")
        self.__scan_files(self.src, split(self.src)[-1], paths, entries)
        paths = sorted(paths)
        self.write_book(paths, entries)

    def __scan_files(self, cur: str, path: str, paths, entries):
        for entry in os.scandir(cur):
            if entry.is_dir():
                child = ""
                if path != "":
                    child = path
                child = join(child, entry.name)
                self.__scan_files(join(cur, entry.name),
                                  child, paths, entries)
            if entry.is_file():
                paths.append(join(path, entry.name))
                entries[join(path, entry.name)] = join(cur, entry.name)


def main():
    typ = sys.argv[1]
    home = sys.argv[2]
    name = "books/book.txt"
    project = ""
    booker = None
    if len(sys.argv) == 4:
        project = sys.argv[3]
        name = join("books", project + ".txt")
    elif len(sys.argv) == 5:
        project = sys.argv[3]
        name = sys.argv[4]
    if typ == "cpp":
        booker = CppProject(home, project, name)
    elif typ == "rust":
        booker = RustProject(home, project, name)
    booker.extract()


def usage():
    print("""
    code2book.py [cpp|rust] [home] [project] [name]
    
        cpp|rust    Source code type
        home        Home directory of the project
        project     Name of the project
        name        Name of the produced book
    """)


if __name__ == '__main__':
    if len(sys.argv) > 5 or len(sys.argv) < 2:
        usage()
        exit(0)
    main()
