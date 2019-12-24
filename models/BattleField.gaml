/***
* Name: BattleField
* Author: Jhorman Perez - Wilfredo Robinson
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model BattleField


global {
	
	int NUMBER_OF_SOLDIERS_IN_FIELD <- 9;
	int indexSoldierAlliance1 <- 10;
	int indexSoldierAlliance2 <- 10;
	int indexReserveSoldierAlliance1 <- 85;
	int indexReserveSoldierAlliance2 <- 15;
	bool battleIsHappening;
	bool initiateBattleSent;
	int armyHealthAlliance1;
	int commanderHealthAlliance1;
	int armyHealthAlliance2;
	int commanderHealthAlliance2;
	bool restartBattle;
	float simulationTime <- -1.0;
	
	init {
		do initializeBattle;
	}
	
	reflex restartBattle when: restartBattle {
		NUMBER_OF_SOLDIERS_IN_FIELD <- 9;
		indexSoldierAlliance1 <- 10;
		indexSoldierAlliance2 <- 10;
		indexReserveSoldierAlliance1 <- 85;
		indexReserveSoldierAlliance2 <- 15;
		battleIsHappening <- false;
		initiateBattleSent <- false;
		armyHealthAlliance1 <- 0;
		commanderHealthAlliance1 <- 0;
		armyHealthAlliance2 <- 0;
		commanderHealthAlliance2 <- 0;
		restartBattle <- false;
		simulationTime <- 0.0;
		do initializeBattle;
	}
	
	action initializeBattle {
		
		ask Commander {
			do die;
		}
		ask Soldier {
			do die;
		}
		ask Medic {
			do die;
		}
		ask Transport {
			do die;
		}
		ask Provisions {
			do die;
		}
		
		// Alliance 1
		create Commander number: 1 {
			alliance <- 1;
		}
		create Soldier number: indexSoldierAlliance1 {
			alliance <- 1;
			inField <- false;
			agentColor <- #purple;
		}
		create Soldier number: 1 {
			alliance <- 1;
			inField <- true;
			agentColor <- #green;
		}
		create Medic number: 2 {
			alliance <- 1;
			location <- {5, 30};
		}
		create Transport number: 2 {
			alliance <- 1;
			location <- {5, 70};
		}
		create Provisions number: 1 {
			alliance <- 1;
			location <- {5, 15};
		}
		
		// Alliance 2
		create Commander number: 1 {
			alliance <- 2;
		}
		create Soldier number: indexSoldierAlliance2 {
			alliance <- 2;
			inField <- false;
			agentColor <- #purple;
		}
		create Soldier number: NUMBER_OF_SOLDIERS_IN_FIELD {
			alliance <- 2;
			inField <- true;
			agentColor <- #red;
		}
		create Medic number: 2 {
			alliance <- 2;
			location <- {95, 70};
		}
		create Transport number: 2 {
			alliance <- 2;
			location <- {95, 30};
		}
		create Provisions number: 1 {
			alliance <- 2;
			location <- {95, 85};
		}
		
		ask BattleGrid {
			if(self.location.x >= 0 and self.location.x <= 10) {
				if(self.location.y >= 80 and self.location.y <= 90) {
					color <- #red;
				}
				else if(self.location.y >= 10 and self.location.y <= 20) {
					color <- #purple;
				}
			}
			else if((self.location.x >= 14 and self.location.x <= 15) or 
				(self.location.x >= 84 and self.location.x <= 85)
			) {
				color <- #brown;
			}
			else if(self.location.x >= 16 and self.location.x <= 50){
				int colorProb <- rnd(1);
				rgb cellColor <- rgb(int(255 * (1 - colorProb)), 255, int(255 * (1 - colorProb)));
				self.color <- cellColor;
			}
			else if(self.location.x >= 51 and self.location.x <= 84){
				int colorProb <- rnd(1);
				// 222,184,135 - 160,82,45 - 210,180,140
				rgb cellColor <- rgb(int(222 * (1 - colorProb)), 184, int(135 * (1 - colorProb)));
				self.color <- cellColor;
			}
			else if(self.location.x >= 90 and self.location.x <= 100) {
				if(self.location.y >= 80 and self.location.y <= 90) {
					color <- #purple;
				}
				else if(self.location.y >= 10 and self.location.y <= 20) {
					color <- #red;
				}
			}
		}
	}
	
}

//Main species. Commands the entire army via FIPA messages, commands, and supplies
species Commander skills:[moving, fipa] {
	
	int alliance;
	int power <- rnd(8,10);
	int health <- rnd(30,40);
	bool battleInitiated;
	float initialTime;
	bool cycleZero <- false;
	list<agent> availableMedics;
	list<message> injuredMessageList;
	list<message> provisionsMessageList;
	list<message> intruderMessageList;
	rgb agentColor;
	point provisionLocation;
	point targetPoint;
	point initialLocation;
	bool initialLocationKnown;
	bool alreadyDrawn;
	bool protectingZone;
	string intruderDetectedName;
	list<Medic> allianceMedicList;
	list<Soldier> allianceReserveList;
	
	init {
		alliance <- alliance;
	}
	
	aspect base {
		if (alliance = 1 and !alreadyDrawn){
			write 'mierda 1';
			location <- {5, 50};
			initialLocation <- location;
			agentColor <- #blue;
			alreadyDrawn <- true;
		}
		else if (alliance = 2 and !alreadyDrawn){
			write 'mierda 2';
			location <- {95, 50};
			initialLocation <- location;
			agentColor <- #blue;
			alreadyDrawn <- true;
		}
        draw sphere(2.0) at: location color: agentColor;
    }
    
    //Fill initial reference lists for the Commander's use
    reflex fillAgentLists when: !initialLocationKnown {
    	ask Medic {
			if myself.alliance = self.alliance {
				add self to: myself.allianceMedicList;
			}
		}
		ask Soldier {
			if myself.alliance = self.alliance and !self.inField {
				add self to: myself.allianceReserveList;
			}
		}
    }
    
    reflex doWander {
		do wander speed: 0.01;
	}
	
	reflex moveToTarget {
		do goto target:targetPoint speed: 0.3;
	}
	
	reflex knowInitialLocation when: !initialLocationKnown {
		initialLocation <- location;
		initialLocationKnown <- true;
	}
	
	reflex sendInitiateBattle when: !battleInitiated {
		if !cycleZero {
			cycleZero <- true;
			initialTime <- time;
		}
		if time - initialTime = 10 {
			do start_conversation with: [ to :: list(Soldier), protocol :: 'fipa-contract-net', 
				performative :: 'inform', contents :: ["Fight!", alliance] ];
			initiateBattleSent <- true;
		}
	}
	
	//Main reflex to receive different kinds of inform messages from agents: injured, provisions, intruders, deaths, etc.
	reflex receiveInforms {
		loop element over: informs {
			if element.contents[1] = alliance and element.contents[0] = "Injured!" {
				add element to: injuredMessageList;
			}	
			else if element.contents[1] = alliance and element.contents[0] = "Need provisions!" {
				add element to: provisionsMessageList;
			}
			else if element.contents[0] = "intruderAlert" and element.contents[2] != alliance {
				add element to: intruderMessageList;
			}
			else if element.contents[0] = "Medic killed!" and element.contents[2] = alliance {
				agent<Medic> deadMedic;
				deadMedic <- element.contents[2];
				remove deadMedic from: allianceMedicList;
			}
			//If a soldier reports his death, send in a Reserve soldier to replace him
			else if element.contents[0] = "I'm dead!" and element.contents[1] = alliance and length(allianceReserveList) > 0{
				point deadSoldierInitialLocation;
				agent<Soldier> chosenReserveSoldier;
				agent<Soldier> deadSoldier;
				message deadSoldierMessage;
				deadSoldierMessage <- element;
				chosenReserveSoldier <- allianceReserveList[rnd(0, (length(allianceReserveList) - 1))];
				deadSoldierInitialLocation <- element.contents[2];
				deadSoldier <- element.sender;
				do start_conversation with: [ to :: list(chosenReserveSoldier), protocol :: 'fipa-contract-net', 
					performative :: 'inform', contents :: ["Dead reported!", alliance, deadSoldierInitialLocation, deadSoldier] ];
				write name + ": Reserve soldier needed at " + deadSoldierInitialLocation + "!" color: agentColor;
				write name + ": Available reserve soldiers are " + allianceReserveList;
				remove chosenReserveSoldier from: allianceReserveList;
			}
		}
		//Checking for available medics to send messages to
		if !empty(injuredMessageList) and !empty(allianceMedicList) {
			availableMedics <- [];
			ask Medic {
				if !self.occupied and self.alliance = myself.alliance and self.medicine != 0  {
					add self to: myself.availableMedics;
				}
			}
			if !empty(availableMedics) {
				agent<Medic> chosenMedic <- availableMedics[rnd(0, length(availableMedics) - 1)];
				do start_conversation with: [ to :: list(chosenMedic), protocol :: 'fipa-contract-net', 
					performative :: 'inform', contents :: ["Injured found!", alliance, Soldier(injuredMessageList[0].sender).location, Soldier(injuredMessageList[0].sender) ] ];
				remove injuredMessageList[0] from: injuredMessageList;
			}
		}
		//Take action if an intruder enters the home base
		if !empty(intruderMessageList) {
			if (!protectingZone) {
				intruderDetectedName <- intruderMessageList[0].contents[1];
				protectingZone <- true;
				write '||| ' + intruderDetectedName + ' is entering forbidden area |||' color: #peru;
			}
			if intruderDetectedName != nil {
				ask Soldier {
					if (myself.intruderDetectedName = self.name) {
						myself.targetPoint <- self.location;
					}
				}
			}
			remove intruderMessageList[0] from: intruderMessageList;
		}
		else {
			targetPoint <- initialLocation;
		}
	}
	
	//If Provisions agent needs bullets, medicine, fuel, etc., it will call its Commander. This reflex receives these messages. 
	reflex restoreProvisions when: !empty(provisionsMessageList) {
		provisionLocation <- provisionsMessageList[0].contents[2];
		targetPoint <- provisionLocation;
		if provisionLocation != nil and distance_to(location, provisionLocation) < 0.5 {
			ask Provisions {
				self.medicineStock <- self.initialMedicineStock;
				self.bulletStock <- self.initialBulletStock;
				self.fuelStock <- initialFuelStock;
				myself.targetPoint <- myself.initialLocation;
				myself.provisionsMessageList <- [];
			}
		}
	}
	
	//Reflex to attack an enemy if it enters the home base
	reflex attackEnemy when: protectingZone {
		ask Soldier at_distance 1 {
			if (myself.intruderDetectedName = self.name) {
				write '---> ' + myself.name + ' attacks ' + self.name color: #orange;
				myself.protectingZone <- false;
				myself.intruderDetectedName <- nil;
				myself.health <- myself.health - self.power;
				do notifyDead;
				do die;
			}
		}
		if health <= 0 {
			write 'RIP ' + name color: #magenta;
			write 'Alliance # ' + alliance + ' has just lost the battle.';
			write 'Restarting...';
			// Restart battle
			restartBattle <- true;
		}
	}
	
	//Reflex to update both commander and army healths to display in pie charts. Provide an overview of the flow of battle in real time
	reflex updateArmyHealth {
		if alliance = 1 {
			commanderHealthAlliance1 <- health;
		}
		if alliance = 2 {
			commanderHealthAlliance2 <- health;	
		}
		armyHealthAlliance1 <- 0;
		armyHealthAlliance2 <- 0;
		ask Soldier {
			if self.alliance = 1 {
				armyHealthAlliance1 <- armyHealthAlliance1 + self.health;
			}
			else if self.alliance = 2 {
				armyHealthAlliance2 <- armyHealthAlliance2 + self.health;
			}
		}
	}
}

//Main field soldiers. Two types: active and reserves. Their goal is to eliminate enemy soldiers. Reserves replace actives when they die.
species Soldier skills:[moving, fipa] {
	
	int alliance;
	bool fighting;
	bool inField;
	bool initialPositionDefined;
	point initialPosition;
	bool injured;
	point positionInFight;
	point targetPoint;
	rgb agentColor;
	list informsList;
	point provisionsLocation;
	bool provisionsLocationKnown;
	bool leadingFight;
	agent<Medic> medicAssigned;
	bool medicLoopDone;
	float transportSpeed;
	float initialSpeed;
	bool wentToprovision;
	agent<Transport> transportAssigned;
	agent<Commander> commanderAssigned;
	agent<Commander> enemyCommander;
	bool medicArrived;
	int medicArrivedCounter;
	point battleLocationAfterHealing;
	int health <- rnd(10, 20);
	int initialHealth;
	int power <- rnd (5, 10);
	int bullets <- rnd (2, 4);
	int initialBulletCount;
	float timeInFight;
	bool goingToProvisions;
	int bulletsNeeded;
	Soldier opponent;
	bool readyToFight;
	bool fightIsOver;
	list<Medic> enemyMedicsKilled;
	list<message> deadSoldierMessageList;
	bool wasFighting;
	agent<Soldier> deadSoldier;
	
	init {
		initialSpeed <- rnd(0.01,0.09);
		speed <- rnd(0.01,0.09);
		initialBulletCount <- bullets;
		initialHealth <- health;
	}
	
	aspect base {
		draw sphere(1.5) at: location color: agentColor;
    }
	
	reflex doWander when: !inField {
		do wander speed: 0.01;
	}
	
	//Reflex to move reserve soldiers when an active one dies
	reflex moveToTargetReserve when: !inField {
		do goto target:targetPoint speed: 0.2;
	}
	
	//Reflex to move active soldiers
	reflex moveToTarget when: battleIsHappening and inField and timeInFight = 0.0 and !wasFighting {
		if (!injured) {
			ask Commander {
				if (myself.alliance != self.alliance){
					myself.enemyCommander <- self;
				}
			}
			if (alliance = 1) {
				targetPoint <- {100, location.y};
				if (location.x >= 84) {
					speed <- 0.01;
					do start_conversation with: [ to :: list(enemyCommander), protocol :: 'fipa-contract-net', 
					performative :: 'inform', contents :: ["intruderAlert", name, alliance, location] ];
				}
				if (location.x = 0) {
					// Restart battle
					write 'Alliance # ' + alliance + ' has just BEATEN Alliance # 2!' color: agentColor;
					write 'Restarting...'; 
					restartBattle <- true;
				}
			}
			else {
				targetPoint <- {0, location.y};
				if (location.x <= 15) {
					speed <- 0.01;
					do start_conversation with: [ to :: list(enemyCommander), protocol :: 'fipa-contract-net', 
					performative :: 'inform', contents :: ["intruderAlert", name, alliance, location] ];
				}
				if (location.x = 100) {
					// Restart battle
					write 'Alliance # ' + alliance + ' has just BEATEN Alliance # 1!' color: agentColor;
					write 'Restarting...'; 
					restartBattle <- true;
				}
			}
		}
		do goto target:targetPoint speed: speed;
	}
	
	//Reflex to go back to initial positions after having resupplied
	reflex moveToInitialPosition when: goingToProvisions or wasFighting {
		do goto target:targetPoint speed: 0.08;
		if location = initialPosition {
			goingToProvisions <- false;
			wasFighting <- false;
		}
	}
	
	//Reflex used when fighting
	reflex stopMoving when: inField {
		ask Soldier {
			if (self.name != myself.name and myself.location distance_to self.location <= 1) {
				if (!self.injured) {
					if (!myself.fighting and !myself.injured and !self.fighting) {
						float currentTime <- time;
						myself.readyToFight <- true;
						myself.fighting <- true;
						myself.bullets <- myself.bullets - 1;
						myself.positionInFight <- location;
						myself.targetPoint <- location;
						myself.timeInFight <- currentTime;
						myself.opponent <- self;
						myself.leadingFight <- true;
						self.bullets <- self.bullets - 1;
						self.readyToFight <- true;
						self.fighting <- true;
						self.positionInFight <- location;
						self.targetPoint <- location;
						self.timeInFight <- currentTime;
						do fight(self);
					}
				}
				else {
					do notifyDead;
					do die;
				}
			}
		}
	}
	
	//Action used to notify others that I have been injured
	action notifyInjured {
		ask Commander {
			if self.alliance = myself.alliance {
				myself.commanderAssigned <- self;
			}
		}
		do start_conversation with: [ to :: list(commanderAssigned), protocol :: 'fipa-contract-net', 
			performative :: 'inform', contents :: ["Injured!", alliance, self] ];
		fighting <- false;
		bullets <- bullets - 1;
		if health > 0 {
			write name + ": I'm injured! My current health is: " + health + "/" + initialHealth color: agentColor;
			write "\t I have " + bullets + " bullet(s) left!" color: agentColor;	
		}
		agentColor <- #yellow;
	}
	
	//Reflex for main movements while fighting enemies
	reflex moveInFight when: fighting and timeInFight != 0.0 {
		if (time - timeInFight = 500) {
			timeInFight <- 0.0;
			positionInFight <- nil;
			wasFighting <- true;
			
			if (!injured) {
				fighting <- false;
				targetPoint <- initialPosition;
			}
			else {
				if (health <= 0) {
					do notifyDead;
					do die;
				}
				do notifyInjured;
			}
		}
		else {	
			if (targetPoint = positionInFight and location distance_to targetPoint <= 1) {
				if (alliance = 1) {
					targetPoint <- {location.x - 2, location.y};
				}
				else {
					targetPoint <- {location.x + 2, location.y};
				}
			}
			else if (location = targetPoint) {
				targetPoint <- positionInFight;
			}
			do goto target:targetPoint speed: rnd(0.05);
		}
	}
	
	//Reflex to place soldiers in initial position after being created
	reflex initializePosition when: !initialPositionDefined {
		if (alliance = 1) {
			if (inField) {
				location <- {30, indexSoldierAlliance1};
				indexSoldierAlliance1 <- indexSoldierAlliance1 + 10;
			}
			else {
				location <- {5, indexReserveSoldierAlliance1};
			}
		}
		else if (alliance = 2) {
			if (inField) {
				location <- {70, indexSoldierAlliance2};
				indexSoldierAlliance2 <- indexSoldierAlliance2 + 10; 
			}
			else {
				location <- {95, indexReserveSoldierAlliance2};
			}
		}
		initialPositionDefined <- true;
		initialPosition <- location;
	}
	
	//Reflex to receive initiateBattle command from Commander
	reflex receiveInitiateBattle when: initiateBattleSent and !injured and inField {
		loop element over: informs {
			if element.contents[1] = alliance and element.contents[0] = "Fight!" {
				battleIsHappening <- true;
				add element to: informsList;
			}		
		}
	}
	
	//One time reflex to save Provisions location
	reflex knowprovisionsLocation when: !provisionsLocationKnown {
		ask Provisions {
			if self.alliance = myself.alliance {
				myself.provisionsLocation <- self.location;	
			}
		}
		provisionsLocationKnown <- true;
	}
	
	//Reflex activated when injured. Soldier will be healed and all corresponding attributes (bullets, health, etc.) will be updated accordingly
	reflex medicArrived when: injured {
		loop element over: informs {
			if element.contents[1] = alliance and element.contents[0] = "Coming to pick you up!"{
				transportAssigned <- element.contents[2];
				medicAssigned <- element.sender;
				medicLoopDone <- true;
			}
		}
		if medicLoopDone and medicArrivedCounter < 1 {
			ask Medic(medicAssigned) {
				if distance_to (self.location, myself.location) < 3.1 {
					if myself.health <= myself.initialHealth - 5 {
						myself.health <- myself.health + 5;
					}
					else {
						myself.health <- myself.initialHealth;
					}	
					if myself.alliance = 1 {
						myself.agentColor <- #green;
					}
					else {
						myself.agentColor <- #red;	
					}
					myself.medicArrived <- true;
					write myself.name + ": I've been healed! My health is now " + myself.health + "/" + myself.initialHealth color: myself.agentColor;
					myself.targetPoint <- myself.initialPosition;	
				}
			}
		}
		if medicArrived and medicArrivedCounter < 1 {
			ask Medic(medicAssigned) {
				self.targetPoint <- self.initialLocation;
				self.medicine <- self.medicine - 1;	
				write name + ": I've given first aid! My current medicine is: " + medicine color: self.agentColor;
				do resetControlVariables;	
			}
			ask Transport(transportAssigned) {
				ask Medic at_distance 1 {
					if myself.alliance = self.alliance {
						myself.targetPoint <- self.initialLocation;
						self.transportSpeed <- self.transportSpeed;	
					}
				}
				self.fuel <- self.fuel - 1;
				write self.name + ": My current fuel is: " + fuel color:agentColor;
				do resetControlVariables;	
			}
			medicArrivedCounter <- medicArrivedCounter + 1;
		}
		
		if medicArrived and location = initialPosition {
			do resetControlVariables;
		}		
	}
	
	//Soldierwill go to Provisions to obtain more bullets to continue fighting
	reflex goToProvisions when: bullets = 0 and !injured and !fighting {
		goingToProvisions <- true;
		ask Provisions {
			if distance_to (myself.location, self.location) > 0.5 and myself.alliance = self.alliance {
				myself.targetPoint <- myself.provisionsLocation;
				}	
			if distance_to (myself.location, self.location) < 0.5 and myself.alliance = self.alliance {
				myself.bulletsNeeded <- myself.initialBulletCount - myself.bullets;
				myself.bullets<- myself.initialBulletCount;
				self.bulletStock <- self.bulletStock - myself.bulletsNeeded;
				write self.name + ": I've given bullets to " + myself + "! My remaining bullets are now " + self.fuelStock color: myself.agentColor;
				
				myself.bullets <- myself.initialBulletCount;
				write "\t My bullets have been replenished to: " + myself.bullets + "/" + myself.initialBulletCount color: myself.agentColor;
			}
		}
		if bullets = initialBulletCount {
			targetPoint <- initialPosition;
		}
	}
	
	//Soldiers will kill enemy medics and steal their transports if found in their own territory
	reflex killEnemyMedics {
		if alliance = 1 and location.x < 50 {
			ask Medic at_distance 1 {
				if self.alliance != myself.alliance {
					add self to: myself.enemyMedicsKilled;
					write name + ": killed enemy " + myself.name + "!!" color: myself.agentColor;
					do die;
				}
			}
			if !empty(enemyMedicsKilled) {
				do start_conversation with: [ to :: list(Commander), protocol :: 'fipa-contract-net', 
					performative :: 'inform', contents :: ["Medic killed!", alliance, enemyMedicsKilled[0]] ];
				remove enemyMedicsKilled[0] from: enemyMedicsKilled;
			}
			ask Transport at_distance 1 {
				if self.alliance != myself.alliance {
					self.targetPoint <- {95, 30};
					self.agentColor <- #gray;
				}
			}
		}
		if alliance = 2 and location.x > 50 {
			ask Medic at_distance 0.5 {
				if self.alliance != myself.alliance {
					do die;
				}
			}
			ask Transport at_distance 0.5 {
				if self.alliance != myself.alliance {
					self.targetPoint <- {5, 70};
					self.agentColor <- #gray;
				}
			}
		}
	}
	
	//Reserve soldiers will replace active soldiers when they die. 
	reflex replaceDeadSoldier when: !inField {
		loop element over: informs {
			if element.contents[0] = "Dead reported!" and element.contents[1] = alliance {
				add element to: deadSoldierMessageList;
			}
		}
		if !empty(deadSoldierMessageList) and targetPoint = nil {
			deadSoldier <- deadSoldierMessageList[0].contents[3];
			targetPoint <- deadSoldierMessageList[0].contents[2];
			remove deadSoldier from: deadSoldierMessageList;
			if alliance = 1 {
				agentColor <- #green;
			}
			else {
				agentColor <- #red;
			}
		}
		if targetPoint != nil and distance_to (location, targetPoint) = 0 {
			write name + ": my targetPoint is " + targetPoint;
			inField <- true;
			battleIsHappening <- true;
			write name + " has arrived to replace " + deadSoldier color: agentColor;
			initialPosition <- location;
			//deadSoldier <- nil;
			do resetControlVariables;
		}
	}
	
	//Action to reset control variables and continue the fight
	action resetControlVariables {
		medicAssigned <- nil;
		medicLoopDone <- false;
		speed <- initialSpeed;
		injured <- false;
		fighting <- false;
		medicArrived <- false;
		medicArrivedCounter <- 0;
	}
	
	//Action used when fighting enemies inField
	action fight (Soldier fightOpponent) {
		
		health <- health - fightOpponent.power;
		fightOpponent.health <- fightOpponent.health - power;
		
		if (power >= fightOpponent.power) {
			fightOpponent.injured <- true;
		}
		else {
			injured <- true;
		}
	}
	
	//Action executed by soldiers right before they die. This notifies their commander of their impending doom
	action notifyDead {
		do start_conversation with: [ to :: list(Commander), protocol :: 'fipa-contract-net', 
			performative :: 'inform', contents :: ["I'm dead!", alliance, initialPosition] ];
		write name + " HAS DIED!" color: agentColor;
	}
}

//Species in charge of assuring that all available soldiers are kept healthy. Casualties must be reduced to a minimum.
species Medic skills:[moving, fipa] {
	int alliance;
	point injuredLocation;
	point targetPoint;
	bool moveControl;
	bool occupied;
	list<Transport> availableTransports;
	agent<Transport> transportAssigned;
	agent<Soldier> injuredSoldier;
	bool transportLoopDone;
	float transportSpeed;
	point initialLocation;
	bool initialLocationKnown;
	float initialSpeed;
	list<message> injuredMessageList;
	list<message> transportMessageList;
	rgb agentColor;
	int medicine <- rnd (3,6);
	int initialMedicine;
	int medicineNeeded;
	point provisionsLocation;
	bool soldierDead;
	
	
	init {
		alliance <- alliance;
		initialSpeed <- 0.05;
		initialMedicine <- medicine;
	}
	
	aspect base {
        agentColor <- #violet;
        draw sphere(1.5) at: location color: agentColor;
    }
    
    reflex doWander {
		do wander speed: 0.01;
	}
	
	//Initial reflex to save initialLocation after being created
	reflex knowInitialLocation when: !initialLocationKnown {
		initialLocation <- location;
		ask Provisions {
			if self.alliance = myself.alliance {
				myself.provisionsLocation <- self.location;
			}
		}
		initialLocationKnown <- true;
	}
	
	//Main movement reflex
	reflex moveToTarget when: moveControl {
		do goto target:targetPoint speed: transportSpeed;
	}
	
	//Reflex to receive different kinds of commands via FIPA. These may be from Commanders, Transports, or others
	reflex receiveInforms {
		loop element over: informs {
			if element.contents[1] = alliance and element.contents[0] = "Injured found!" and !occupied {
				add element to: injuredMessageList;
			}
			if element.contents[1] = alliance and element.contents[0] = "Pick up!" {
				if transportAssigned = nil {
					transportAssigned <- element.sender;	
				}
				transportLoopDone <- true;
				add element to: transportMessageList;
			}					
		}
		availableTransports <- [];
		ask Transport {
			if !self.occupied and self.alliance = myself.alliance and self.fuel != 0{
				add self to: myself.availableTransports;
			}
		}
		
		//Medic will call any available transport to come aid him in his quest to heal his comrades
		if (!empty(availableTransports) or transportAssigned != nil) and !empty(injuredMessageList) and !occupied and medicine != 0 {
			injuredLocation <- injuredMessageList[0].contents[2];
			injuredSoldier <- injuredMessageList[0].contents[3];
			if transportAssigned = nil {
				agent<Transport> chosenTransport;
				chosenTransport <- availableTransports[rnd(0, length(availableTransports) -1)];
				do start_conversation with: [ to :: list(chosenTransport), protocol :: 'fipa-contract-net', 
					performative :: 'inform', contents :: ["Pick me up!", alliance, location, injuredLocation, injuredSoldier] ];	
			}
			else {
				do start_conversation with: [ to :: list(transportAssigned), protocol :: 'fipa-contract-net', 
					performative :: 'inform', contents :: ["Pick me up!", alliance, location, injuredLocation, injuredSoldier] ];
			}
			occupied <- true;
			remove injuredMessageList[0] from: injuredMessageList;	
		}
		if transportLoopDone and injuredSoldier != nil {
			ask Transport(transportAssigned) {
				if distance_to (self.location, myself.location) < 1{
					myself.targetPoint <- myself.injuredLocation;
					self.targetPoint <- myself.injuredLocation;
					myself.transportSpeed <- self.transportSpeed;
					myself.moveControl <- true;
				}
			}
			do start_conversation with: [ to :: list(injuredSoldier), protocol :: 'fipa-contract-net', 
				performative :: 'inform', contents :: ["Coming to pick you up!", alliance, transportAssigned] ];
		}
	}
	
	//Reflex to run when restocking in Provisions
	reflex inProvisions when: medicine != initialMedicine {
		ask Provisions {
			if distance_to (myself.location, self.location) < 0.5 and myself.alliance = self.alliance {
				myself.medicineNeeded <- myself.initialMedicine - myself.medicine;
				myself.medicine <- myself.initialMedicine;
				self.medicineStock <- self.medicineStock - myself.medicineNeeded;
				write self.name + ": I've given medicine to " + myself + "! My remaining medicine is now " + self.fuelStock color: myself.agentColor;
				write myself.name + ": I've been restocked! My medicine is now " + myself.medicine+ "/" + myself.initialMedicine color: myself.agentColor;
			}
		}
	}
	
	//If Medic runs out of medicine, it must go to Provisions and restock
	reflex needMedicine when: medicine = 0 and !occupied {
		targetPoint <- provisionsLocation;
		moveControl <- true;
		ask Transport at_distance 1 {
			if self.alliance = myself.alliance {
				self.targetPoint <- myself.targetPoint;	
			}
		}
	}
	
	//Reflex to ensure that Medic and its assigned Transport are never too far apart
	reflex followTransport when: medicine != 0{
		if injuredLocation != nil and transportAssigned != nil {
			ask Transport (transportAssigned) {
				self.targetPoint <- myself.location;
				if distance_to (self.location, myself.location) < 0.1 {
					myself.targetPoint <- myself.injuredLocation;
					self.targetPoint <- myself.location;	
				}
			}
		}
		ask Transport at_distance 0.2 {
			if self.alliance = myself.alliance and self.fuel = 0 {
				self.targetPoint <- self.provisionsLocation;
				myself.targetPoint <- self.targetPoint;
				myself.speed <- self.speed;	
			}
		}
	}
	
	//Reflex to check if assigned injuredSoldier dies before the Medic arrives to help
	reflex checkForDeadSoldier {
		ask Soldier {
			if self.alliance = myself.alliance and self.medicAssigned = myself and dead(self) {
				myself.soldierDead <- true;
			}
		}
		if soldierDead {
			targetPoint <- initialLocation;
			do resetControlVariables;
			soldierDead <- false;
			ask Transport(transportAssigned) {
				self.targetPoint <- myself.targetPoint;
				do resetControlVariables;
			}
		}
	}
	
	//Action to reset control variables and continue the fight
	action resetControlVariables {
		//transportAssigned <- nil;
		transportLoopDone <- false;
		speed <- initialSpeed;
		//moveControl <- false;
		availableTransports <- [];
		injuredLocation <- nil;
		injuredSoldier <- nil;
		occupied <- false;
		targetPoint <- initialLocation;
	}
}

//Main helper for Medics. They will help the Medic get quickly to injured soldiers. They may be interchanged between Medics if necessary
species Transport skills:[moving, fipa] {
	
	int alliance;
	point targetPoint;
	bool moveControl;
	point initialLocation;
	bool initialLocationSaved;
	bool occupied;
	float transportSpeed <- 0.4;
	agent<Soldier> injuredSoldier;
	rgb agentColor <- #black;
	int fuel <- rnd(2, 5);
	int initialFuel;
	int fuelNeeded;
	point provisionsLocation;
	list<message> injuredReportedMessageList;
	
	init {
		alliance <- alliance;
		initialFuel <- fuel;
	}
	
	aspect base {
        draw cube(2.5) color: agentColor;
    }
    
    //One time reflex to save initial location after initializing
    reflex saveInitialLocation when: !initialLocationSaved {
    	initialLocation <- location;
    	initialLocationSaved <- true;
    	ask Provisions {
    		if myself.alliance = self.alliance {
    			myself.provisionsLocation <- self.location;
    		}
    	}
    }
    
    reflex doWander {
		do wander speed: 0.01;
	}
	
	reflex moveToTarget when: moveControl {
		do goto target:targetPoint speed: transportSpeed;
	}
	
	//Reflex used to receive FIPA commands from Medics
	reflex injuredReported {
		loop element over: informs {
			if element.contents[1] = alliance and element.contents[0] = "Pick me up!" {
				add element to: injuredReportedMessageList;
			}
		}
		if !empty(injuredReportedMessageList) {
			targetPoint <- injuredReportedMessageList[0].contents[2];
			moveControl <- true;
			occupied <- true;
			do start_conversation with: [ to :: injuredReportedMessageList[0].sender, protocol :: 'fipa-contract-net', 
				performative :: 'inform', contents :: ["Pick up!", alliance, location] ];
			remove injuredReportedMessageList[0] from: injuredReportedMessageList;
		}
	}
	
	//Reflex used when restocking in Provisions
	reflex inProvisions when: fuel != initialFuel {
		ask Provisions {
			if distance_to (myself.location, self.location) < 0.5 and myself.alliance = self.alliance {
				myself.fuelNeeded <- 0;
				myself.fuelNeeded <- myself.initialFuel - myself.fuel;
				myself.fuel <- myself.initialFuel;
				self.fuelStock <- self.fuelStock - myself.fuelNeeded;
				write self.name + ": I've refueled " + myself + "! My remaining fuel is now " + self.fuelStock color: myself.agentColor;
				write myself.name + ": I've been refueled! My fuel is now " + myself.fuel + "/" + myself.initialFuel color: myself.agentColor;
			}
		}
	}
	
	//Reflex used to go to Provisions if fuel is needed
	reflex needFuel when: fuel = 0 {
		targetPoint <- provisionsLocation;
		moveControl <- true;
		ask Medic at_distance 1 {
			if self.alliance = myself.alliance {
				self.targetPoint <- myself.targetPoint;	
			}
		}
	}
	
	//Reflex used to endure Transport and nearby Medic are always close by
	reflex followMedic when: fuel !=0 {
		ask Medic at_distance 0.7 {
			if self.alliance = myself.alliance {
				myself.targetPoint <- self.location;
				myself.speed <- self.speed;	
			}
		}
	}
	
	//Action to reset control variables and continue fighting
	action resetControlVariables {
		//moveControl <- false;
		//occupied <- false;
		ask Medic at_distance 1 {
			if self.alliance = myself.alliance {
				myself.targetPoint <- self.targetPoint;	
			}
		}
		//targetPoint <- initialLocation;
	}
	
}

//Main supply agent. In charge of providing comrades with medicine, bullets, fuel, and others. 
//Most actions are done through reflexes in the other agents
species Provisions skills: [fipa] {
	
	int alliance;
	float medicineStock <- 10.0;
	float initialMedicineStock;
	float bulletStock <- 20.0;
	float initialBulletStock;
	float fuelStock <- 6.0;
	float initialFuelStock;
	agent<Commander> assignedCommander;
	
	init {
		alliance <- alliance;
		initialMedicineStock <- medicineStock;
		initialBulletStock <- bulletStock;
		initialFuelStock <- fuelStock;
	}
	
	aspect base {
        draw sphere(1.5) color: #white;
    }
    
    //If it runs out of Provisions, it must call the Commander with FIPA to come and restock
    reflex restoreOwnProvisions when: medicineStock < 3 or bulletStock < 5 or fuelStock < 2 {
		do start_conversation with: [ to :: list(Commander), protocol :: 'fipa-contract-net', 
			performative :: 'inform', contents :: ["Need provisions!", alliance, location] ];
    }
}

//Battlegrid used to color the map and define the different zones where soldiers interact
grid BattleGrid width: 100 height: 100 neighbors: 8 {
	
}

experiment BattleField type: gui {
	
    output {
    	display Battlefield type: opengl {
    		grid BattleGrid;
			species Commander aspect: base;
			species Soldier aspect: base;
			species Medic aspect: base;
			species Transport aspect: base;
			species Provisions aspect: base;
       	}
       	//Chart used to display overall Army Health. Provides an estimate of who is winning the battle
       	display ArmyHealth type: opengl {
       		chart "Army Health" type: pie {
				data "Alliance #1" value: armyHealthAlliance1 color: #green;
				data "Alliance #2" value: armyHealthAlliance2 color: #red;
			}
       	}
   		//Chart used to display opposing Commanders' Health. Provides an estimate of who is winning the battle
   		display CommanderHealth type: opengl {
			chart "Commander Health" type: pie {
				data "Alliance #1" value: commanderHealthAlliance1 color: #green;
				data "Alliance #2" value: commanderHealthAlliance2 color: #red;
			}
   		}
    }
    
}

