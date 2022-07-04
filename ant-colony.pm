/*
 * Matteo Romagnoli - PAS Exam
 *
 * References: 
 *  https://harvardforest.fas.harvard.edu/ants/life-cycle
 *	https://onlinelibrary.wiley.com/doi/full/10.1111/gcb.16140 
 *  https://www.antwiki.org/wiki/Life_in_an_Ant_Colony
 *	https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4951116
 *	https://www.terminix.com/ants/behavior/do-ants-hibernate
 *  https://www.ted.com/talks/deborah_gordon_the_emergent_genius_of_ant_colonies
 *  https://dc.etsu.edu/cgi/viewcontent.cgi?article=3757&context=etd
 *
 * Ant Colony
 * The ant colony is composed by different type of ants, each having a particular role:
 * - Queen (Q): is the queen of the colony, it is going to depositate new Eggs (Larve), depending on the food storage & queen hungry / mass;
 * - Nurses (N): this ants are going to operate always inside the nest, and provide food to the queen & larves;
 * - Foragers (F): they collect food from the outside and provide nutrient for the nest. They never operate inside the nest;
 * - Larvae (L): with the term Larvae we refer to Eggs, Larvae and Pupi, and so, they are not still ants, but they require food in order to grow; when old enough (adult ant), they become Foragers or Nurses.
 * 
 * Nurses and Foragers can change their role depending on the amount of food stored in the nest.
 *
 * In particular 2 factors influence the colony survival & grow:
 * 1. Temperature: the ideal tempherature is between 23 and 35 °C (we assume 29 °C as the ideal temperature); at these temperatures, ants are more likely to forage for food and maintain an active colony (optimal metabolism).
 * 2. Quantity of food in the environment.
 * 
 * The consumption of food depends on the role of the ant, if it work inside or outside (temperature), the level of energy and the global food storage.
 * 
 * The temperature has effects on workers' size, immature ants' development, and queen's reproduction:
 * 1- There is no effects of temperature and food on ant colony’s energy and population dynamics.
 * 2- Temperature elevations (or diminuition) will increase the risk of ant colonies for dying out because they need to consume more energy to sustain themselves.
 * 3- Changes of food availability will affect energy and population dynamics of ant colonies. --NO-> Rich food sources can protect ant colonies from decaying even in very high temperature. <-NO--
 *
 */

/* ======================================= */
/*              CONST & AGENTS             */
/* ======================================= */
/* -------- Math constants -------- */
const e = 2.718281;
const beta = 4;
const sigma = 5;
const gamma = 0.53;
const alpha = 1;
const delta = -41;

/* -------- Environment Parameters -------- */
param initial_larvae = 20;
param initial_nurses = 10;
param initial_forager = 10;

param temperature = 29;
param foodAvailabilityRate = 1; /* Ranges between 0 and 1 */

/* -------- Generic Constants -------- */
const ENERGY = 10;              /* Energy (or hungry) level of an ant: 0 = no hunger (full of energy), 10 = really hungry (no energy) */
const FOOD_STORAGE = 10;        /* Food storage: 0 = no food, 10 = storage full of food */
const IDEAL_TEMPERATURE = 29;   /* The ideal temperature for the ant is between 23 and 35 °C; we can consider 29°C and the tollerance +-10°C */
const DELTA_TEMPERATURE = 10;   /* The delta of the temperature (tollerance of the ant +- 10°C) */

/* -------- Agents -------- */
species H of [0, FOOD_STORAGE];                 /* Nest (home)  : H[i] specify the amount of food in the nest */
species Q of [0, ENERGY]; 	                    /* Queen        : Q[i] queen with hungry level i */
species L of [0, ENERGY]; 		                  /* Larvae       : L[i] hunger of the larve */
species N of [0, ENERGY]; 		                  /* Nurse        : N[i] hunger of the nurse ant */
species F of [0, ENERGY]; 		                  /* Forager      : F[i] hunger of the forager ant */
species DL; 			                              /* Death larva */
species DA; 			                              /* Death ant */

/* -------- Probability Rates & Multipliers -------- */
const queenFertilityRate = 0.1;
const baseConsumeEnergyRate = 0.25;
const eatRate = 0.5;
const transformationRate = 0.5;
const larvaGrowRate = 0.2;

const nurseWorkRate = 0.50;
const nurseFeedLarvaRate = 0.50;
const nurseFeedQueenRate = 0.75;
const nurseCleanRate = 0.25;
const foragerWorkRate = 0.750;

const queenDeathRate = 0.001; /* It is really rare that the queen dies */
const larvaDeathRate = 1.0;  /* If larva is not well feeded, it will die */
const workerDeathRate = 0.25; 

/* Must range between 0 and 2 */
const larvaConsumeEnergyMultiplier = 1.5;
const queenConsumeEnergyMultiplier = 2;
const nurseConsumeEnergyMultiplier = 0.5;
const foragerConsumeEnergyMultiplier = 1;

/* 
 * The function (gaussian function) ranges between 0.01 and 0.99: as we move away from 29 °C, the influence function increase until reaches the maximum (0.99).
 *                                                                                      
 *             ^                                                                        
 * Probability |                                                                         
 *             |                                                                         
 *             |                                                                         
 *             |                                                                         
 *             |                                                                         
 *             |                                                                         
 *  0.99 -----------\                          -------------                                 
 *             |     -\                       /                                          
 *             |       -\                   -/                                           
 *             |         \                 /                                             
 *             |          -\              /                                              
 *             |            -\           /                                               
 *             |              \        -/                                               -
 *             |               -\     /                                                  
 *        0.01 |                 -\  /                                                   
 *      -------+------------------------------------------->                             
 *             |              23   29   35      Temperature                              
 *             |                                                                         
 *             |                                                                         
 *
 */
const temperatureInfluence = 0.99 - 0.98 * ( beta / (2 * (sigma + DELTA_TEMPERATURE) * gamma * (1 / beta))) * (e ^ -(((temperature - IDEAL_TEMPERATURE) / (sigma + DELTA_TEMPERATURE))^beta)) * (1 / (1 + e ^ (alpha*(temperature + delta))));
/* const temperatureInfluence = 1 - (0.01 + 0.98 * e ^ -((temperature - IDEAL_TEMPERATURE) ^ 2 / DELTA_TEMPERATURE ^ 2)); */
const eggs = 10; /* number of eggs the queen will lay */

/* ======================================= */
/*                  LABELS                 */
/* ======================================= */
label nurses = { N[i for i in [0,ENERGY]] }
label foragers = { F[i for i in [0,ENERGY]] }
label workers = { N[i for i in [0,ENERGY]], F[i for i in [0,ENERGY]] }
label larvae = { L[i for i in [0,ENERGY]] }


/* ======================================= */
/*                   RULES                 */
/* ======================================= */
/* --------- Reproduction rules ---------- */
/* The queen will lay eggs depending on 3 factor: 
 * - the fertility (queenFertilityRate);
 * - the more satiated the queen, the more likely she is to lay eggs (1.0 - i / ENERGY);
 * - the more food there is in the nest (food storage), the more likely the queen is to lay eggs (1.0 - f / FOOD_STORAGE);
 * - the temperature.
 * 
 * The queen will lay a number of eggs that is constant (eggs).
 */
rule queen_lays_eggs for i in [0, ENERGY/2] and f in [0, FOOD_STORAGE] {
  Q[i]|H[f] -[ (1.0 - i / ENERGY) * (1.0 - f / FOOD_STORAGE) * queenFertilityRate * (1 - temperatureInfluence) ]-> Q[i+1]|H[f]|L[0]<eggs>
}

/* ------- Consume energy rules --------- */
/* The energy consumed (Metabolism of the ant) depens on the Mass of the ant (that is abstracted with the Multipliers) and the Temperature: 
 * - Farter is the temperature from the ideal T, faster will be the metabolism (Temperature influence);
 * - The heavier the ant, the faster the metabolism.
 */
rule larva_consume_energy for i in [0, ENERGY-1] {
  L[i] -[ baseConsumeEnergyRate * larvaConsumeEnergyMultiplier + temperatureInfluence / 2 ]-> L[i+1]
}
rule queen_consume_energy for i in [0, ENERGY-1] {
  Q[i] -[ baseConsumeEnergyRate * queenConsumeEnergyMultiplier + temperatureInfluence / 2 ]-> Q[i+1] 
}
rule nurse_consume_energy for i in [0, ENERGY-1] {
  N[i] -[ baseConsumeEnergyRate * nurseConsumeEnergyMultiplier + temperatureInfluence / 2 ]-> N[i+1]
}
rule forager_consume_energy for i in [0, ENERGY-1] {
  F[i] -[ baseConsumeEnergyRate * foragerConsumeEnergyMultiplier + temperatureInfluence / 2 ]-> F[i+1]
}

/* ----------- Eating rules ------------ */
/* When an ant eats then the food from the global storage is decreased by one. Only Nurses and Foragers eat food directly. */
rule nurse_hungry_eats for i in [ENERGY/2, ENERGY] and f in [2, FOOD_STORAGE] {
  H[f]|N[i] -[ eatRate ]-> H[f-1]|N[i-1]
}
rule forager_hungry_eats for i in [ENERGY/2, ENERGY] and f in [2, FOOD_STORAGE] {
  H[f]|F[i] -[ eatRate ]-> H[f-1]|F[i-1]
}

/* ------------- Work rules ------------- */
/* The work of the ants are mainly influenced by the Temperature:
 * - The farter the temperature is from the ideal temperature, slower the Nurse will be and the slower it will be for feed the queen and larvae;
 * - The farter the temperature is from the ideal temperature, slower the Forager will be and the slower it will be for food to be harvested.
 *
 * Moreover, the Foragers are also influenced by the availability of the food: more food there is, greater it will be for food to be harvested.
 */
rule nurse_feed_queen for i in [0, ENERGY-1] and j in [ENERGY/4, ENERGY] and f in [2, FOOD_STORAGE] {
  /* Since the queen is bigger that the normal ants, it will eat more food */
  N[i]|Q[j]|H[f] -[ nurseFeedQueenRate * (1 - temperatureInfluence) ]-> N[i+1]|Q[j-1]|H[f-2]
}
rule nurse_feed_larva for i in [0, ENERGY-1] and b in [ENERGY/2, ENERGY] and f in [3, FOOD_STORAGE] {
  N[i]|L[b]|H[f] -[ nurseFeedLarvaRate * (1 - temperatureInfluence) ]-> N[i+1]|L[b-1]|H[f-1]
}
rule nurse_clean_nest for i in [0, ENERGY-1] and f in [0, FOOD_STORAGE-1] {
  N[i]|H[f]|DL -[ nurseCleanRate * (1 - temperatureInfluence) * %DL ]-> N[i]|H[f+1]
}
rule forager_works for i in [0, ENERGY-1] and f in [0, FOOD_STORAGE-2] {
  F[i]|H[f] -[ foragerWorkRate * (1 - temperatureInfluence) * foodAvailabilityRate ]-> F[i+1]|H[f+2]
}

/* ------------- Die rules ------------- */
/* The probability of death mainly depends on the energy level: the hungrier the ant, the more likely it is to die.
 * However, the probability of death also depends on the kind of ant:
 * - it is really rare that the queen dies;
 * - it is more likely the larva dies if not well feeded;
 * - the worker death rate is pretty low.
 */
rule queen_dies for i in [0, ENERGY] when i > ENERGY / 4 * 3 {
  Q[i] -[ i / ENERGY * queenDeathRate ]-> DA
}
rule larva_dies for i in [0, ENERGY] when i > ENERGY / 4 * 3 {
  L[i] -[ i / ENERGY * larvaDeathRate ]-> DL
}
rule nurse_dies for i in [0, ENERGY] when i > ENERGY / 4 * 3 {
  N[i] -[ i / ENERGY * workerDeathRate ]-> DA
}
rule forager_dies for i in [0, ENERGY] when i > ENERGY / 4 * 3 {
  F[i] -[ i / ENERGY * workerDeathRate ]-> DA
}

/* ------- Larvae transformation rules -------- */
/* When a larva is grow enough, it will turn into: Nurse or Forager.
 * The probability is the same for both, and it is 50%.
 */
rule larva_becomes_nurse for i in [0, ENERGY] {
  L[i] -[ transformationRate * larvaGrowRate ]-> N[i]
}
rule larva_becomes_forager for i in [0, ENERGY] {
  L[i] -[ transformationRate * larvaGrowRate ]-> F[i]
}

/* ------------- Change of work rules -------------- */
/* During the life, an ant (Forager or Nurse) that is not dying ([0, ENERGY / 4 * 3]) can change the job:
 * - A Nurse can become a Forager if the amount of food stored in the nest is scarce and the percentage of Nurses increase;
 * - Viceversa, a Forager can become a Nurse if the amount of food stored in the nest is plentiful and the percentage of Foragers increase.
 */
rule nurse_becomes_forager for i in [0, ENERGY / 4 * 3] and f in [0, FOOD_STORAGE] {
  N[i]|H[f] -[ #nurses * (1 - (f/2) / (FOOD_STORAGE - 1)) * (#nurses / #workers) ]-> F[i]|H[f]
}
rule forager_becomes_nurse for i in [0, ENERGY / 4 * 3] and f in [0, FOOD_STORAGE] {
  F[i]|H[f] -[ #foragers * ((f / (FOOD_STORAGE - 1)) / 2) * (#foragers / #workers) ]-> N[i]|H[f]
}


/* ======================================= */
/*          MEASURES & PREDICATES          */
/* ======================================= */
measure n_queen = #Q[i for i in [0,ENERGY]];
measure n_nurse = #nurses;
measure n_forager = #foragers;
measure n_larvae = #larvae;
measure n_death = #DA;
measure n_larvae_death = #DL;

predicate colony_growing = (#nurses + #foragers + #larvae > initial_nurses + initial_forager + initial_larvae);
predicate colony_survived = (#Q[i for i in [0,ENERGY]] > 0);
predicate colony_dying = ( #Q[i for i in [0,ENERGY]] == 0 );


/* ======================================= */
/*                SYSTEM DEF               */
/* ======================================= */
system initial = H[FOOD_STORAGE-1]<1>|Q[0]<1>|N[0]<initial_nurses>|F[0]<initial_forager>|L[0]<initial_larvae>|DA<0>|DL<0>;