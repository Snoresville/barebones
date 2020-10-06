// Quests
var quests_current = {};

function AddQuest(title, description, amount){
	
	// Add a quest to the quest list
	var newQuest = $.CreatePanel('Panel', $('#QuestList'), '');
	newQuest.BLoadLayoutSnippet("Quest")
	
	newQuest.FindChildTraverse("QuestTitle").text = title;
	newQuest.FindChildTraverse("QuestDescription").text = description;
	SetQuestProgress(newQuest, 0, amount);
	
	/*
	newQuest.style.width = "100px";
	newQuest.style.height = "100px";
	newQuest.style.backgroundColor = "red";
	*/
	
	SetQuestProgress(newQuest, 0 , amount)
	
	newQuest.name = title;
	newQuest.desc = description;
	newQuest.goal = amount;
	newQuest.current = 0;
	
	return newQuest;
}

function DeleteQuests(){
	$("#QuestList").RemoveAndDeleteChildren()
}

function RemoveQuest(quest){
	SetQuestProgress(quest, quest.goal, quest.goal)
	
	quest.FindChildTraverse("QuestDescription").text = "Complete!";
	
	$.Schedule(5, function(){
		quest.DeleteAsync(0);
	});
}

function SetQuestProgress(quest, current, goal){
	var percent = current / goal
	var progressBar = quest.FindChildTraverse("QuestBackground")
	progressBar.style.width = (percent * 100) + "%";
	
	quest.FindChildTraverse("QuestProgress").text = current + "/" + goal;
	
	// If the quest is just a single action
	if(goal < 2){ 
		quest.FindChildTraverse("QuestProgress").text = "";
	}
}

// Debug Function
function debug(){
	$.Msg("[Quest Module] Activated");
	
	DeleteQuests();
	/*
	var genocideQuest = AddQuest("FUCK EM UP FUCK EM UP", "we do this hard", 177013);
	var weedQuest = AddQuest("Smoke that dank weed", "my brother went to jail for this", 420);
	AddQuest("the hECK", "AHH WTF", 1);
	var genericQuest = AddQuest("Slay 10 Slimes", "It should be easy.", 10);
	
	
	SetQuestProgress(genocideQuest, 1337, genocideQuest.goal);
	SetQuestProgress(weedQuest, 69, weedQuest.goal);
	RemoveQuest(genericQuest);
	*/
	GameEvents.Subscribe("quest_new", OnNewQuest);
	GameEvents.Subscribe("quest_update", OnQuestUpdateProgress);
	GameEvents.Subscribe("quest_remove", OnQuestRemoved);
	
	OnNewQuest({title: "Search and Destroy", description: "You know what I mean.", goal: 1000000, id: 1}); 
	OnQuestUpdateProgress({id: 1, current: 123456, goal: 1000000});
	OnQuestRemoved({id: 1});
}
debug();

// Active Functions
function OnNewQuest(data){
	var newQuest = AddQuest(data.title, data.description, data.goal);
	newQuest.tag = data.id;
	quests_current[data.id] = newQuest;
}

function OnQuestUpdateProgress(data){
	SetQuestProgress(quests_current[data.id], data.current, data.goal);
}

function OnQuestRemoved(data){
	RemoveQuest(quests_current[data.id]);
}