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
			agentColor <- #green;
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


species Commander skills:[moving] {
	
	int alliance;
	
	init {
		alliance <- alliance;
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
	
}

species Soldier skills:[moving] {
	
	int alliance;
	bool inField;
	bool initialPositionDefined;
	point initialPosition;
	rgb agentColor;
	
	init {
		
	}
	
	reflex doWander when: !inField {
		do wander speed: 0.01;
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
	
	aspect base {
		draw sphere(1.5) at: location color: agentColor;
    }
	
}

species Medic skills:[moving] {
	
	int alliance;
	
	init {
		alliance <- alliance;
	}
	
	aspect base {
        draw sphere(1.5) at: location color: #red;
    }
    
    reflex doWander {
		do wander speed: 0.01;
	}
	
}

species Transport skills:[moving] {
	
	int alliance;
	
	init {
		alliance <- alliance;
	}
	
	aspect base {
        draw cube(2.0) color: #black;
    }
    
    reflex doWander {
		do wander speed: 0.01;
	}
	
}

species Provision {
	
	int alliance;
	
	init {
		alliance <- alliance;
	}
	
	aspect base {
        draw sphere(1.5) color: #brown;
    }
}

grid BattleGrid width: 100 height: 100 neighbors: 8 {
	
}

experiment BattleField type: gui {
    output {
    	display main_display type: opengl {
    		grid BattleGrid;
    		species Provision aspect: base;
			species Transport aspect: base;
			species Commander aspect: base;
			species Soldier aspect: base;
			species Medic aspect: base;
       	}
    }
}

