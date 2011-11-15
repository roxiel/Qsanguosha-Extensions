--水浒杀之替天行道 2011·11·11
module("extensions.SHSTTXD", package.seeall)
extension = sgs.Package("SHSTTXD")
skills={}
qmtarget={}
qmgeneral={}
qmkingdom={}

yinyu_card=sgs.CreateSkillCard{
name="yinyu_effect",
target_fixed=true,
will_throw=false,
once=false,
on_use=function(self,room,source,targets)
	if(source:hasFlag("yinyu_spade")) then 
		local card=room:askForCard(source, "slash", "@yinyu_spade",sgs.QVariant())
		if not card then return	end
		local sp=sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(source)) do
			if source:canSlash(p,true) then
            sp:append(p) 
			end  			
		end
		local t = room:askForPlayerChosen(source, sp, "yinyu-spadeslash")
		room:playSkillEffect("yinyu", math.random(1,2))		
		room:cardEffect(card,source, t)
	end
end
}

yinyu_heart=sgs.CreateDistanceSkill{
name= "yinyu_heart",
correct_func=function(self,from,to)
	if from:hasFlag("yinyu_heart") and not to:hasFlag("yinyu_fixed")
	then return -5
	else return 0
	end
end
}

yinyu_viewAsSkill=sgs.CreateViewAsSkill{
name="yinyu_viewAs",
n=0,
view_filter=function(self, selected, to_select)			
	return false
end,
view_as=function(self, cards)	
	local acard=yinyu_card:clone()	
	acard:setSkillName(self:objectName())		
	return acard	
end,
enabled_at_play=function()
	return --(sgs.Self:hasFlag("yinyu_heart") and not sgs.Self:hasFlag("yinyu_used")) or
    sgs.Self:hasFlag("yinyu_spade") 
    
end,
enabled_at_response=function(self,pattern)	
	return false 
end
}

yinyu=sgs.CreateTriggerSkill{
	name="yinyu",
	events={sgs.TurnStart,sgs.PhaseChange,sgs.CardUsed,sgs.SlashProceed},
	view_as_skill=yinyu_viewAsSkill,
	priority=1,
	on_trigger=function(self,event,player,data)
	local room=player:getRoom()
		local log=sgs.LogMessage()
		log.from=player
	if event==sgs.TurnStart then
		if (room:askForSkillInvoke(player,self:objectName())~=true) then return false end
		local judge=sgs.JudgeStruct()
		judge.pattern=sgs.QRegExp("(.*):(.*):(.*)")
		judge.good=true
		judge.reason="yinyu"
		judge.who=player
		room:judge(judge)		
		if (judge.card:getSuit()==sgs.Card_Heart) then
		     room:setPlayerFlag(player,"yinyu_heart")			 
			 log.type = "#yinyuHeart"
			 room:sendLog(log)				 		 
			 return false						
		elseif	(judge.card:getSuit()==sgs.Card_Diamond) then
			 room:setPlayerFlag(player,"yinyu_diamond")
			 log.type = "#yinyuDiamond"
			 room:sendLog(log)	
			 return false	
		elseif	(judge.card:getSuit()==sgs.Card_Spade) then	
			 room:setPlayerFlag(player,"yinyu_spade")
			 log.type = "#yinyuSpade"
			 room:sendLog(log)						  
		elseif	(judge.card:getSuit()==sgs.Card_Club) then	
			 room:setPlayerFlag(player,"yinyu_club")
			 log.type = "#yinyuClub"
			 room:sendLog(log)
		return false end	
	elseif (event==sgs.SlashProceed) then
			local effect=data:toSlashEffect()				
			if player:hasFlag("yinyu_diamond")	 then
				room:playSkillEffect("yinyu", 3)
				log.type = "#yinyu_diamond"	
				room:sendLog(log)			
				room:slashResult(effect, nil)   			
				return true
			else return false 
			end					
	elseif (event==sgs.CardUsed) then
		local use=data:toCardUse()
	    local card = use.card			
		if  player:hasFlag("yinyu_club") and not player:hasFlag("yinyu_clubused") then 						
				if  card:inherits("Slash") then
				room:playSkillEffect("yinyu", 4)
				log.type = "#yinyu_club"
				room:sendLog(log)
				for _,p in sgs.qlist(use.to) do
					p:addMark("qinggang")				
				end			    	
				room:setPlayerFlag(player,"yinyu_clubused")
				room:useCard(use,false)
				for _,p in sgs.qlist(use.to) do
					p:removeMark("qinggang")				
				end	
				room:setPlayerFlag(player,"-yinyu_clubused")
				return true
				elseif card:inherits("ArcheryAttack") or card:inherits("SavageAssault") or card:inherits("FireAttack") then
				room:playSkillEffect("yinyu", 4)
				for _,p in sgs.qlist(use.to) do
					p:addMark("qinggang")				
				end	
				room:setPlayerFlag(player,"yinyu_clubused")
				room:useCard(use,false)	
				for _,p in sgs.qlist(use.to) do
					p:removeMark("qinggang")				
				end	
				room:setPlayerFlag(player,"-yinyu_clubused")
				return	true			
				end	
		elseif  player:hasFlag("yinyu_heart") then 
				if (card:inherits("Slash")) then
				room:playSkillEffect("yinyu", 5) 
				return false
				elseif (card:inherits("Snatch") or card:inherits("SupplyShortage")) then 
				for _,p in sgs.qlist(use.to) do
				    room:setPlayerFlag(p,"yinyu_fixed")
					if(player:distanceTo(p)>1) then
					log.type = "#yinyu_heart"
					room:sendLog(log)
					room:setPlayerFlag(p,"-yinyu_fixed")
					return true	
					end					
				end	
				end	
				return false				
		end					
    elseif (event==sgs.PhaseChange) and (player:getPhase()==sgs.Player_Finish) then	
        if  player:hasFlag("yinyu_heart") then 
			room:setPlayerFlag(player,"-yinyu_heart")		
		elseif  player:hasFlag("yinyu_diamond")then 
			room:setPlayerFlag(player,"-yinyu_diamond")				
		elseif  player:hasFlag("yinyu_club")then 
			room:setPlayerFlag(player,"-yinyu_club")			
		elseif player:hasFlag("yinyu_spade")then 
			room:setPlayerFlag(player,"-yinyu_spade")
		elseif player:hasFlag("yinyu_used")then 
			room:setPlayerFlag(player,"-yinyu_used")
		end
		if(player:hasSkill("yinyu_heart")) then player:loseSkill("yinyu_heart") end
	end
	end	
}

yueli=sgs.CreateTriggerSkill{
	name="yueli",
	events=sgs.FinishJudge,
	--priority=3,
	frequency=sgs.Skill_Frequent,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()	
		local log=sgs.LogMessage()
		log.type = "#yueli"
		log.from=player					
		local judge=data:toJudge()
		local card=judge.card
		local data_card=sgs.QVariant(0)
		data_card:setValue(card)							
			if judge.card:inherits("BasicCard") then
			if (player:askForSkillInvoke(self:objectName(),data_card)==true) then
				room:sendLog(log)
				room:playSkillEffect("yueli",math.random(1, 2))					
				player:obtainCard(judge.card)		
				return true
			else return false end
		end
	end,	
}

taohui=sgs.CreateTriggerSkill{
name="taohui",
events=sgs.PhaseChange,
priority=2,
frequency=sgs.Skill_Frequent,
on_trigger=function(self,event,player,data)
	local room=player:getRoom()	
	local log=sgs.LogMessage()
	log.type = "#taohui"
	log.from=player
	if player:getPhase()==sgs.Player_Finish then 				
		while true do
		if (room:askForSkillInvoke(player,self:objectName())~=true) then return false end		
		local judge=sgs.JudgeStruct()
		judge.pattern=sgs.QRegExp("(.*):(.*):(.*)")
		judge.good=true
		judge.reason="taohui"
		judge.who=player
		room:judge(judge)        		
		if not judge.card:inherits("BasicCard") then	
			room:playSkillEffect("taohui",math.random(1, 2))		
		    local target = room:askForPlayerChosen(player, room:getAlivePlayers(), "taohui")
			log.arg = target:getGeneralName()
			room:sendLog(log)	
			target:drawCards(1)						
		elseif judge.card:inherits("BasicCard") then break 
		end
		
	end
	return false
	end
	end,
}

huqi=sgs.CreateDistanceSkill{
name= "huqi",
correct_func=function(self,from,to)
	if from:hasSkill(self:objectName())
	then return -1
	else return 0
	end
end
}

wuzu=sgs.CreateTriggerSkill{
	name="wuzu",
	events=sgs.CardUsed,
	priority=2,
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
	local room=player:getRoom()
	local use=data:toCardUse()
	local card = use.card	
	local log=sgs.LogMessage()
	log.type = "#wuzu"
	log.from=player
	if event==sgs.CardUsed and not player:hasFlag("wuzu_used") then 	    
		if  card:inherits("Slash")  then
				room:playSkillEffect("wuzu", 1)				
				room:sendLog(log)
				for _,p in sgs.qlist(use.to) do
					p:addMark("qinggang")				
				end			    	
				room:setPlayerFlag(player,"wuzu_used")
				room:useCard(use,false)
				for _,p in sgs.qlist(use.to) do
					p:removeMark("qinggang")				
				end	
				room:setPlayerFlag(player,"-wuzu_used")
				return true
		elseif card:inherits("ArcheryAttack") or card:inherits("SavageAssault") or card:inherits("FireAttack") then
				room:playSkillEffect("wuzu", 2)	
				room:sendLog(log)				
				for _,p in sgs.qlist(use.to) do
					p:addMark("qinggang")										
				end	
				room:setPlayerFlag(player,"wuzu_used")
				room:useCard(use,false)	
				for _,p in sgs.qlist(use.to) do
					p:removeMark("qinggang")				
				end	
				room:setPlayerFlag(player,"-wuzu_used")
				return true			
		end
	end
	end,
}

qiangqu=sgs.CreateTriggerSkill{
	name="qiangqu",
	events=sgs.Predamage,
	priority=2,	
	on_trigger=function(self,event,player,data)
	if not event==sgs.Predamage then return false end
		local damage=data:toDamage()
		local room=player:getRoom()	
		if not damage.card:inherits("Slash") then return end
		if damage.to:getGeneral():isMale() then return end	
		if not damage.to:isWounded() then return end	
		if damage.to:isKongcheng() 
		and damage.to:getEquips():isEmpty() 
		and damage.to:getJudgingArea():isEmpty() then return end
		local log=sgs.LogMessage()
		log.type = "#qiangqu"
		log.from=player
		if (room:askForSkillInvoke(player,self:objectName())~=true) then return false end
		local card_id=room:askForCardChosen(player,damage.to,"hej",self:objectName())
		if room:getCardPlace(card_id)==sgs.Player_Hand then
			room:moveCardTo(sgs.Sanguosha:getCard(card_id),player,sgs.Player_Hand,false)
		else
			room:obtainCard(player,card_id)
		end
		room:playSkillEffect("qiangqu", math.random(1, 2))	
		log.arg=damage.to:getGeneralName()
		room:sendLog(log)	
		local recover=sgs.RecoverStruct()
		recover.recover=1
		recover.who=player
		room:recover(damage.to,recover)
		room:recover(player,recover)
		return true
	end
}

huatianai=sgs.CreateTriggerSkill{
	name="huatianai",
	events={sgs.Damaged},
	priority=2,	
	on_trigger=function(self,event,player,data)
	local log=sgs.LogMessage()	
	log.from=player
	local room=player:getRoom()	
	if  event==sgs.Damaged then 
		local damage=data:toDamage()
		if damage.damage==0 then return false end		
		local sp=sgs.SPlayerList()
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if (p:isWounded() and p:objectName()~=player:objectName()) then sp:append(p) end				
		end
		if sp:isEmpty() then return false end		
		local x=0
		while x<damage.damage do
		   if room:askForSkillInvoke(player,self:objectName()) then 
		   local target = room:askForPlayerChosen(player, sp, "huatianai")
		   local recover=sgs.RecoverStruct()
		   recover.recover=1
		   recover.who=player
		   room:playSkillEffect("huatianai", math.random(1,2))			   
		   log.type = "#huatianai"
		   log.arg = target:getGeneralName()
		   room:sendLog(log)
		   room:recover(target,recover)           	
		   end	
		   x=x+1		   
		end
		return false  	
	end
end
}
huatiancuo=sgs.CreateTriggerSkill{
	name="huatiancuo",
	events={sgs.HpRecover},
	priority=2,	
	on_trigger=function(self,event,player,data)
	local log=sgs.LogMessage()	
	log.from=player
	local room=player:getRoom()	 	
	if (event==sgs.HpRecover) then
		local recover=data:toRecover()
		local y=0
		while y<recover.recover do
		   if room:askForSkillInvoke(player,self:objectName()) then  
		   local target = room:askForPlayerChosen(player, room:getAlivePlayers(), "huatiancuo")
		   local damage=sgs.DamageStruct()
		   damage.damage=1
		   damage.from=player
		   damage.to=target
		   damage.nature=sgs.DamageStruct_Normal
		   damage.chain=false 
		   room:playSkillEffect("huatiancuo", math.random(1,2))			   
		   log.type = "#huatiancuo"
		   log.arg = target:getGeneralName()
		   room:sendLog(log)
		   room:damage(damage)
		   end        		   
		   y=y+1
		end
	end
end
}

danshu=sgs.CreateTriggerSkill{
	name="danshu",
	events=sgs.SlashEffected,
	priority=3,
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
	if event==sgs.SlashEffected then 	    
		if not player:isWounded() then return end
		local effect=data:toSlashEffect()
		local room=player:getRoom()		
		room:playSkillEffect("danshu",math.random(1, 2))		
		local log=sgs.LogMessage()
		log.type ="#danshu"
		log.arg=player:getGeneralName()
		log.from =effect.from
		room:sendLog(log)
		local x=player:getLostHp()				
		if(room:askForDiscard(effect.from,self:objectName(),x,true,false)) then 
			return false
		else 
			log.type ="#danshunodiscard"
			room:sendLog(log)
			return true
		end
		return false
	end
	end,
}

haoshen_card=sgs.CreateSkillCard{
name="haoshen_effect",
will_throw=false,
once=false,
target_fixed=true,
on_use=function(self,room,source,targets)
	for _,p in sgs.qlist(room:getAlivePlayers()) do
		if  p:hasFlag("haoshen_target")then	
		room:moveCardTo(self, p, sgs.Player_Hand, false)
		return true end			
	end	      
end
}

haoshen_vs=sgs.CreateViewAsSkill{
name="haoshen_vs",
n=99,
view_filter=function(self, selected, to_select)	
	if to_select:isEquipped() then return false
	else return true end
end,
view_as=function(self, cards)
	local x=math.ceil(sgs.Self:getHandcardNum()/2) 
	if #cards==x then 
	local acard=haoshen_card:clone()
	local y=1
	while y<=x do
	acard:addSubcard(cards[tonumber(y)])
	y=y+1
	end		
	return acard end
end,
enabled_at_play=function()
	return sgs.Self:hasFlag("haoshen_source")	
end,
enabled_at_response=function(self,pattern)
	return pattern=="@@haoshen!"	
end
}

haoshen=sgs.CreateTriggerSkill{
name="haoshen",
priority=2,
view_as_skill=haoshen_vs,
events=sgs.PhaseChange,--sgs.CardDiscarded
on_trigger=function(self,event,player,data)
	local room=player:getRoom()	
	local log=sgs.LogMessage()
	log.from=player	
	if event==sgs.PhaseChange then 	   
		if (player:getPhase()==sgs.Player_Draw) then			
				local sp=sgs.SPlayerList()
				local spnum=0
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if(p:getMaxHP() > p:getHandcardNum()) then 
					sp:append(p)
					spnum=spnum+1 
					end			
				end	
				if spnum<1 then return false end
				if(room:askForSkillInvoke(player,self:objectName()) ~=true) then return false end
				log.type ="#haoshendraw"			
				room:sendLog(log)
		   		local target = room:askForPlayerChosen(player, sp, "haoshen")
				if target then
				room:playSkillEffect("haoshen",math.random(1, 4))	
				target:drawCards(target:getMaxHP()-target:getHandcardNum())
				end
				return true
		elseif (player:getPhase()==sgs.Player_Play) then 	 
			if player:isKongcheng() then return end		
			if(room:askForSkillInvoke(player,self:objectName()) ~=true) then return end
				log.type ="#haoshenplay"			
				room:sendLog(log)
				local n=math.ceil(player:getHandcardNum()/2)				
				local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "haoshen")		
				room:setPlayerFlag(target,"haoshen_target")	
				room:setPlayerFlag(player,"haoshen_source")	
				if room:askForUseCard(player, "@@haoshen!", "@haoshen") then				
				room:playSkillEffect("haoshen",math.random(1, 4))
				room:setPlayerFlag(target,"-haoshen_target")
				room:setPlayerFlag(player,"-haoshen_source")						
				return true	end
		end
	end
end,
}

huanshu=sgs.CreateTriggerSkill{
	name="huanshu",
	events=sgs.Damaged,
	on_trigger = function(self,event,player,data)
		local room=player:getRoom()
		local damage=data:toDamage()
		local log=sgs.LogMessage()
		log.from=player		
		local x=0
		if damage.damage==0 then return false end
		while x<damage.damage do
			if  (room:askForSkillInvoke(player,self:objectName())==true) then 
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "huanshu")
			local judge=sgs.JudgeStruct()
			judge.pattern=sgs.QRegExp("(.*)")
			judge.good=true
			judge.reason=self:objectName()
			judge.who=target		
			room:judge(judge)
			if judge.card:isBlack() then 
				local judge2=sgs.JudgeStruct()
				judge2.pattern=sgs.QRegExp("(.*)")
				judge2.good=true
				judge2.reason=self:objectName()
				judge2.who=target		
				room:judge(judge2)
				if judge2.card:isBlack() then 
						local damage=sgs.DamageStruct()
						damage.damage=2
						damage.from=player
						damage.to=target
						damage.nature=sgs.DamageStruct_Thunder 
						damage.chain=true 						
						log.type = "#huanshuthunder"
						log.arg = target:getGeneralName()
						room:sendLog(log)
						room:playSkillEffect("huanshu",math.random(1, 2))	
						room:damage(damage)
				else 
				room:playSkillEffect("huanshu",3)				
				log.type = "#huanshufailed"
				room:sendLog(log)
				end
			elseif judge.card:isRed() then
				local judge2=sgs.JudgeStruct()
				judge2.pattern=sgs.QRegExp("(.*)")
				judge2.good=true
				judge2.reason=self:objectName()
				judge2.who=target		
				room:judge(judge2)
				if judge2.card:isRed() then 
						local damage=sgs.DamageStruct()
						damage.damage=2
						damage.from=player
						damage.to=target
						damage.nature=sgs.DamageStruct_Fire
						damage.chain=true 						
						log.type = "#huanshufire"
						log.arg = target:getGeneralName()
						room:sendLog(log)
						room:playSkillEffect("huanshu",math.random(1, 2))	
						room:damage(damage)
				else 	
				room:playSkillEffect("huanshu",3)
				log.type = "#huanshufailed"
				room:sendLog(log)						
				end
			end		
		end
		x=x+1
		end
		
		return false
	end
}

mozhang=sgs.CreateTriggerSkill{
name="mozhang",
events=sgs.PhaseChange,
frequency=sgs.Skill_Compulsory,
on_trigger=function(self,event,player,data)
	local room=player:getRoom()		
	if player:getPhase()==sgs.Player_Finish then 
		if player:isChained() then return false end	
		room:playSkillEffect("mozhang")			
		local log=sgs.LogMessage()
		log.type ="#mozhang"
		log.from=player		
		room:sendLog(log)	
		player:setChained(true)
		room:broadcastProperty(player, "chained")			
	end
	end,
}

yanshou_card=sgs.CreateSkillCard{
name="yanshou_effect",
target_fixed=true,
will_throw=true,
once=false,
on_use=function(self,room,source,targets)		
	room:throwCard(self)
	room:setPlayerFlag(source,"yanshou_used")
	room:setPlayerFlag(source,"-yanshou_canuse")	
	local t = room:askForPlayerChosen(source, room:getAlivePlayers(), "yanshou")
	room:broadcastInvoke("animate", "lightbox:$yanshou")
	room:playSkillEffect("yanshou")		
	room:setPlayerProperty(t,"maxhp",sgs.QVariant(t:getMaxHP()+1))		
end
}

yanshou_viewAsSkill=sgs.CreateViewAsSkill{
name="yanshou_viewAs",
n=2,
view_filter=function(self, selected, to_select)	
	if to_select:getSuit()==sgs.Card_Heart then return true 
	else return false end
end,
view_as=function(self, cards)
	if #cards==2 then 
	local acard=yanshou_card:clone()	
	acard:addSubcard(cards[1])	
	acard:addSubcard(cards[2])
	acard:setSkillName("yanshou")
	return acard end
end,
enabled_at_play=function()
	if sgs.Self:hasFlag("yanshou_used") then return false
	else return sgs.Self:hasFlag("yanshou_canuse")  end
end,
}

yanshou=sgs.CreateTriggerSkill{
name="yanshou",
priority=2,
view_as_skill=yanshou_viewAsSkill,
frequency=sgs.Skill_Limited,
events=sgs.TurnStart,
on_trigger=function(self,event,player,data)
		local room=player:getRoom()			
		if player:hasFlag("yanshou_used") then return end
		if not player:hasFlag("yanshou_canuse") then
	 		room:setPlayerFlag(player,"yanshou_canuse")
		return end		
end,
}

shsjishi=sgs.CreateTriggerSkill{
name="shsjishi",
can_trigger=function()
return true
end,
events=sgs.TurnStart,
on_trigger=function(self,event,player,data)
	local room=player:getRoom()	
	local andaoquan=room:findPlayerBySkillName(self:objectName())	
	if not player:isWounded() then return end
	if andaoquan:isKongcheng() then return end	
		if(room:askForSkillInvoke(andaoquan,self:objectName()) ~=true) then return false end
		if(room:askForDiscard(andaoquan,self:objectName(),1,true,false)) then 
			room:playSkillEffect("shsjishi",math.random(1, 2))	
			local recover=sgs.RecoverStruct()
			recover.who=andaoquan
			recover.recover=1
			room:recover(player,recover)		
		end			
	return false
end,
}

fengyue=sgs.CreateTriggerSkill{
name="fengyue",
events=sgs.PhaseChange,
frequency=sgs.Skill_Frequent,
on_trigger=function(self,event,player,data)
	local room=player:getRoom()	
	if player:getPhase()==sgs.Player_Finish then 
			local x = 0
			local y=0
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if not p:getGeneral():isMale() then x=x+1 end		
			end
			if x==0 then return false end			
			if x>2 then y=2
			else y=x 
			end	
			if(room:askForSkillInvoke(player,self:objectName()) ~=true) then return false end			
			room:playSkillEffect("fengyue",math.random(1, 2))	
			player:drawCards(y)					
	end
end,
}

hengxing=sgs.CreateTriggerSkill{		
name="hengxing",
priority=1,		
can_trigger=function()
return true
end,
events={sgs.Death,sgs.DrawNCards},
on_trigger=function(self,event,player,data)	
	local room=player:getRoom()
	local gaoqiu=room:findPlayerBySkillName(self:objectName())			
	if (event==sgs.Death) then	
		local x=gaoqiu:getMark("deadcount")	
		if player:hasSkill(self:objectName()) then return false end		
			if x<=0 then				
				room:setPlayerMark(gaoqiu,"deadcount",1)
			elseif x==1 then				
				room:setPlayerMark(gaoqiu,"deadcount",2)
			elseif x>1  then return false 
			end			
    elseif (event==sgs.DrawNCards) then
		if not player:hasSkill(self:objectName()) then return end
		local z=gaoqiu:getMark("deadcount")	
		if z<1 then return end
		if gaoqiu:isWounded() then return end		
			data:setValue(data:toInt()+z)
			room:playSkillEffect("hengxing",math.random(1, 2))
			local log=sgs.LogMessage()
			log.type ="#hengxing"
			log.arg=tostring(z)
			log.from=gaoqiu		
			room:sendLog(log)
			return false		
	end	
end,
}

cuju=sgs.CreateTriggerSkill{
	name="cuju",
	events={sgs.Predamaged},
	priority=2,	
	on_trigger=function(self,event,player,data)
	if not event==sgs.Predamaged then return false end
		if player:isKongcheng() then return end
		local damage=data:toDamage()
		if damage.damage==0 then return end
		local room=player:getRoom()		
		if (room:askForSkillInvoke(player,self:objectName())~=true) then return end				
		local judge=sgs.JudgeStruct()
		judge.pattern=sgs.QRegExp("(.*)")
		judge.good=true
		judge.reason="cuju"
		judge.who=player
		room:judge(judge)
		local log=sgs.LogMessage()	
		log.from=player		
		if judge.card:isBlack() then
			room:setEmotion(player,"good")	
			if not(room:askForDiscard(player,self:objectName(),1,true,false)) then return end
			local target = room:askForPlayerChosen(player,room:getOtherPlayers(player),"cuju")		
			local damagetmp=sgs.DamageStruct()
			damagetmp.damage=damage.damage
			damagetmp.from=damage.from
			damagetmp.to=target
			damagetmp.nature=damage.nature
			damagetmp.chain=damage.chain 			
			log.type="#cuju"			
			log.arg = target:getGeneralName()
			room:sendLog(log)
			room:playSkillEffect("cuju",math.random(1, 2))
			room:damage(damagetmp)
			return true
		else
			log.type="#cujufailed"
			room:setEmotion(player,"bad")
			room:sendLog(log)
			return false
		end
	end	
}

panquan_card=sgs.CreateSkillCard{
name="panquan_effect",
will_throw=false,
once=true,
target_fixed=true,
on_use=function(self,room,source,targets)		
		room:moveCardTo(self,nil,sgs.Player_DrawPile,true)			
		return true
end
}

panquan_vs=sgs.CreateViewAsSkill{
name="panquan_vs",
n=1,
view_filter=function(self, selected, to_select)	
	if to_select:isEquipped() then return false
	else return true end
end,
view_as=function(self,cards)	
	if #cards==1 then 
	local acard=panquan_card:clone()	
	acard:addSubcard(cards[1])			
	return acard
	end
end,
enabled_at_play=function()
	return false	
end,
enabled_at_response=function(self,pattern)
	return pattern=="@@panquan!"	
end
}

panquan=sgs.CreateTriggerSkill{
	name="panquan$",
	events={sgs.HpRecover},
	priority=2,
	view_as_skill=panquan_vs,
	can_trigger=function()
	return true
	end,
	on_trigger=function(self,event,player,data)
	if  player:getKingdom()~="wei" then return false end
	local room=player:getRoom()	
	local log=sgs.LogMessage()
	local gaoqiu=room:findPlayerBySkillName(self:objectName())	
	log.from=gaoqiu	
	if player:objectName()== gaoqiu:objectName() then return false end	
	if (event==sgs.HpRecover) then
		local recover=data:toRecover()
		if recover.recover==0 then return false end	
		local control=0	
		while control<recover.recover do		
			if (room:askForChoice(player,self:objectName(), "agree+ignore") == "agree") then 
				room:playSkillEffect("panquan",math.random(1, 2))	
				gaoqiu:drawCards(2)					
				local cc=false
				repeat				
				cc=room:askForUseCard(gaoqiu, "@@panquan!","@panquan")	
				until cc==true
			end
		control=control+1
		end		
	end
	return false
end
}

qimen=sgs.CreateTriggerSkill{
name="qimen",
priority=1,
can_trigger=function()
return true
end,
events={sgs.TurnStart,sgs.FinishJudge,sgs.PhaseChange,sgs.Death},
on_trigger=function(self,event,player,data)
	local room=player:getRoom()	
	local gongsunsheng=room:findPlayerBySkillName(self:objectName())	
	local totransfigure="a"	
	local log=sgs.LogMessage()
	if (event==sgs.TurnStart) then 
		 if not (gongsunsheng) then return end
		 if(room:askForSkillInvoke(gongsunsheng,self:objectName()) ~=true) then return false end	
	 	 local target = room:askForPlayerChosen(gongsunsheng, room:getAlivePlayers(), "qimen")  		 
		  if target:getGeneral():isMale() then
		 	 totransfigure ="sujiang"
		  else totransfigure ="sujiangf" end		
		 local judge=sgs.JudgeStruct()
		 judge.pattern=sgs.QRegExp("(.*):(.*):(.*)")
		 judge.good=true
		 judge.reason="qimen"
		 judge.who=target
		 room:judge(judge)
		 if gongsunsheng:hasFlag("qimen_good") then
		 room:setPlayerFlag(player,"qimen_start")		 
		      room:setEmotion(target, "bad")
		 	  room:setEmotion(gongsunsheng, "good")				 
			  log.from=gongsunsheng
			  log.arg=target:getGeneralName()
			  log.type="#qimen"
			  room:sendLog(log)	
			  room:playSkillEffect("qimen",math.random(1, 2))	
			  local datatmp=sgs.QVariant(0)
		      datatmp:setValue(target)
		      gongsunsheng:setTag("qimentarget",datatmp)
		      table.insert(qmtarget,datatmp)			  
			  local backkingdom=target:getKingdom()
			  local back=target:getGeneralName()
			  for _,sk in sgs.qlist(target:getVisibleSkillList()) do
			  		if (sk:objectName()~="spear" and sk:objectName()~="axe") then
			  		table.insert(skills,sk:objectName())					
					target:loseSkill(sk:objectName())
					room:broadcastInvoke("detachSkill",target:objectName()..":"..sk:objectName())
					end					
			  end		 	 
			  table.insert(qmkingdom,backkingdom)
			  table.insert(qmgeneral,back)
			  local kingdom= backkingdom
			  room:setPlayerProperty(target,"general",sgs.QVariant(totransfigure))
			  room:setPlayerProperty(target,"kingdom",sgs.QVariant(kingdom))
			  room:setPlayerFlag(gongsunsheng,"-qimen_good")				  
		 else								
		 	  room:setEmotion(gongsunsheng, "bad")	
    	 end   	
	elseif(event==sgs.FinishJudge)	then
		if not (gongsunsheng) then return end
		local judge = data:toJudge()
		if(judge.reason == "qimen" ) then
		    local suit=judge.card:getSuitString()			
			suit="."..suit:sub(1,1):upper()			
			local cz=room:askForCard(gongsunsheng,suit,"@qimen",data)
			if cz~=nil then
			room:setPlayerFlag(gongsunsheng,"qimen_good")			
			end			
		end			
	elseif ((event==sgs.PhaseChange) and player:getPhase()==sgs.Player_Finish) then	
		if (not player:hasFlag("qimen_start")) then return end		
		--if #qmtarget==0 then return false end
		room:setPlayerFlag(player,"-qimen_start")			
		local tar=qmtarget[1]:toPlayer()
		local back=qmgeneral[1]
		local backkingdom=qmkingdom[1]		
		room:setPlayerProperty(tar,"general",sgs.QVariant(back))
		room:setPlayerProperty(tar,"kingdom",sgs.QVariant(backkingdom))				
		log.type="#qimenend"		
		log.arg=tar:getGeneralName()
		room:sendLog(log)
		for _,s in ipairs(skills) do			  		
			tar:acquireSkill(s)
			tar:invoke("attachSkill",s)							
	    end			
		for x=1,#skills,1 do
		table.remove(skills)		
		end		
		table.remove(qmtarget)
		table.remove(qmgeneral)
		table.remove(qmkingdom)			
		return true	
	elseif (event==sgs.Death) then
		if player:hasSkill("qimen") then
		--if #qmtarget==0 then return false end
		room:setPlayerFlag(player,"-qimen_start")
		for _,p in sgs.qlist(room:getAllPlayers()) do
			room:setPlayerFlag(p,"-qimen_start")				
		end			
		local tar=qmtarget[1]:toPlayer()
		local back=qmgeneral[1]
		local backkingdom=qmkingdom[1]
		room:setPlayerProperty(tar,"general",sgs.QVariant(back))
		room:setPlayerProperty(tar,"kingdom",sgs.QVariant(backkingdom))					
		log.type="#qimenend"		
		log.arg=tar:getGeneralName()
		room:sendLog(log)
		for _,s in ipairs(skills) do			  		
			tar:acquireSkill(s)
			tar:invoke("attachSkill",s)							
	    end			
		for x=1,#skills,1 do
		table.remove(skills)		
		end		
		table.remove(qmtarget)
		table.remove(qmgeneral)
		table.remove(qmkingdom)	
		return false end
	end			
end,
}

yixing=sgs.CreateTriggerSkill{
	name="yixing",
	events=sgs.AskForRetrial,	
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local gongsunsheng=room:findPlayerBySkillName(self:objectName())
		local judge=data:toJudge()			
		gongsunsheng:setTag("Judge",data)			     
        local sp=sgs.SPlayerList()
		for _,p in sgs.qlist(room:getAllPlayers()) do			
			if not p:getEquips():isEmpty() then
			sp:append(p)
			end			
		end
        if sp:isEmpty() then return false end		
        if (room:askForSkillInvoke(gongsunsheng,self:objectName())~=true) then return false end		
		local target = room:askForPlayerChosen(gongsunsheng, sp, self:objectName())			
		local card_id=room:askForCardChosen(gongsunsheng,target,"e",self:objectName())		
		local card=sgs.Sanguosha:getCard(card_id)		
		target:obtainCard(judge.card)
		judge.card=card				
		room:moveCardTo(judge.card,judge.who, sgs.Player_Special, true)
		local log=sgs.LogMessage()
		log.type = "$ChangedJudge"
		log.from=gongsunsheng
	    log.to:append(judge.who)
		log.card_str =card:getEffectIdString()
		room:sendLog(log)
		room:playSkillEffect("yixing",math.random(1, 2))		
		return false
	end,	
}

baoguo=sgs.CreateTriggerSkill{
	name="baoguo",
	events={sgs.Predamaged,sgs.Damaged},
	priority=2,
	can_trigger=function()
		return true
	end,	
	on_trigger=function(self,event,player,data)		
		local room=player:getRoom()	
		local lujunyi=room:findPlayerBySkillName(self:objectName())
		local log=sgs.LogMessage()
		log.from=lujunyi
		if (event==sgs.Damaged) then 		 			
			if player:hasSkill(self:objectName()) and player:isAlive() then							
		   		local damage=data:toDamage()
				local x=player:getLostHp()		   		
		   		log.type = "#baoguo"
		   		log.arg=tostring(x)
		   		room:sendLog(log)	
				room:playSkillEffect("baoguo",math.random(1, 2))									
		   		player:drawCards(x)	
				return false
        	end		   
        elseif (event==sgs.Predamaged) then		   
        	local damage=data:toDamage()
		    if player:hasSkill(self:objectName()) then return end
		    if lujunyi:isNude() then return end
		    if (room:askForSkillInvoke(lujunyi,self:objectName())~=true) then return false end
		    room:askForDiscard(lujunyi,self:objectName(),1,false,true) 
		    log.type ="#baoguodamage"
		    log.arg=damage.to:getGeneralName()
		    log.arg2=tostring(damage.damage)
		    room:sendLog(log)	
		    local damagetmp=sgs.DamageStruct()
		    damagetmp.damage=damage.damage
		    damagetmp.from=damage.from
		   	damagetmp.to=lujunyi
		   	damagetmp.nature=damage.nature
		   	damagetmp.chain=damage.chain						
		   	room:damage(damagetmp)
		    return true
		end
	end,
}

hongjin=sgs.CreateTriggerSkill{
	name="hongjin",
	events={sgs.Damage},
	priority=1,
	on_trigger=function(self,event,player,data)
	if (event==sgs.Damage) and player:getPhase()==sgs.Player_Play then 
		local damage=data:toDamage()
		local room=player:getRoom()			
		local log=sgs.LogMessage()
		log.from=player			
		if not damage.to:getGeneral():isMale() then return end
		if damage.to:isNude() then 
			log.type ="#hongjindraw"				  
			room:sendLog(log)
			room:playSkillEffect("hongjin",2)
			player:drawCards(1)		
		elseif (room:askForChoice(player,self:objectName(), "discard+draw") ~= "draw") then
		    log.type ="#hongjindiscard"
		    log.arg=damage.to:getGeneralName()		  
		    room:sendLog(log)			
		    local card_id=room:askForCardChosen(player,damage.to,"he",self:objectName())
			room:playSkillEffect("hongjin",1)
		    room:throwCard(card_id)
		else
			log.type ="#hongjindraw"				  
			room:sendLog(log)
			room:playSkillEffect("hongjin",2)
			player:drawCards(1)
		
		end
	end
	end,
}

wuji_card=sgs.CreateSkillCard{
name="wujieffect",
target_fixed=true,
will_throw=false,
once=false,
on_use=function(self,room,source,targets)
	room:throwCard(self);
    if(source:isAlive()) then
	local log=sgs.LogMessage()
	log.from=source
	log.type ="#wuji"				  
	room:sendLog(log)
	room:playSkillEffect("wuji",math.random(1, 2))
    room:drawCards(source, self:getSubcards():length())
	end
end
}

wuji=sgs.CreateViewAsSkill{
name="wuji",
n=99,
view_filter=function(self, selected, to_select)			
	return to_select:inherits("Slash") 
end,
view_as=function(self, cards)	
	if #cards==0 then return end
	local acard=wuji_card:clone()
    for var=1,#cards,1 do	
	acard:addSubcard(cards[var])		
	end	
	acard:setSkillName(self:objectName())
	return acard	
end,
enabled_at_play=function()
	return true    
end,
}

ganlin_card=sgs.CreateSkillCard{
name="ganlincard",
target_fixed=true,
will_throw=false,
once=false,
on_use=function(self,room,source,targets)
	local log=sgs.LogMessage()
	log.from=source
	log.type ="#ganlin"				  
	room:sendLog(log)
	local t = room:askForPlayerChosen(source, room:getOtherPlayers(source), "ganlin")	
	room:playSkillEffect("ganlin",math.random(1, 2))
	room:moveCardTo(self,t,sgs.Player_Hand,false)				
	if(source:isWounded())then	
		local x=source:getLostHp()
		local y=source:getHandcardNum()
	    if source:isKongcheng() then		  
			if (x-y<=0) then return end
			log.type ="#ganlindraw"	
			log.arg=tostring(x-y)	
			room:sendLog(log)			
    		room:drawCards(source,x-y)			
			room:setPlayerFlag(source,"-ganlin_canuse")
		elseif (x-y>0) then 	
		    if (room:askForChoice(source, self:objectName(), "draw+no") ~= "no") then 
				local x=source:getLostHp()
				local y=source:getHandcardNum()			
				log.type ="#ganlindraw"	
				log.arg=tostring(x-y)	
				room:sendLog(log)				
    			room:drawCards(source,x-y)			
				room:setPlayerFlag(source,"-ganlin_canuse")
			end	
		end	
	else return true
	end
end,
}

ganlinvs=sgs.CreateViewAsSkill{
name="ganlinvs",
n=99,
view_filter=function(self, selected, to_select)
	if to_select:isEquipped() then return false end			
	return true 
end,
view_as=function(self, cards)	
	if #cards==0 then return end
	local acard=ganlin_card:clone()
    for var=1,#cards,1 do	
	acard:addSubcard(cards[var])		
	end	
	acard:setSkillName(self:objectName())
	return acard	
end,
enabled_at_play=function()
	return sgs.Self:hasFlag("ganlin_canuse")    
end,
}

ganlin=sgs.CreateTriggerSkill{
name="ganlin",
view_as_skill=ganlinvs,
events=sgs.PhaseChange,
on_trigger=function(self,event,player,data)
	local room=player:getRoom()		
	if player:getPhase()==sgs.Player_Play then 	    
	   room:setPlayerFlag(player,"ganlin_canuse")
    end	   
end,
}

juyi_card=sgs.CreateSkillCard{
name="juyicard",
target_fixed=true,
will_throw=false,
once=true,
on_use=function(self,room,source,targets)	
	local t=room:findPlayerBySkillName("juyi") 
	if t:isDead() then return end
	local log=sgs.LogMessage()
	if (room:askForSkillInvoke(source,"juyi")~=true) then return false end	
	if (room:askForChoice(t,self:objectName(), "yes+no") ~= "yes") then 
	log.from=source
	log.arg=t:objectName()
	log.type ="#juyino"				  
	room:sendLog(log)	 
	return true end	
	log.from=source
	log.arg=t:objectName()
	log.type ="#juyi"				  
	room:sendLog(log)	 
	local to_exchange=t:wholeHandCards()  
    local to_exchange2=source:wholeHandCards()  
	room:playSkillEffect("juyi",math.random(1, 2))
	if not t:isKongcheng() then
    room:moveCardTo(to_exchange,source,sgs.Player_Hand,false)
	end	
    room:moveCardTo(to_exchange2,t,sgs.Player_Hand,false) 	
	room:setPlayerFlag(source,"-juyi_canuse")
end
}

juyi_vs=sgs.CreateViewAsSkill{
name="juyi_vs",
n=0,
view_filter=function(self,selected,to_select)
	return true
end,
view_as=function(self,cards)
	if #cards==0 then
	local acard=juyi_card:clone()	
	return acard
	end
end,
enabled_at_play=function()
	return  sgs.Self:hasFlag("juyi_canuse")
	and sgs.Self:getKingdom()=="qun"
end,
}

juyiother=sgs.CreateTriggerSkill{
name="juyiother",
view_as_skill=juyi_vs,
events=sgs.PhaseChange,
on_trigger=function(self,event,player,data)	
	if player:hasSkill("ganlin") then return end
	local room=player:getRoom()		
	if player:getPhase()==sgs.Player_Play then
		room:setPlayerFlag(player,"juyi_canuse")
	elseif player:getPhase()==sgs.Player_Finish then 	    
		room:setPlayerFlag(player,"-juyi_canuse")	
	end
end,
}

juyi=sgs.CreateGameStartSkill{
name="juyi$",
on_gamestart=function(self,player)
	local room=player:getRoom()	
	local log=sgs.LogMessage()
	log.from=player
	log.type ="#juyidebug"	
	for _,sk in sgs.qlist(player:getVisibleSkillList()) do
			  	if (sk:objectName()=="juyiother") then
			  		table.insert(skills,sk:objectName())					
					player:loseSkill(sk:objectName())
					room:broadcastInvoke("detachSkill",player:objectName()..":"..sk:objectName())
				end					
	end			  	
	for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:objectName()~=player:objectName() then
			log.from=p
			room:sendLog(log)					
			p:acquireSkill(skills[1])
			p:invoke("attachSkill",skills[1])		
			end
	end
	table.remove(skills)
end,
}

--[[ 官 ]]--
gaoqiu=sgs.General(extension,"gaoqiu$","wei",3)
gaoqiu:addSkill(hengxing)
gaoqiu:addSkill(cuju)
gaoqiu:addSkill(panquan)

zhangqing=sgs.General(extension,"zhangqing","wei")
zhangqing:addSkill(yinyu)
zhangqing:addSkill(yinyu_heart)

chaijin=sgs.General(extension,"chaijin","wei",3)
chaijin:addSkill(danshu)
chaijin:addSkill(haoshen) 

lujunyi=sgs.General(extension,"lujunyi","wei")
lujunyi:addSkill(baoguo)
--[[民]]--
yuehe=sgs.General(extension,"yuehe","wu",3)
yuehe:addSkill(yueli)
yuehe:addSkill(taohui)

andaoquan = sgs.General(extension,"andaoquan","wu",3)
andaoquan:addSkill(shsjishi)
andaoquan:addSkill(yanshou)
andaoquan:addSkill(fengyue)

--[[将]]--
muhong = sgs.General(extension,"muhong","shu")
muhong:addSkill(wuzu)
muhong:addSkill(huqi)

husanniang = sgs.General(extension,"husanniang","shu",3,false)
husanniang:addSkill(hongjin)
husanniang:addSkill(wuji)

--[[寇]]--
songjiang = sgs.General(extension,"songjiang$","qun")
songjiang:addSkill(ganlin)
songjiang:addSkill(juyi)
songjiang:addSkill(juyiother) --这个技能其实是分发给其它角色的,不在此处添加,其它角色将不会出现该技能按钮

zhoutong = sgs.General(extension,"zhoutong","qun",3)
zhoutong:addSkill(qiangqu)
zhoutong:addSkill(huatianai)
zhoutong:addSkill(huatiancuo)

qiaodaoqing = sgs.General(extension,"qiaodaoqing","qun",3)
qiaodaoqing:addSkill(huanshu)
qiaodaoqing:addSkill(mozhang)

gongsunsheng = sgs.General(extension,"gongsunsheng","qun",3)
gongsunsheng:addSkill(yixing)
gongsunsheng:addSkill(qimen) --此处同花色判断只能用于“手牌”

sgs.LoadTranslationTable{
	["SHSTTXD"]="替天行道",		
	["zhangqing"]="张清",
	["yinyu"]="饮羽",	
	["yinyu_heart"]="石影",
	[":yinyu_heart"]="<b>锁定技</b>,若“饮羽”的判定结果为<b><font color='red'>♥</font></b>,你的攻击范围无限.",	
	[":yinyu"]="—回合开始阶段,你可以进行一次判定,获得与判定结果对应的一项技能直到回合结束：\
	<b><font color='red'>♥</font></b>~攻击范围无限;\
	<b><font color='red'>♦</font></b>~使用的【杀】不可被闪避;\
	♠~可使用任意数量的【杀】;\
	♣~无视其他角色的防具.",
	["#yinyu_diamond"]="%from的技能“<b><font color='red'>饮羽</font></b>”被触发,目标不可闪避该【杀】",
	["#yinyu_club"]="%from的技能“<b><font color='red'>饮羽</font></b>”被触发,无视该角色的防具",
	["#yinyu_heart"]="你不能对该角色使用该锦囊",
	["#yinyuHeart"]="本回合%from的攻击范围无限",
	["#yinyuDiamond"]="本回合%from的【杀】不可被闪避",
	["#yinyuClub"]="本回合%from无视其他角色的防具",
	["#yinyuSpade"]="本回合%from可以使用任意数量的【杀】",
	["@yinyu_heart"]="请使用一张【杀】",
	["@yinyu_spade"]="请使用一张【杀】",
	["~zhangqing"]="一技之长,不足傍身啊！",
	["$yinyu1"]="飞蝗如雨,看尔等翻成画饼!",
	["$yinyu2"]="飞石连伤,休想逃跑!",
	["$yinyu3"]="叫汝等饮羽沙场吧!",
	["$yinyu4"]="此等破铜烂铁岂能挡我!",
	["$yinyu5"]="看你马快,还是我飞石快!",
	
	["yuehe"]="乐和",
	["yueli"]="乐理",
	[":yueli"]="若你的判定牌为基本牌,在其生效后,你可以获得之.",
	["#yueli"]="%from的技能“<b><font color='red'>乐理</font></b>”被触发,他悄悄拿走了判定牌",
	["taohui"]="韬晦",
	[":taohui"]="回合结束阶段,你可以进行一次判定:若结果不为基本牌,你可以令任一角色摸一张牌,并可以再次使用“韬晦”——如此反复,直到出现基本牌为止.",
	["#taohui"]="%from的技能“<b><font color='red'>韬晦</font></b>”被触发,%arg陶醉在优美的音律中",
	["~yuehe"]="叫子也难吹奏了。",
	["$yueli1"]="呵呵～",
	["$yueli2"]="且慢,音律有误。",	
	["$taohui1"]="白云起,郁披香;离复合,曲未央。",
	["$taohui2"]="此曲只应天上有,人间能得几回闻。",

	["muhong"]="穆弘",
	["wuzu"]="无阻",
	[":wuzu"]="<b>锁定技</b>,你始终无视其他角色的防具.",
	["#wuzu"]="%from的技能“<b><font color='yellow'>无阻</font></b>”被触发,%from无视其他角色的防具",	
	["huqi"]="虎骑",
	[":huqi"]="<b>锁定技</b>,当你计算与其他角色的距离时,始终-1.",
	["~muhong"]="弟,兄先去矣。",
	["$wuzu1"]="谁敢拦我?",
	["$wuzu2"]="游击部,冲!",	
	
	["zhoutong"]="周通",
	["qiangqu"]="强娶",
	[":qiangqu"]="当你使用【杀】对已受伤的女性角色造成伤害时,你可以防止此伤害,改为获得该角色的一张牌若如此做,你和她各回复1点体力.",
	["#qiangqu"]="%from硬是把%arg拉入了洞房",
	["huatianai"]="花田·爱",
	[":huatianai"]="你每受到1点伤害,可以令任一已受伤的其他角色回复1点体力.",
	["huatiancuo"]="花田·错",
	[":huatiancuo"]="你每回复1点体力,可以对任一其他角色造成1点伤害.",
	["#huatianai"]="%from与%arg爱来爱去,死去活来",
	["#huatiancuo"]="%arg嘤咛一声倒在了花田中,看样子是中了情毒",
	["$qiangqu1"]="小娘子,春宵一刻值千金啊!",
	["$qiangqu2"]="今夜,本大王定要做新郎!",
	["$huatianai1"]="无妨,只当为汝披嫁纱！",
	["$huatianai2"]="只要娘子开心,怎样都好！",
	["$huatiancuo1"]="破晓之前,忘了此错。",
	["$huatiancuo2"]="无心插柳,岂是花田之错？",
	["~zhoutong"]="虽有霸王相,奈无霸王功啊!",
	
	["chaijin"]="柴进",
	["danshu"]="丹书",
	[":danshu"]="<b>锁定技</b>,当其他角色使用【杀】指定你为目标时,须额外弃置X张手牌,X为你已损失的体力值,否则该【杀】对你无效.",
	["haoshen"]="豪绅",
	[":haoshen"]="你可以跳过你的摸牌阶段,令任一其他角色将手牌补至其体力上限的张数;\
        你可以跳过你的出牌阶段,将一半的手牌（向上取整）交给任一其他角色.", 
	["haoshen_vs"]="豪绅·2",
	[":haoshen_vs"]="当你发动豪绅跳过出牌阶段时,此技能生效.",
	["#danshu"]="%from 的技能“<b><font color='yellow'>丹书</font></b>”被触发,%arg须额外弃牌才能使该【杀】生效",
	["#danshunodiscard"]="%from使用的【杀】对%arg无效",
	["#haoshendraw"]="%from跳过了<b><font color='blue'>摸牌</font></b>阶段,可以令一名其他角色将手牌补至其体力上限的张数",
	["#haoshenplay"]="%from跳过了<b><font color='blue'>出牌</font></b>阶段,可以将一半的手牌（向上取整）交给一名其他角色",	
	["$danshu1"]="丹书铁券在此,刀斧不得加身!",
	["$danshu2"]="御赐丹书铁券,可保祖孙三代!",
	["$haoshen1"]="兄弟有难,必当拔刀相助！",
	["$haoshen2"]="吾好结交天下各路英雄。",
	["$haoshen3"]="碎银铺路,富贵如云。",
	["$haoshen4"]="既是兄弟,理应有福同享。",
	["~chaijin"]="辞官回乡罢了～",
	["@haoshen"]="请选择一半的手牌（向上取整）,然后点击[确定]",
	
	["qiaodaoqing"]="乔道清",
	["huanshu"]="幻术",
	[":huanshu"]="你每受到1点伤害,可以令任一其他角色连续进行两次判定:\
        若结果均为<b><font color='red'>红色</font></b>,你对其造成2点火焰伤害;\
        若结果均为黑色,你对其造成2点雷电伤害.",
	["mozhang"]="魔障",
	[":mozhang"]="<b>锁定技</b>,你的回合结束时,若你未处于横置状态,你须横置你的武将牌.",
	["#huanshufire"]="%arg受到%from的技能“<b><font color='red'>幻术</font></b>”的影响,仿佛置身于火海之中",
	["#huanshuthunder"]="%arg受到%from的技能“<b><font color='red'>幻术</font></b>”的影响,尝到了五雷轰顶的滋味",
	["#huanshufailed"]="%from发动了技能“<b><font color='red'>幻术</font></b>”,结果却连个屁声都听不到",
	["#mozhang"]="%from的技能“<b><font color='yellow'>魔障</font></b>”被触发,%from进入连环状态",
	["$huanshu1"]="沙石一起,真假莫辨!",
	["$huanshu2"]="五行幻化,破!",
	["$huanshu3"]="五雷天心,五雷天心,缘何不灵?",
	["$mozhang"]="外道之法,也可乱心?",
	["~qiaodaoqing"]="这,就是五雷轰顶的滋味吗?",
	
	["andaoquan"]="安道全",
	["shsjishi"]="济世",
	[":shsjishi"]="任意角色的回合开始时,若该角色已受伤,你可以弃置一张手牌,令其回复1点体力.",
	["yanshou"]="延寿",
	[":yanshou"]="<b>限定技</b>,出牌阶段,你可以弃置两张<b><font color='red'>♥</font></b>牌,令任一角色增加1点体力上限.",
	["fengyue"]="风月",
	[":fengyue"]="回合结束阶段,你可以摸X张牌,X为场上存活的女性角色数且至多为2.每回合限一次.",
	["$yanshou"]="助你延寿十年!",
	["$shsjishi1"]="祖传内科外科尽皆医得。",
	["$shsjishi2"]="回春之术!",
	["$fengyue1"]="一生风月供惆怅。",
	["$fengyue2"]="活色生香伴佳人。",
	["~andaoquan"]="救人易,救己难！",
	
	["gaoqiu"]="高俅",
	["hengxing"]="横行",
	[":hengxing"]="摸牌阶段,若你未受伤,可以额外摸X张牌,X为已死亡的角色数且至多为2.",
	["cuju"]="蹴鞠",
	[":cuju"]="每当你受到伤害时,可以进行一次判定:若结果为♠或♣,你可以弃置一张手牌,将该伤害转移给任一其他角色.",
	["panquan"]="攀权",
	[":panquan"]="<b>主公技</b>,其他官势力角色每回复1点体力,可以让你摸两张牌,然后你将一张手牌置于牌堆顶.",
	["#hengxing"]="%from的技能“<b><font color='red'>横行</font></b>”被触发,将额外摸%arg张牌",
	["#hengxingdeath"]="%arg this",
	["#cuju"]="%from将伤害踢给了%arg",
	["#cujufailed"]="%from“<b><font color='red'>蹴鞠</font></b>”不赖,只可惜进了国家队,怎么都射不出来",
	["#panquan"]="%arg发动技能“<b><font color='blue'>攀权</font><b>”,%from摸了2张牌",
	["@panquan"]="请选择一张手牌,然后点击[确定],这张牌将被置于牌堆顶",
	["panquan:agree"]="发动攀权,令高俅摸2张牌",
	["panquan:ignore"]="放弃攀权",
	["$hengxing1"]="安敢辄入白虎节堂,可知法度否?",
	["$hengxing2"]="哼!不认得我?!",
	["$cuju1"]="看我入那风流眼!",
	["$cuju2"]="有此绝技,休想伤我!",
	["$panquan1"]="圣上有旨!",
	["$panquan2"]="共求富贵!",
	["~gaoqiu"]="报应啊～报应!",
	
	["gongsunsheng"]="公孙胜",
	["yixing"]="移星",
	[":yixing"]="在任意角色的判定牌生效前,你可以用任一角色装备区里的一张牌替换之(替换后,该角色将获得该判定牌).",
	["qimen"]="奇门",
	[":qimen"]="任意角色的回合开始时,你可以令任一角色进行一次判定,若你弃置一张与该判定牌相同花色的手牌,则该角色不能发动当前的所有技能直到回合结束.",
	["@qimen"]="请弃置一张与判定牌相同花色的手牌,然后点击[确定]",	 
	["#qimen"]="%from的技能“<b><font color='blue'>奇门</font><b>”被触发,%arg不能发动当前的所有技能直到回合结束",	
	["#qimenend"]="“<b><font color='blue'>奇门</font><b>”的作用失效,%arg仿佛获得了重生",
	["$yixing1"]="天命有旋转,地星而应之。",
	["$yixing2"]="夜道极阴,昼道极阳。",
	["$qimen1"]="汝逢大凶,不宜出兵再战。",
	["$qimen2"]="小奇改门户,大奇变格局。",
	["~gongsunsheng"]="天罡尽已归天界,地煞还应入地中。",	
	
	["lujunyi"]="卢俊义",
	["baoguo"]="报国",
	[":baoguo"]="每当其他角色受到伤害时,你可以弃置一张牌,将此伤害转移给你;你每受到一次伤害,可以摸X张牌,X为你已损失的体力值.",	
	["#baoguo"]="%from的技能“<b><font color='green'>报国</font><b>被触发”,%from摸了%arg张牌",
	["#baoguodamage"]="%from的技能“<b><font color='green'>报国</font><b>被触发”,%from替%arg承受了%arg2点伤害",
	["$baoguo1"]="大丈夫为国尽忠,死而无憾!",
	["$baoguo2"]="与其坐拥金山,不如上阵杀敌!",
	["~lujunyi"]="我,生为大宋人,死为大宋鬼!",
	
	["husanniang"]="扈三娘",
	["hongjin"]="红锦",
	[":hongjin"]="出牌阶段,你每对男性角色造成一次伤害,可以执行下列两项中的一项:\
        1.摸一张牌;\
        2.弃掉该角色的一张牌.",
	["hongjin:draw"]="摸一张牌",
	["hongjin:discard"]="弃掉该角色的一张牌",
	["hongjin:draw"]="摸一张牌",
	["#hongjindiscard"]="%from发动技能“<b><font color='red'>红锦</font><b>”,%from弃掉了%arg的1张牌",
	["#hongjindraw"]="%from发动技能“<b><font color='red'>红锦</font><b>”,%from摸了1张牌",
	["wuji"]="武姬",
	[":wuji"]="出牌阶段,你可以弃置任意数量的【杀】,然后摸等量的牌.",	
	["#wuji"]="%from发动了技能“<b><font color='red'>武姬</font><b>”",	
	["$hongjin1"]="一击枫叶落!",
	["$hongjin2"]="玉纤擒猛将,霜刀砍雄兵！",	
	["$wuji1"]="巾帼不让须眉!",
	["$wuji2"]="连环铠甲衬红纱。",
	["~husanniang"]="卿本佳人,奈何从贼?",
	
	["songjiang"]="宋江",
	["ganlin"]="甘霖",
	[":ganlin"]="出牌阶段,你可以将任意数量的手牌以任意分配方式交给其他角色.若如此做,你可以将手牌补至X张,X为你已损失的体力值(补牌之后,将不能再次发动本技能).",
	["ganlincard"]="甘霖",
	["ganlincard:draw"]="将手牌补至X张,X为你已损失的体力值",
	["ganlincard:no"]="放弃补牌(可以再次发动“甘霖”)",
	["juyi"]="聚义",
	[":juyi"]="<b>主公技</b>,其他寇势力角色可在他们各自的出牌阶段与你交换一次手牌（你可以拒绝）.",
	["#ganlin"]="%from发动了技能“<b><font color='yellow'>甘霖</font><b>”",
	["#ganlindraw"]="%from的技能“<b><font color='yellow'>甘霖</font><b>”被触发,%from摸了%arg张牌",
	["#juyi"]="%from发动了技能“<b><font color='yellow'>聚义</font><b>”,将与%arg交换所有手牌",
	["#juyino"]="%arg拒绝了%from“<b><font color='yellow'>聚义</font><b>”的请求",
	["#juyidebug"]="%from this time!",
	["juyiother"]="聚义(换牌)",
	[":juyiother"]="出牌阶段,你可以与主公宋江交换所有手牌.每回合限一次.",
	["juyicard"]="聚义(换牌)",
	["juyicard:yes"]="与该角色交换所有手牌",
	["juyicard:no"]="拒绝",	
	["$ganlin1"]="扶危济困,急人所难。",
	["$ganlin2"]="在下正是山东及时雨宋公明。",
	["$juyi1"]="替天行道!",
	["$juyi2"]="我等上应天星,合当聚义!",
	["~songjiang"]="何时方能报效朝廷?",	
	
	["designer:zhangqing"]="烨子 LUA:roxiel",
	["designer:yuehe"]="烨子 LUA:roxiel",
	["designer:muhong"]="烨子 LUA:roxiel",
	["designer:zhoutong"]="烨子 LUA:roxiel",
	["designer:chaijin"]="烨子&小花荣 LUA:roxiel",
	["designer:qiaodaoqing"]="烨子 LUA:roxiel",
	["designer:andaoquan"]="烨子 LUA:roxiel",
	["designer:gaoqiu"]="烨子 LUA:roxiel",
	["designer:gongsunsheng"]="烨子 LUA:roxiel",
	["designer:lujunyi"]="烨子 LUA:roxiel",
	["designer:husanniang"]="烨子 LUA:roxiel",
	["designer:songjiang"]="烨子&凌天翼 LUA:roxiel",
	
	["cv:zhangqing"]="烨子",
	["cv:yuehe"]="烨子",
	["cv:muhong"]="爪子",
	["cv:zhoutong"]="烨子",
	["cv:chaijin"]="烨子",
	["cv:qiaodaoqing"]="烨子",
	["cv:andaoquan"]="烨子",
	["cv:gaoqiu"]="爪子",
	["cv:gongsunsheng"]="黑马之殇【KA.U】",
	["cv:lujunyi"]="声声melody猎狐",
	["cv:husanniang"]="明日如歌",
	["cv:songjiang"]="声声melody猎狐",
}