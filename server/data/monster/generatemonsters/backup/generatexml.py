import shutil
import os

fin = open("modelo.xml")
f2 = open("pokes.txt")
linhas=f2.readlines()
for i in range(len(linhas)):
	linha = linhas[i].split()
	fout = open(os.path.abspath("%s.xml" % linha[1]), "w")
	for line in fin:
		fout.write(line.replace('#name', '%s' %(linha[1])))


	

