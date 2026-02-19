Algumas aplicações por exemplo em servidores de pokemon ao jogar a pokebola mandar um som para o client ao capturar outro som ou falhar na captura, assim como som de batalhas, som ambiente, o limite é sua imaginação!

 

Lista de funções

pauseAll
isPlaying
isFinished
getSoundPlayLen
getSoundPlayPosition
setSndPlayPos
setSoundMinDistance
setListenerPosition
setSound3DPosition
setVolume
getVolume
setPaused
isPaused
playMusic
deleteSnd
setReverbEnabled
setEchoEnabled
setDistortionEnabled
Exemplo de uso em lua servidor:

local colors = {
	TEXTCOLOR_BLUE,
	TEXTCOLOR_LIGHTBLUE,
	TEXTCOLOR_LIGHTGREEN,
	TEXTCOLOR_TEAL,
	TEXTCOLOR_PURPLE,
	TEXTCOLOR_PLATINUMBLUE,
	TEXTCOLOR_LIGHTGREY,
	TEXTCOLOR_DARKRED,
	TEXTCOLOR_RED,
	TEXTCOLOR_ORANGE,
	TEXTCOLOR_YELLOW,
	TEXTCOLOR_WHITE_EXP
}
function onSay(cid, words, param)
	local playerpos = getPlayerPosition(cid)
	local random = math.random(1, #colors)
	if math.max(math.abs(playerpos.x-23), math.abs(playerpos.y-30)) < 9999 then
		doSendAnimatedText(playerpos, "GoGoGo!", colors[random]) 
		sendScreanSound(cid, "com_go.wav")		
	end
	return true
end
 
 

Criaturas Falantes C++ ServerSide:

 

Em game.cpp, procure por:
 

bool Game::internalCreatureSay(Creature* creature, SpeakClasses type, const std::string& text,
bool ghostMode, SpectatorVec* spectators/* = NULL*/, Position* pos/* = NULL*/)
E abaixo de:
 

if(!ghostMode || tmpPlayer->canSeeCreature(creature))
tmpPlayer->sendCreatureSay(creature, type, text, &destPos);
Adicione:

 

if(type == SPEAK_MONSTER_YELL or type == SPEAK_MONSTER_SAY){
tmpPlayer->sendExtendedOpcode(85, text + ".mp3|false");
}
Dai é só adicionar os som a pasta e colocar o nome dele igual a fala nesse metodo só ta pra rodar mp3, tem jeito melhor de fazer isso adicionando um nova tag no .xml do monstro mais acabei ficando com preguiça e fiz assim kk'