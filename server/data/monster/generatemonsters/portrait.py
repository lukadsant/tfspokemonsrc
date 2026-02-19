first = 27117
last = 27117 + 251

msg = ""

for i in range(first, last+1):
	msg = msg + '\t<item id="%i" article="a" name="portrait">\n\t\t<attribute key="slotType" value="head" />\n\t</item>\n' %i

first = 27959
last = 28093

for i in range(first, last+1):
	msg = msg + '\t<item id="%i" article="a" name="portrait">\n\t\t<attribute key="slotType" value="head" />\n\t</item>\n' %i

print(msg)

