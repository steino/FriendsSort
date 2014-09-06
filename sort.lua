local FriendButtons = { count = 0 }

function FriendsSort_Update()
  local numBNetTotal, numBNetOnline = BNGetNumFriends()
	local numBNetOffline = numBNetTotal - numBNetOnline
	local numWoWTotal, numWoWOnline = GetNumFriends()
	local numWoWOffline = numWoWTotal - numWoWOnline

	FriendsMicroButtonCount:SetText(numBNetOnline + numWoWOnline)
  	if ( not FriendsListFrame:IsShown() ) then
		return;
	end

  local haveHeader;
	local buttonCount = numBNetTotal + numWoWTotal;
	if ( (numBNetOnline > 0 or numWoWOnline > 0) and (numBNetOffline > 0 or numWoWOffline > 0) ) then
		haveHeader = true;
		buttonCount = buttonCount + 1;
	end
	if ( buttonCount > #FriendButtons ) then
		for i = #FriendButtons + 1, buttonCount do
			FriendButtons[i] = { };
		end
	end

  local friends = {}

  for i = 1, BNGetNumFriends() do
    friends[i] = { game = select(7,BNGetFriendInfo(i)), idx = i }
  end

  local wow = {}
  local other = {}

  for i = 1, #friends do
    if friends[i].game == "WoW" then
      wow[#wow+1] = friends[i].idx
    elseif friends[i].game ~= nil then
      other[#other+1] = friends[i].idx
    end
  end

  local index = 0
  -- online Battle.net Friends (WoW first.)
  for i = 1, #wow do
    print(wow[i])
		index = index + 1;
		FriendButtons[index].buttonType = FRIENDS_BUTTON_TYPE_BNET;
		FriendButtons[index].id = wow[i];
	end
  for i = 1, #other do
    index = index + 1;
    FriendButtons[index].buttonType = FRIENDS_BUTTON_TYPE_BNET;
    FriendButtons[index].id = other[i];
  end
  	-- online WoW friends
	for i = 1, numWoWOnline do
		index = index + 1;
		FriendButtons[index].buttonType = FRIENDS_BUTTON_TYPE_WOW;
		FriendButtons[index].id = i;
	end
	-- offline header
	if ( haveHeader ) then
		index = index + 1;
		FriendButtons[index].buttonType = FRIENDS_BUTTON_TYPE_HEADER;
		-- we can have a single button of different height than the others in a hybrid scrollframe
		-- even though the header is smaller than the other buttons, it will still work if we "expand" it
		HybridScrollFrame_ExpandButton(FriendsFrameFriendsScrollFrame, (numBNetOnline + numWoWOnline) * FRIENDS_BUTTON_NORMAL_HEIGHT, FRIENDS_BUTTON_HEADER_HEIGHT);
	else
		HybridScrollFrame_CollapseButton(FriendsFrameFriendsScrollFrame);
	end
	-- offline Battlenet friends
	for i = 1, numBNetOffline do
		index = index + 1;
		FriendButtons[index].buttonType = FRIENDS_BUTTON_TYPE_BNET;
		FriendButtons[index].id = i + numBNetOnline;
	end
	-- offline WoW friends
	for i = 1, numWoWOffline do
		index = index + 1;
		FriendButtons[index].buttonType = FRIENDS_BUTTON_TYPE_WOW;
		FriendButtons[index].id = i + numWoWOnline;
	end
	FriendButtons.count = index;

	-- selection
	local selectedFriend = 0;
	-- check that we have at least 1 friend
	if ( index > 0 ) then
		-- get friend
		if ( FriendsFrame.selectedFriendType == FRIENDS_BUTTON_TYPE_WOW ) then
			selectedFriend = GetSelectedFriend();
		elseif ( FriendsFrame.selectedFriendType == FRIENDS_BUTTON_TYPE_BNET ) then
			selectedFriend = BNGetSelectedFriend();
		end
		-- set to first in list if no friend
		if ( selectedFriend == 0 ) then
			FriendsFrame_SelectFriend(FriendButtons[1].buttonType, 1);
			selectedFriend = 1;
		end
		-- check if friend is online
		local isOnline;
		if ( FriendsFrame.selectedFriendType == FRIENDS_BUTTON_TYPE_WOW ) then
			local name, level, class, area;
			name, level, class, area, isOnline = GetFriendInfo(selectedFriend);
		elseif ( FriendsFrame.selectedFriendType == FRIENDS_BUTTON_TYPE_BNET ) then
			local presenceID, presenceName, battleTag, isBattleTagPresence, toonName, toonID, client;
			presenceID, presenceName, battleTag, isBattleTagPresence, toonName, toonID, client, isOnline = BNGetFriendInfo(selectedFriend);
			if ( not presenceName ) then
				isOnline = false;
			end
		end
		if ( isOnline ) then
			FriendsFrameSendMessageButton:Enable();
		else
			FriendsFrameSendMessageButton:Disable();
		end
	else
		FriendsFrameSendMessageButton:Disable();
	end
	FriendsFrame.selectedFriend = selectedFriend;
	FriendsSort_UpdateFriends();
end

function FriendsSort_UpdateFriends()
	local scrollFrame = FriendsFrameFriendsScrollFrame;
	local offset = HybridScrollFrame_GetOffset(scrollFrame);
	local buttons = scrollFrame.buttons;
	local numButtons = #buttons;
	local numFriendButtons = FriendButtons.count;

	local nameText, nameColor, infoText, broadcastText;

	local height;
	local usedHeight = 0;

	local hasTravelPass = HasTravelPass();
	local hasTravelPassButton;
	local canInvite = FriendsFrame_HasInvitePermission();

	FriendsFrameOfflineHeader:Hide();
	for i = 1, numButtons do
		local button = buttons[i];
		local index = offset + i;
		if ( index <= numFriendButtons ) then
			button.buttonType = FriendButtons[index].buttonType;
			button.id = FriendButtons[index].id;
			height = FRIENDS_BUTTON_NORMAL_HEIGHT;
			hasTravelPassButton = false;
			if ( FriendButtons[index].buttonType == FRIENDS_BUTTON_TYPE_WOW ) then
				local name, level, class, area, connected, status, note = GetFriendInfo(FriendButtons[index].id);
				broadcastText = nil;
				if ( connected ) then
					button.background:SetTexture(FRIENDS_WOW_BACKGROUND_COLOR.r, FRIENDS_WOW_BACKGROUND_COLOR.g, FRIENDS_WOW_BACKGROUND_COLOR.b, FRIENDS_WOW_BACKGROUND_COLOR.a);
					if ( status == "" ) then
						button.status:SetTexture(FRIENDS_TEXTURE_ONLINE);
					elseif ( status == CHAT_FLAG_AFK ) then
						button.status:SetTexture(FRIENDS_TEXTURE_AFK);
					elseif ( status == CHAT_FLAG_DND ) then
						button.status:SetTexture(FRIENDS_TEXTURE_DND);
					end
					nameText = name..", "..format(FRIENDS_LEVEL_TEMPLATE, level, class);
					nameColor = FRIENDS_WOW_NAME_COLOR;
				else
					button.background:SetTexture(FRIENDS_OFFLINE_BACKGROUND_COLOR.r, FRIENDS_OFFLINE_BACKGROUND_COLOR.g, FRIENDS_OFFLINE_BACKGROUND_COLOR.b, FRIENDS_OFFLINE_BACKGROUND_COLOR.a);
					button.status:SetTexture(FRIENDS_TEXTURE_OFFLINE);
					nameText = name;
					nameColor = FRIENDS_GRAY_COLOR;
				end
				infoText = area;
				button.gameIcon:Hide();
				FriendsFrame_SummonButton_Update(button.summonButton);
			elseif ( FriendButtons[index].buttonType == FRIENDS_BUTTON_TYPE_BNET ) then
				local presenceID, presenceName, battleTag, isBattleTagPresence, toonName, toonID, client, isOnline, lastOnline, isAFK, isDND, messageText, noteText, isRIDFriend, messageTime, canSoR = BNGetFriendInfo(FriendButtons[index].id);
				broadcastText = messageText;
				-- set up player name and character name
				local characterName = toonName;
				if ( presenceName ) then
					nameText = presenceName;
					-- if no character name but we have a BattleTag, use that
					if ( isOnline and not characterName and battleTag ) then
						characterName = battleTag;
					end
				elseif ( givenName ) then
					nameText = givenName;
				else
					nameText = UNKNOWN;
				end

				-- append toon
				if ( characterName ) then
					if ( client == BNET_CLIENT_WOW and CanCooperateWithToon(toonID, hasTravelPass) ) then
						nameText = nameText.." "..FRIENDS_WOW_NAME_COLOR_CODE.."("..characterName..")";
					else
						if ( ENABLE_COLORBLIND_MODE == "1" ) then
							characterName = characterName..CANNOT_COOPERATE_LABEL;
						end
						nameText = nameText.." "..FRIENDS_OTHER_NAME_COLOR_CODE.."("..characterName..")";
					end
				end

				if ( isOnline ) then
					local _, _, _, realmName, realmID, faction, _, _, _, zoneName, _, gameText = BNGetToonInfo(toonID);
					button.background:SetTexture(FRIENDS_BNET_BACKGROUND_COLOR.r, FRIENDS_BNET_BACKGROUND_COLOR.g, FRIENDS_BNET_BACKGROUND_COLOR.b, FRIENDS_BNET_BACKGROUND_COLOR.a);
					if ( isAFK ) then
						button.status:SetTexture(FRIENDS_TEXTURE_AFK);
					elseif ( isDND ) then
						button.status:SetTexture(FRIENDS_TEXTURE_DND);
					else
						button.status:SetTexture(FRIENDS_TEXTURE_ONLINE);
					end
					if ( client == BNET_CLIENT_WOW ) then
						if ( not zoneName or zoneName == "" ) then
							infoText = UNKNOWN;
						else
							infoText = zoneName;
						end
					else
						infoText = gameText;
					end
					button.gameIcon:SetTexture(BNet_GetClientTexture(client));
					nameColor = FRIENDS_BNET_NAME_COLOR;
					button.gameIcon:Show();
					-- travel pass
					if ( hasTravelPass ) then
						hasTravelPassButton = true;
						local restriction = FriendsFrame_GetInviteRestriction(button.id, canInvite);
						if ( restriction == INVITE_RESTRICTION_NONE ) then
							button.travelPassButton:Enable();
						else
							button.travelPassButton:Disable();
						end
					end
				else
					button.background:SetTexture(FRIENDS_OFFLINE_BACKGROUND_COLOR.r, FRIENDS_OFFLINE_BACKGROUND_COLOR.g, FRIENDS_OFFLINE_BACKGROUND_COLOR.b, FRIENDS_OFFLINE_BACKGROUND_COLOR.a);
					button.status:SetTexture(FRIENDS_TEXTURE_OFFLINE);
					nameColor = FRIENDS_GRAY_COLOR;
					button.gameIcon:Hide();
					if ( not lastOnline or lastOnline == 0 or time() - lastOnline >= ONE_YEAR ) then
						infoText = FRIENDS_LIST_OFFLINE;
					else
						infoText = string.format(BNET_LAST_ONLINE_TIME, FriendsFrame_GetLastOnline(lastOnline));
					end
				end
				FriendsFrame_SummonButton_Update(button.summonButton);
			else	-- header
				FriendsFrameOfflineHeader:Show();
				FriendsFrameOfflineHeader:SetAllPoints(button);
				height = FRIENDS_BUTTON_HEADER_HEIGHT;
				nameText = nil;
			end
			-- travel pass?
			if ( hasTravelPassButton ) then
				button.travelPassButton:Show();
				button.gameIcon:SetPoint("TOPRIGHT", -21, -2);
			else
				button.travelPassButton:Hide();
				button.gameIcon:SetPoint("TOPRIGHT", -2, -2);
			end
			-- selection
			if ( FriendsFrame.selectedFriendType == FriendButtons[index].buttonType and FriendsFrame.selectedFriend == FriendButtons[index].id ) then
				button:LockHighlight();
			else
				button:UnlockHighlight();
			end
			-- finish setting up button if it's not a header
			if ( nameText ) then
				button.name:SetText(nameText);
				button.name:SetTextColor(nameColor.r, nameColor.g, nameColor.b);
				button.info:SetText(infoText);
				button:Show();
			else
				button:Hide();
			end
			-- update the tooltip if hovering over a button
			if ( FriendsTooltip.button == button ) then
				FriendsFrameTooltip_Show(button);
			end
			-- set heights
			button:SetHeight(height);
			usedHeight = usedHeight + height;
			if ( GetMouseFocus() == button ) then
				FriendsFrameTooltip_Show(button);
			end
		else
			button:Hide();
		end
	end
	local headerHeight = scrollFrame.largeButtonHeight or 0;
	local totalHeight = numFriendButtons * FRIENDS_BUTTON_NORMAL_HEIGHT - headerHeight;
	HybridScrollFrame_Update(scrollFrame, totalHeight, usedHeight);
end

FriendsList_Update = FriendsSort_Update
FriendsFrame_UpdateFriends = FriendsSort_UpdateFriends
