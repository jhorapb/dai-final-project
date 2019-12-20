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
	bool testInjured;
	
	init {
		// Alliance 1
		create Commander number: 1 {
			alliance <- 1;
		}
		create Soldier number: 10 {
			alliance <- 1;
			inField <- false;
			agentColor <- #purple;
		}
		create Soldier number: NUMBER_OF_SOLDIERS_IN_FIELD {
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
		create Provision number: 1 {
			alliance <- 1;
			location <- {5, 15};
		}
		
		// Alliance 2
		create Commander number: 1 {
			alliance <- 2;
		}
		create Soldier number: 10 {
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
		create Provision number: 1 {
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


species Commander skills:[moving, fipa] {
	
	int alliance;
	int power <- rnd(8,10);
	int health <- rnd(30,40);
	bool battleInitiated;
	float initialTime;
	bool cycleZero <- false;
	list<agent> availableMedics;
	
	init {
		alliance <- alliance;
		//name <- "Commander";
	}
	
	aspect base {
		if (alliance = 1){
			location <- {5, 50};
		}
		else if (alliance = 2){
			location <- {95, 50};
		}
        draw sphere(2.0) color: #blue;
    }
    
    reflex doWander {
		do wander speed: 0.01;
	}
	
	reflex sendInitiateBattle when: !battleInitiated {
		if !cycleZero {
			cycleZero <- true;
			initialTime <- time;
		}
		if time - initialTime = 10{
			do start_conversation with: [ to :: list(Soldier), protocol :: 'fipa-contract-net', 
				performative :: 'inform', contents :: ["Fight!", alliance] ];
			//write "My name is " + name + " and I sent the Fight message!" color:#blue;
			initiateBattleSent <- true;
		}
	}
	
	reflex receiveInjured {
		loop element over: informs {
			if element.contents[1] = alliance and element.contents[0] = "Injured!" {
				//write "My name is " + name + " and I received an Injured message from " + element.sender color: #blue;
				ask Medic {
					if !self.occupied {
						add self to: myself.availableMedics;
					}
				}
				do start_conversation with: [ to :: availableMedics, protocol :: 'fipa-contract-net', 
					performative :: 'inform', contents :: ["Injured found!", alliance, Soldier(element.sender).location, Soldier(element.sender) ] ];
			}
		}
	}
}

species Soldier skills:[moving, fipa] {
	
	int alliance;
	bool fighting;
	bool inField;
	bool initialPositionDefined;
	point initialPosition;
	point positionInFight;
	point targetPoint;
	rgb agentColor;
	list informsList;
	point provisionsLocation;
	bool provisionLocationKnown;
	int fightSequence <- 0;
	agent<Medic> medicAssigned;
	bool medicLoopDone;
	float transportSpeed;
	bool injured;
	float initialSpeed;
	bool wentToProvisions;
	agent<Transport> transportAssigned;
	
	
	init {
		//name <- "Soldier";
		initialSpeed <- rnd(0.01,0.09);
		speed <- rnd(0.01,0.09);
	}
	
	aspect base {
		draw sphere(1.5) at: location color: agentColor;
    }
	
	reflex doWander when: !inField {
		do wander speed: 0.01;
	}
	
	reflex moveToTarget when: battleIsHappening and inField and !fighting {
		if (alliance = 1) and !injured {
			targetPoint <- {100, location.y};
		}
		else if !injured {
			targetPoint <- {0, location.y};
		}
		do goto target:targetPoint speed: speed;
	}
	
	reflex stopMoving when: inField {
		ask Soldier {
			point localLocation <- myself.location;
			point enemyLocation <- self.location;
			/////////////////////////////////////////////////////////Agregue las dos ultimas condiciones al if xq sino el idiota injured encima de mi Transport se andaba hablando con los que no estaban injured
			if (self.name != myself.name and localLocation distance_to enemyLocation <= 1 and !self.injured and !myself.injured) {
				myself.fighting <- true;
				myself.positionInFight <- location;
				myself.targetPoint <- location;
				self.fighting <- true;
				self.positionInFight <- location;
				self.targetPoint <- location;
			}
		}
	}
	
	action notifyInjured {
		do start_conversation with: [ to :: list(Commander), protocol :: 'fipa-contract-net', 
		performative :: 'inform', contents :: ["Injured!", alliance] ];
		//write "My name is " + name + " and I sent the injured message to the Commander!" color: #orange;
		agentColor <- #yellow;
		///////////////////////////////////////////////////////Fighting se hace false cuando esta injured
		fighting <- false;
	}
	
	reflex goToMedic when: injured {
		if medicAssigned != nil {
			ask Medic(medicAssigned){
				if self = myself.medicAssigned and distance_to (self.location, myself.location) < 1 {
					myself.targetPoint <- self.location;
					myself.speed <- self.transportSpeed;
				}
			}
		}
	}
	
	///////////////////////////////La variable fightSequence no es nada util. Solo es para que luego de 1000 veces de....algo entonces que uno quede injured
	/////////////////////////////// Esta cambiala por tu tema del tiempo. Testinjured tampoco hace gran cosa. Se deberia cambiar por la injured nada mas
	/////////////////////////////// Cuando se ha ya cumplido el tiempo de pelea y que el man quede injured, pon injured en cierto y que haga el notify
	reflex moveInFight when: fighting and fightSequence <= 1000{
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
		if fightSequence < 1000 {
			fightSequence <- fightSequence + 1;	
		}
		else if !testInjured {
			do notifyInjured;
			fightSequence <- fightSequence + 1;
			testInjured <- true;
			injured <- true;
		}
		do goto target:targetPoint speed: rnd(0.05);
	}
	
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
	
	reflex receiveInitiateBattle when: initiateBattleSent and !injured {
		loop element over: informs {
			if element.contents[1] = alliance and element.contents[0] = "Fight!" {
				//write "My name is " + name + " and I received the fight message!" color: #pink;
				battleIsHappening <- true;
				add element to: informsList;
			}		
		}
	}
	
	///////////////////////EN adelante no uso ninguna de tus variables, solo el targetPoint
	reflex knowProvisionLocation when: !provisionLocationKnown {
		ask Provision {
			if self.alliance = myself.alliance {
				myself.provisionsLocation <- self.location;	
			}
		}
		provisionLocationKnown <- true;
	}
	
	reflex transportArrived when: injured {
		loop element over: informs {
			if element.contents[1] = alliance and element.contents[0] = "Coming to pick you up!"{
				transportAssigned <- element.contents[2];
				medicAssigned <- element.sender;
				medicLoopDone <- true;
			}
		}
		if medicLoopDone {
			ask Medic(medicAssigned) {
				self.injuredLocation <- myself.location;
				if distance_to (self.location, myself.location) < 1 {
					self.targetPoint <- myself.provisionsLocation;
					myself.targetPoint <- myself.provisionsLocation;
					myself.transportSpeed <- self.transportSpeed;
				}
			}
			ask Transport(transportAssigned) {
				if distance_to (self.location, myself.location) < 1 {
					self.targetPoint <- myself.provisionsLocation;
				}
			}	
		}
	}
	
	reflex goToInitialPosition {
		ask Provision {
			if distance_to (myself.location, self.location) < 1 and myself.alliance = self.alliance {
				myself.wentToProvisions <- true;
				if myself.alliance = 1 {
					myself.agentColor <- #green;
				}
				else {
					myself.agentColor <- #red;	
				}
			}
		}
		if wentToProvisions {
			targetPoint <- initialPosition;
		}
		if wentToProvisions{
			ask Medic(medicAssigned) {
				self.targetPoint <- self.initialLocation;
				do resetControlVariables;
			}
			ask Transport(transportAssigned) {
				self.targetPoint <- self.initialLocation;
				do resetControlVariables;
			}
		}
		if wentToProvisions and location = initialPosition {
			do resetControlVariables;
		}
	}
	
	/////////////////////////////////////////Pense meter todas las variables de control en acciones para cuando haya que resetear las cosas
	action resetControlVariables {
		medicAssigned <- nil;
		medicLoopDone <- false;
		speed <- initialSpeed;
		injured <- false;
		testInjured <- false;
		fightSequence <- 0;
		fighting <- false;
		wentToProvisions <- false;
	}
}

species Medic skills:[moving, fipa] {
	///////////////////////////////////////////////Asumo que de aqui en adelante no has modificado mucho porque estaba con los Soldiers mas que todo
	int alliance;
	point injuredLocation;
	point targetPoint;
	bool moveControl;
	bool occupied;
	list<Transport> availableTransports;
	bool transportEnRoute;
	bool injuredFound;
	agent<Transport> transportAssigned;
	agent<Soldier> injuredSoldier;
	bool transportLoopDone;
	float transportSpeed;
	bool onTransport;
	point initialLocation;
	bool initialLocationKnown;
	float initialSpeed;
	
	init {
		alliance <- alliance;
		initialSpeed <- 0.05;
	}
	
	aspect base {
        draw sphere(1.5) at: location color: #violet;
        list(Medic)[0].occupied <- true;
        list(Medic)[2].occupied <- true;
    }
    
    reflex doWander {
		do wander speed: 0.01;
	}
	
	reflex knowInitialLocation when: !initialLocationKnown {
		initialLocation <- location;
		initialLocationKnown <- true;
	}
	
	reflex moveToTarget when: moveControl {
		if transportLoopDone {
			do goto target:targetPoint speed: transportSpeed;
		}
		else {
			do goto target:targetPoint speed: initialSpeed;
		}
	}
	
	reflex receiveInjured when: !injuredFound{
		loop element over: informs {
			if element.contents[1] = alliance and element.contents[0] = "Injured found!" {
				occupied <- true;
				injuredLocation <- element.contents[2];
				injuredSoldier <- element.contents[3];
				//write "My name is " + name + " and there is an injured soldier reported at " + injuredLocation color: #red;
				//write "Transport needed at " + location + "!" color: #red;
				ask Transport {
					if !self.occupied {
						add self to: myself.availableTransports;
					}
				}
				do start_conversation with: [ to :: availableTransports, protocol :: 'fipa-contract-net', 
					performative :: 'inform', contents :: ["Pick me up!", alliance, location, injuredLocation, injuredSoldier] ];
				injuredFound <- true;
			}
		}
	}
	
	reflex transportArrived {
		loop element over: informs {
			if element.contents[1] = alliance and element.contents[0] = "Pick up!"{
				transportAssigned <- element.sender;
				transportLoopDone <- true;
			}
		}
		if transportLoopDone {
			ask Transport(transportAssigned) {
				if distance_to (self.location, myself.location) < 1{
					self.targetPoint <- myself.injuredLocation;
					myself.targetPoint <- myself.injuredLocation;
					myself.transportSpeed <- self.transportSpeed;
					myself.moveControl <- true;
					myself.transportAssigned <- self;
				}
			}
			do start_conversation with: [ to :: list(injuredSoldier), protocol :: 'fipa-contract-net', 
				performative :: 'inform', contents :: ["Coming to pick you up!", alliance, transportAssigned] ];
		}
	}
	
	action resetControlVariables {
		transportAssigned <- nil;
		transportLoopDone <- false;
		speed <- initialSpeed;
		injuredFound <- false;
		injuredLocation <- nil;
		//moveControl <- false;
		availableTransports <- [];
		injuredLocation <- nil;
		injuredSoldier <- nil;
		occupied <- false;
	}
}

species Transport skills:[moving, fipa] {
	
	int alliance;
	point targetPoint;
	bool moveControl;
	point initialLocation;
	bool initialLocationSaved;
	bool occupied;
	float transportSpeed <- 0.1;
	agent<Soldier> injuredSoldier;
	
	init {
		alliance <- alliance;
		//name <- "Transport";
	}
	
	aspect base {
        draw cube(2.5) color: #black;
        list(Transport)[0].occupied <- true;
		list(Transport)[2].occupied <- true;
    }
    
    reflex saveInitialLocation when: !initialLocationSaved {
    	initialLocation <- location;
    	initialLocationSaved <- true;
    }
    
    reflex doWander {
		do wander speed: 0.01;
	}
	
	reflex moveToTarget when: moveControl {
		do goto target:targetPoint speed: transportSpeed;
	}
	
	reflex injuredReported {
		point medicLocation;
		loop element over: informs {
			if element.contents[1] = alliance and element.contents[0] = "Pick me up!" {
				medicLocation <- element.contents[2];
				targetPoint <- medicLocation;
				injuredSoldier <- element.contents [4];
				moveControl <- true;
				occupied <- true;
				do start_conversation with: [ to :: element.sender, protocol :: 'fipa-contract-net', 
					performative :: 'inform', contents :: ["Pick up!", alliance, location] ];
			}
		}
	}
	
	action resetControlVariables {
		injuredSoldier <- nil;
		//moveControl <- false;
		occupied <- false;
	}
	
}

species Provision {
	
	int alliance;
	
	init {
		alliance <- alliance;
	}
	
	aspect base {
        draw sphere(1.5) color: #white;
    }
}

grid BattleGrid width: 100 height: 100 neighbors: 8 {
	
}

experiment BattleField type: gui {
    output {
    	display main_display type: opengl {
    		grid BattleGrid;
			species Commander aspect: base;
			species Soldier aspect: base;
			species Medic aspect: base;
			species Transport aspect: base;
			species Provision aspect: base;
       	}
    }
}

