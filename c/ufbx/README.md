This is a bare-essentials copy of ufbx (the repository contains lots of .fbx files and testing guff).
https://github.com/bqqbarbhg/ufbx

This was compiled into a static library using:
clang -c -o temporary.o ufbx.c && llvm-ar rc ufbx.lib temporary.o