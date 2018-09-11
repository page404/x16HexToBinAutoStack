ml /c hexToBin.asm
ml /c mylib.asm
link hexToBin.obj mylib.obj
debug hexToBin.exe