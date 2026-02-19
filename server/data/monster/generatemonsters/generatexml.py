import shutil
import os

pasta="Pokes1"

f2 = open("pokes.txt")
f3 = open("m.xml", "w")
f4 = open("i.xml", "w")
f5 = open("monsternumber.txt", "w")
f5.write('monsterNumber = {\n')
f6 = open("creatures.xml", "w")
f7 = open("i_portrait.xml", "w")
f8 = open("blogdex.txt", "w")
f9 = open("monsterstaskeasy.txt", "w")
f9.write('easyPokes = {\n')
f10 = open("monsterstaskhard.txt", "w")
f10.write('hardPokes = {\n')
f11 = open("portraitspng.txt", "w")
linhas=f2.readlines()
portraitfolder = "portraitspng"
portraitfoldernew = "portraitspng_renamed"
move=[0]*14
loot=[0]*11

lendarios = ["Zapdos", "Articuno", "Moltres", "Mew", "Mewtwo", "Raikou", "Entei", "Suicune", "Ho-oh", "Lugia", "Celebi", "Regirock", "Regice", "Registeel", "Latias", "Latios", "Kyogre", "Groudon", "Rayquaza", "Shiny_Zapdos", "Shiny_Articuno", "Shiny_Moltres", "Shiny_Mew", "Shiny_Mewtwo", "Shiny_Raikou", "Shiny_Entei", "Shiny_Suicune", "Shiny_Ho-oh", "Shiny_Lugia", "Shiny_Celebi", "Shiny_Regirock", "Shiny_Regice", "Shiny_Registeel", "Shiny_Latias", "Shiny_Latios", "Shiny_Kyogre", "Shiny_Groudon", "Shiny_Rayquaza", "Uxie", "Mesprit", "Azelf", "Dialga", "Palkia", "Heatran", "Regigigas", "Giratina", "Cresselia", "Phione", "Manaphy", "Darkrai", "Shaymin", "Arceus","Shiny_Uxie", "Shiny_Mesprit", "Shiny_Azelf", "Shiny_Dialga", "Shiny_Palkia", "Shiny_Heatran", "Shiny_Regigigas", "Shiny_Giratina", "Shiny_Cresselia", "Shiny_Phione", "Shiny_Manaphy", "Shiny_Darkrai", "Shiny_Shaymin", "Shiny_Arceus"]

targets=["quick attack", "bite", "scratch", "leech seed", "double slap", "super fang", "fireball", "razor leaf", "bubble", "ember", "drill peck", "thunder bolt", "poison sting", "bug bite", "string shot", "acid", "headbutt", "sucker punch", "shadow punch", "shadow ball", "poison bomb", "leech life", "pin missile", "struggle bug", "twinneedle", "crunch", "feint attack", "pursuit", "thief", "thunder punch", "cross chop", "double kick", "jump kick", "low kick", "mach punch", "rock smash", "rolling rock", "seismic toss", "submission", "high jump kick", "jump kick", "karate chop", "submission", "fire punch", "fly", "peck", "sky attack", "confuse ray", "curse", "lick", "absorb", "mega drain", "bone club", "bonemerang", "mud bomb", "mud shot", "mud slap", "avalanche", "ice punch", "ice shards", "powder snow", "body slam", "egg bomb", "extreme speed", "fury attack", "hyper fang", "mega kick", "mega punch", "pound", "slam", "slash", "stomp", "strength", "swift", "tackle", "thrash", "tri attack", "gunk shot", "poison fang", "sludge", "sludge bomb", "dream eater", "future sight", "psychic fangs", "psystrike", "zen headbutt", "rock throw", "smack down", "stone edge", "iron tail", "heavy slam", "iron head", "clamp", "crabhammer", "knock off", "horn attack"]

distance=["bite", "scratch", "super fang", "struggle bug", "twinneedle", "crunch", "feint attack", "thief", "fire punch", "peck", "mud slap", "body slam", "hyper fang", "mega punch", "slam", "tackle", "strength", "slash", "smack down", "iron tail", "heavy slam", "clamp", "crabhammer", "double slap", "pound", "low kick", "karate chop", "cross chop", "seismic toss", "thunder punch", "ice punch", "mega kick", "shadow punch", "knock off", "bug bite", "horn attack", "thrash", "headbutt", "stomp"]

passives = ["passive fire", "passive water", "passive grass", "passive electric", "passive ice", "passive poison", "passive flying", "passive rock", "passive psychic", "passive dark", "passive fighting", "passive ghost", "passive ground"]


for i in range(len(linhas)):
	linha = linhas[i].split()
	print(linhas[i].split()[0])
	print(linha[1])
	if linha[1][0] == "A" or linha[1][0] == "E" or linha[1][0] == "I" or linha[1][0] == "O" or linha[1][0] == "U":
		vdes = "an "
	else:
		vdes = "a " 
	if linha[12] == "none":
		lvlmin = 1
		lvlmax = 15
	else:
		lvlmin = int(linha[12])
		lvlmax = int(linha[13])

	if linha[14] != "none":
		evo = linha[14]
	else:
		evo = False


	for j in range(1,14):
		move[j]=False

	for j in range(1,11):
		loot[j]=False

	if linha[19] != "none": move[1]=True
	if linha[21] != "none": move[2]=True
	if linha[23] != "none": move[3]=True
	if linha[25] != "none": move[4]=True	
	if linha[27] != "none": move[5]=True
	if linha[29] != "none": move[6]=True
	if linha[31] != "none": move[7]=True
	if linha[33] != "none": move[8]=True
	if linha[35] != "none": move[9]=True
	if linha[37] != "none": move[10]=True
	if linha[39] != "none": move[11]=True
	if linha[41] != "none": move[12]=True
	if linha[87] != "none": move[13]=True



	if linha[55] != "none": loot[1]=True
	if linha[58] != "none": loot[2]=True
	if linha[61] != "none": loot[3]=True
	if linha[64] != "none": loot[4]=True	
	if linha[67] != "none": loot[5]=True
	if linha[70] != "none": loot[6]=True
	if linha[73] != "none": loot[7]=True
	if linha[76] != "none": loot[8]=True
	if linha[79] != "none": loot[9]=True
	if linha[82] != "none": loot[10]=True

	movemsg=""
	lootmsg=""

	raceblog = ""
	moveblog = ""
	evoblog = ""
	habilidadesblog = ""

	if linha[3].lower() == "none":
		raceblog = linha[2].lower()
	else:
		raceblog = linha[2].lower() + "/" + linha[3].lower()

	evomsg=""
	attackmsg=""
	defensemsg=""
	legendarymsg=""
	namemsg=linha[1]
	flymsg=int(linha[43])
	ridemsg=int(linha[45])
	surfmsg=int(linha[44])
	corpseid=int(linha[52])

	if flymsg > 0:
		habilidadesblog = "\nHabilidades: Fly"
	if ridemsg > 0:
		if habilidadesblog == "":
			habilidadesblog = "\nHabilidades: Ride"
		else:
			habilidadesblog = habilidadesblog + ", Fly"
	if surfmsg > 0:
		if habilidadesblog == "":
			habilidadesblog = "\nHabilidades: Surf"
		else:
			habilidadesblog = habilidadesblog + ", Surf"

	if habilidadesblog != "":
		habilidadesblog = habilidadesblog + "\n"

	namemsg = linha[1].replace("_"," ")

	targetmsg = ""
	immunitiesmsg = ""

	if linha[1] in lendarios:
		legendarymsg = '\t\t<event name="LegendariesDeath"/>'
		targetmsg = '"30"'
#		immunitiesmsg = '\t\t<immunity paralyze="1" />\n\t\t<immunity sleep="1" />'
	else:
		targetmsg = '"0"'

	if evo:
		evo2=1
		tiraespaco = linha[17].replace("_"," ")
		nomesemespaco = linha[14].replace("_"," ")

		evoblog = "\nEvolucoes: " + nomesemespaco.title() + " level "+linha[15]+" ou usando " +linha[18] + " " + tiraespaco.replace(",","/") + "\n"

		if linha[14]=="vileplume,bellossom":
			evomsg = '\t\t<evolution name="'+'Vileplume'+'" level="'+linha[15]+'"'+' chance="'+linha[16]+'"' + ' itemName="leaf stone" count="'+linha[18]+'"/>\n'
			evomsg = evomsg + '\t\t<evolution name="'+'Bellossom'+'" level="'+linha[15]+'"'+' chance="'+linha[16]+'"' + ' itemName="sun stone" count="'+linha[18]+'"/>\n'
		elif linha[14]=="poliwrath,politoed":
			evomsg = '\t\t<evolution name="'+'Poliwrath'+'" level="'+linha[15]+'"'+' chance="'+linha[16]+'"' + ' itemName="water stone" count="'+linha[18]+'"/>\n'
			evomsg = evomsg + '\t\t<evolution name="'+'Politoed'+'" level="'+linha[15]+'"'+' chance="'+linha[16]+'"' + ' itemName="'+"king's rock stone"+'" count="'+linha[18]+'"/>\n'
		elif linha[14]=="vaporeon,jolteon,flareon,umbreon,espeon":
			evomsg = '\t\t<evolution name="'+'Vaporeon'+'" level="'+linha[15]+'"'+' chance="'+linha[16]+'"' + ' itemName="water stone" count="'+linha[18]+'"/>\n'
			evomsg = evomsg + '\t\t<evolution name="'+'Jolteon'+'" level="'+linha[15]+'"'+' chance="'+linha[16]+'"' + ' itemName="thunder stone" count="'+linha[18]+'"/>\n'
			evomsg = evomsg + '\t\t<evolution name="'+'Flareon'+'" level="'+linha[15]+'"'+' chance="'+linha[16]+'"' + ' itemName="fire stone" count="'+linha[18]+'"/>\n'
			evomsg = evomsg + '\t\t<evolution name="'+'Umbreon'+'" level="'+linha[15]+'"'+' chance="'+linha[16]+'"' + ' itemName="darkness stone" count="'+linha[18]+'"/>\n'
			evomsg = evomsg + '\t\t<evolution name="'+'Espeon'+'" level="'+linha[15]+'"'+' chance="'+linha[16]+'"' + ' itemName="enigma stone" count="'+linha[18]+'"/>\n'
		elif linha[14]=="hitmontop,hitmonlee,hitmonchan":
			evomsg = '\t\t<evolution name="'+'Hitmontop'+'" level="'+linha[15]+'"'+' chance="'+linha[16]+'"' + ' itemName="punch stone" count="'+linha[18]+'"/>\n'
			evomsg = evomsg + '\t\t<evolution name="'+'Hitmonlee'+'" level="'+linha[15]+'"'+' chance="'+linha[16]+'"' + ' itemName="punch stone" count="'+linha[18]+'"/>\n'
			evomsg = evomsg + '\t\t<evolution name="'+'Hitmonchan'+'" level="'+linha[15]+'"'+' chance="'+linha[16]+'"' + ' itemName="punch stone" count="'+linha[18]+'"/>\n'
		elif linha[14]=="shiny_vileplume,shiny_bellossom":
			evomsg = '\t\t<evolution name="'+'Shiny Vileplume'+'" level="'+linha[15]+'"'+' chance="'+linha[16]+'"' + ' itemName="leaf stone" count="'+linha[18]+'"/>\n'
			evomsg = evomsg + '\t\t<evolution name="'+'Shiny Bellossom'+'" level="'+linha[15]+'"'+' chance="'+linha[16]+'"' + ' itemName="sun stone" count="'+linha[18]+'"/>\n'
		elif linha[14]=="shiny_poliwrath,shiny_politoed":
			evomsg = '\t\t<evolution name="'+'Shiny Poliwrath'+'" level="'+linha[15]+'"'+' chance="'+linha[16]+'"' + ' itemName="water stone" count="'+linha[18]+'"/>\n'
			evomsg = evomsg + '\t\t<evolution name="'+'Shiny Politoed'+'" level="'+linha[15]+'"'+' chance="'+linha[16]+'"' + ' itemName="'+"king's rock stone"+'" count="'+linha[18]+'"/>\n'
		elif linha[14]=="shiny_vaporeon,shiny_jolteon,shiny_flareon,shiny_umbreon,shiny_espeon":
			evomsg = '\t\t<evolution name="'+'Shiny Vaporeon'+'" level="'+linha[15]+'"'+' chance="'+linha[16]+'"' + ' itemName="water stone" count="'+linha[18]+'"/>\n'
			evomsg = evomsg + '\t\t<evolution name="'+'Shiny Jolteon'+'" level="'+linha[15]+'"'+' chance="'+linha[16]+'"' + ' itemName="thunder stone" count="'+linha[18]+'"/>\n'
			evomsg = evomsg + '\t\t<evolution name="'+'Shiny Flareon'+'" level="'+linha[15]+'"'+' chance="'+linha[16]+'"' + ' itemName="fire stone" count="'+linha[18]+'"/>\n'
			evomsg = evomsg + '\t\t<evolution name="'+'Shiny Umbreon'+'" level="'+linha[15]+'"'+' chance="'+linha[16]+'"' + ' itemName="darkness stone" count="'+linha[18]+'"/>\n'
			evomsg = evomsg + '\t\t<evolution name="'+'Shiny Espeon'+'" level="'+linha[15]+'"'+' chance="'+linha[16]+'"' + ' itemName="enigma stone" count="'+linha[18]+'"/>\n'
		elif linha[14]=="shiny_hitmontop,shiny_hitmonlee,shiny_hitmonchan":
			evomsg = '\t\t<evolution name="'+'Shiny Hitmontop'+'" level="'+linha[15]+'"'+' chance="'+linha[16]+'"' + ' itemName="punch stone" count="'+linha[18]+'"/>\n'
			evomsg = evomsg + '\t\t<evolution name="'+'Shiny Hitmonlee'+'" level="'+linha[15]+'"'+' chance="'+linha[16]+'"' + ' itemName="punch stone" count="'+linha[18]+'"/>\n'
			evomsg = evomsg + '\t\t<evolution name="'+'Shiny Hitmonchan'+'" level="'+linha[15]+'"'+' chance="'+linha[16]+'"' + ' itemName="punch stone" count="'+linha[18]+'"/>\n'
		else:
			for l,m in enumerate(tiraespaco):
				if m==",":
					evo2=evo2+1
			if evo2==2:
				tiraespaco1=tiraespaco.split(",")[0]
				tiraespaco2=tiraespaco.split(",")[1]
				evomsg = '\t\t<evolution name="'+nomesemespaco.title()+'" level="'+linha[15]+'"'+' chance="'+linha[16]+'"' + ' itemName="'+tiraespaco1+'" count="'+linha[18]+'"/>\n'
				evomsg = evomsg + '\t\t<evolution name="'+nomesemespaco.title()+'" level="'+linha[15]+'"'+' chance="'+linha[16]+'"' + ' itemName="'+tiraespaco2+'" count="'+linha[18]+'"/>\n'
			else:
				evomsg = '\t\t<evolution name="'+nomesemespaco.title()+'" level="'+linha[15]+'"'+' chance="'+linha[16]+'"' + ' itemName="'+tiraespaco+'" count="'+linha[18]+'"/>\n'


	for k in range(1,14):
		if move[k] == True:
			if k <= 12:
				linhaatual = linha[17+k*2]
				proximalinha = linha[17+k*2+1]
			else:
				linhaatual = linha[87]
				proximalinha = linha[88]
			tiraespaco = linhaatual.replace("_"," ")
			if k <=12:
				moveblog = moveblog + 'm' + str(k) + " - " + tiraespaco + '\n'
			else:
				moveblog = moveblog + "Passiva - " + tiraespaco + '\n'
			if tiraespaco in passives:
				defensemsg = defensemsg + '\t\t<defense name="'+tiraespaco+'" interval="'+str(proximalinha)+'" chance="100"/>\n'			
			if tiraespaco in (targets and distance):
				movemsg = movemsg + '\t\t<move name="'+tiraespaco+'" interval="'+str(proximalinha)+'"'+' isTarget="1"'+' range="1"'+'/>\n'
				attackmsg = attackmsg + '\t\t<attack name="'+tiraespaco+'" interval="'+str(proximalinha)+'" chance="40" range="1" target="1"/>\n'
			elif tiraespaco in targets:
				movemsg = movemsg + '\t\t<move name="'+tiraespaco+'" interval="'+str(proximalinha)+'"'+' isTarget="1"'+'/>\n'
				attackmsg = attackmsg + '\t\t<attack name="'+tiraespaco+'" interval="'+str(proximalinha)+'" chance="40" target="1"/>\n'
			else:
				attackmsg = attackmsg + '\t\t<attack name="'+tiraespaco+'" interval="'+str(proximalinha)+'" chance="40"/>\n'
				if not tiraespaco in passives:
					movemsg = movemsg + '\t\t<move name="'+tiraespaco+'" interval="'+str(proximalinha)+'"/>\n'

	for k in range(1,11):
		if loot[k] == True:
			tiraespaco = linha[52+k*3].replace("_"," ")
			lootmsg = lootmsg + '\t\t<item name="'+tiraespaco+'" countmax="'+str(linha[52+k*3+2])+'" chance="'+str(linha[52+k*3+1])+'"/>\n'
	

	fin = open("modelo.xml")
	fout = open(os.path.abspath(pasta+"/%s.xml" % namemsg.lower()), "w")
	for line in fin:
		fout.write(line.replace('#name', '"%s"' %(namemsg)).replace('#description', '"%s"' %(vdes + namemsg.lower())).replace('#race', '"%s"' %(linha[2].lower())).replace('#srace', '"%s"' %(linha[3].lower())).replace('#experience', '"%s"' %(linha[4])).replace('#health', '"%i"' %(17*int(linha[5]))).replace('#attack', '"-%s"' %(linha[6])).replace('#defense', '"%s"' %(linha[7])).replace('#magicattack', '"%s"' %(linha[8])).replace('#magicdefense', '"%s"' %(linha[9])).replace('#speed', '"%s"' %(2*int(linha[10]))).replace('#dexentry', '"%s"' %(linha[0])).replace('#looktype', '"%i"' %(int(linha[54]))).replace('#corpse', '"%i"' %(corpseid)).replace('#voice', '"%s"' %(namemsg.upper()+"!")).replace('#lvlmin', '"%i"' %(lvlmin)).replace('#lvlmax', '"%i"' %(lvlmax)).replace("#msgmove",movemsg).replace("#msgloot",lootmsg).replace("#msgevo",evomsg).replace("#msgattack",attackmsg).replace("#msgimmunities",immunitiesmsg).replace("#targetchange",targetmsg).replace("#msgdefense",defensemsg).replace('#fly', '"%s"' %(flymsg)).replace('#catch', '"%s"' %(linha[86])).replace('#msglegendary', '%s' %(legendarymsg)).replace('#ride', '"%s"' %(ridemsg)).replace('#surf', '"%s"' %(surfmsg)).replace('#agressive', '"%s"' %(linha[49])).replace('#teleport', '"%s"' %(linha[47])).replace('#shiny', '"%s"' %(linha[50])).replace('#mega', '"%s"' %(linha[51])).replace('#portraitid', '"%s"' %(linha[53])) )
	fin.close()
	fout.close()

	f3.write('\t<monster name="%s" file="%s.xml" />\n' %(namemsg.title(),pasta+"/"+namemsg.lower()))

	if int(corpseid) != 0:
		f4.write('\t<item id="%s" article="a" name="slain %s">\n\t\t<attribute key="weight" value="20000" />\n\t\t<attribute key="decayTo" value="0" />\n\t\t<attribute key="duration" value="600" />\n\t\t<attribute key="corpseType" value="blood" />\n\t</item> \n' %(corpseid,namemsg.lower()))

	if int(linha[53]) != 0:
		f7.write('\t<item id="%s" article="a" name="portrait">\n\t\t<attribute key="slotType" value="head" />\n\t</item>\n' %(linha[53]))


	f5.write('{"%s", %s},\n' %(namemsg, linha[0]))

	if namemsg.split()[0] != "Shiny":
		if int(linha[86]) > 15:
			f9.write('"%s", ' %(namemsg))
		elif int(linha[86]) <= 15 and int(linha[86])>0:
			f10.write('"%s", ' %(namemsg))
		

	f6.write('\t<creature name="%s" type="monster" looktype="%s" />\n' %(namemsg.title(),linha[54]))

	f8.write('[%s] %s\nRace: %s \nCatch Chance: %s a cada 300 com pokeball. %i a cada 300 com ultraball. %i a cada 300 com premierball.\n\nHealth: %i\nAttack: %s\nMagic Attack: %s\nMagic Defense: %s\nArmor: %s\nSpeed: %i\n\nMoves:\n%s%s%s\n\n<hr />\n' %(linha[0], namemsg, raceblog, linha[86], 1.4*int(linha[86]), 1.5*int(linha[86]),17*int(linha[5]), linha[6], linha[8], linha[9], linha[7], 2*int(linha[10]), moveblog, evoblog, habilidadesblog) )

	pokenumber = int(linha[53])-2416
	f11.write('%s %s\n' %(namemsg.lower(),pokenumber))
	if pokenumber == 24819: #seaking
		pokenumber = 25054
	elif pokenumber == 25894: #shiny pupitar
		pokenumber = 25890
	elif pokenumber == 25895: #shiny tyranitar
		pokenumber = 25891
	elif pokenumber >= 24819 and pokenumber < 36282:
		pokenumber = pokenumber - 1
	elif pokenumber >= 36282:
		pokenumber = pokenumber - 26
	portraitname = "item_"+str(pokenumber)+".png"
	found = False
	for file in os.listdir(portraitfolder):
    		if file.endswith(".png"):
			if file == portraitname:
				found = True
				shutil.copy2(portraitfolder+"/"+portraitname, portraitfoldernew+"/"+namemsg.lower()+".png")
				print(os.path.join(portraitfolder, file))
	if found == False:
		print("portrait not found")
		shutil.copy2(portraitfolder+"/"+"notfound.png", portraitfoldernew+"/"+namemsg.lower()+".png")

f2.close()

f5.write('}')





	

