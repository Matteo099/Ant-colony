/*
 * Matteo Romagnoli - PAS Exam
 *
 * Ant Colony
 * The ant colony is composed by different type of ants, each having a particular role:
 * - Queen (Q): is the queen of the colony, it is going to depositate new Eggs (Larve), depending on the food storage & queen hungry / mass;
 * - Nurses (N): this ants are going to operate always inside the nest, and provide food to the queen & larves;
 * - Foragers (F): they collect food from the outside and provide nutrients for the nest. They never operate inside the nest;
 * - Larvae (L): with the term Larvae we refer to Eggs, Larvae and Pupi, and so, they are not still ants, but they require food in order to grow; when old enough (adult ant), they become Foragers or Nurses.
 * 
 * Nurses and Foragers can change their role depending on the amount of food stored in the nest.
 *
 * In particular 2 factors influence the colony survival & grow:
 * 1. Temperature: the ideal temperature is between 23 and 35 °C (we assume 29 °C as the ideal temperature); at these temperatures, ants are more likely to forage for food and maintain an active colony (optimal metabolism).
 * 2. Quantity of food in the environment.
 * 
 * The consumption of food depends on the role of the ant, if it work inside or outside (temperature), the level of energy and the global food storage.
 * 
 * The temperature has effects on workers' size, immature ants' development, and queen's reproduction:
 * 1- There is no effects of temperature and food on ant colony’s energy and population dynamics.
 * 2- Temperature elevations (or diminuition) will increase the risk of ant colonies for dying out because they need to consume more energy to sustain themselves.
 * 3- Changes of food availability will affect energy and population dynamics of ant colonies.
 *
 * References: 
 *  https://harvardforest.fas.harvard.edu/ants/life-cycle
 *	https://onlinelibrary.wiley.com/doi/full/10.1111/gcb.16140 
 *  https://www.antwiki.org/wiki/Life_in_an_Ant_Colony
 *	https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4951116
 *	https://www.terminix.com/ants/behavior/do-ants-hibernate
 *  https://www.ted.com/talks/deborah_gordon_the_emergent_genius_of_ant_colonies
 *  https://dc.etsu.edu/cgi/viewcontent.cgi?article=3757&context=etd
 */

/* ======================================= */
/*              CONST & AGENTS             */
/* ======================================= */
/* -------- Maths constants -------- */
const e = 2.718281;
const beta = 4;
const sigma = 15;
const gamma = 0.32;
const alpha = 1;
const boundaryR = -41;
const boundaryL = -11;

/* -------- Environment Parameters -------- */
param initial_larvae = 20;
param initial_nurses = 10;
param initial_forager = 10;

param temperature = 13;
param foodAvailabilityRate = 1; /* Ranges between 0 and 1 */

/* -------- Generic Constants -------- */
const ENERGY = 4;               /* Energy (or hungry) level of an ant: 0 = no hunger (full of energy), 4 = really hungry (no energy) */
const FOOD_STORAGE = 20;        /* Food storage: 0 = no food, 10 = storage full of food */
const IDEAL_TEMPERATURE = 29;   /* The ideal temperature for the ant is between 23 and 35 °C; we can consider 29°C and the tolerance +-10°C */
const DELTA_TEMPERATURE = 10;   /* The delta of the temperature (tolerance of the ant +- 10°C) */

/* -------- Helper constants --------- */
const initial_ants = initial_nurses + initial_forager + initial_larvae;
const delta_ants = initial_ants * 0.25; /* 25% tolerance */

/* -------- Agents -------- */
species H of [0, FOOD_STORAGE];                 /* Home (nest)  : H[i] specify the amount of food in the nest */
species Q of [0, ENERGY]; 	                    /* Queen        : Q[i] queen with hungry level i */
species L of [0, ENERGY]; 		                  /* Larvae       : L[i] hunger of the larva */
species N of [0, ENERGY]; 		                  /* Nurse        : N[i] hunger of the nurse ant */
species F of [0, ENERGY]; 		                  /* Forager      : F[i] hunger of the forager ant */
species DL; 			                              /* Death larva */
species DA; 			                              /* Death ant */

/* -------- Probability Rates & Multipliers -------- */
const eggsLaysDelayRate     = 0.1;
const queenFertilityRate    = 1.0;  /* Ranges between 0.2 and 1 -> (0.2, 1] */

const baseConsumeEnergyRate = 0.25;
const eatRate               = 1.0;
const transformationRate    = 0.5;
const larvaGrowRate         = 0.2;

const nurseFeedQueenRate    = 2.0;
const nurseFeedLarvaRate    = 0.6;  /* Ranges between 0.5 and 1 -> (0.5, 1] */
const nurseCleanRate        = 0.25; /* Ranges between 0.2 and 1 -> (0.2, 1] */
const foragerWorkRate       = 0.75; /* Ranges between 0.5 and 1 -> (0.5, 1] */

const changeOfWorkRate      = 0.5;

/* 
 * The probability that the queen dies is pretty low, because, it can dies only in 2 ways: 
 * - by human's work;
 * - other ants kill it;
 * Since, in this model, the human influence is not take into account, the queen will die only if the workers ant kill it; 
 * but again, also the second condition is not probable since, the workers kill a queen only if there is a surplus of queen in a colony. 
 * In the model we consider only one queen. 
 *
 * The queen will die only when the colony is dying and it remains alone. 
 */
const queenDeathRate        = 0.001;  
const larvaDeathRate        = 1.0;      /* If larva is not well feeded, it will die */
const workerDeathRate       = 0.25; 

/* Must range between 0 and 2 */
const larvaConsumeEnergyMultiplier    = 1.75;
const queenConsumeEnergyMultiplier    = 1;
const nurseConsumeEnergyMultiplier    = 0.5;
const foragerConsumeEnergyMultiplier  = 1;

/* 
 * The function (generalized normal function) ranges between ~0 and ~1: as we move away from 29 °C, the influence function increase until reaches the maximum.
 *                                                                                      
 *             ^                                                                        
 * Probability |                                                                         
 *             |                                                                         
 *             |                                                                         
 *             |                                                                         
 *             |                                                                         
 *             |                                                                         
 *  ~1   -----------\                         /-------------                                 
 *             |     -\                      /                                          
 *             |       -\                   |                                           
 *             |         \                  |                                             
 *             |          -\               /                                              
 *             |            \             |                                             
 *             |             \            |                                               -
 *             |              \          /                                                  
 *  ~0         |               \--------/                                                   
 *      -------+------------------------------------------->                             
 *           0 |              23   29   35      Temperature                              
 *             |                                                                         
 *             |                                                                         
 *
 */
const temperatureInfluence = 0.99 - 0.98 * ( beta / (2 * (sigma + DELTA_TEMPERATURE) * gamma * (1 / beta))) * (e ^ -(((temperature - IDEAL_TEMPERATURE) / (sigma + DELTA_TEMPERATURE))^beta)) * (1 / (1 + e ^ (alpha*(temperature + boundaryR)))) * (1 / (1 + e ^ (-alpha*(temperature + boundaryL))));
const eggs = 30; /* number of eggs the queen will lay */
const antBound = eggs * 7;

/* ======================================= */
/*                  LABELS                 */
/* ======================================= */
label nurses = { N[i for i in [0,ENERGY]] }
label foragers = { F[i for i in [0,ENERGY]] }
label workers = { N[i for i in [0,ENERGY]], F[i for i in [0,ENERGY]] }
label larvae = { L[i for i in [0,ENERGY]] }
label ants = { N[i for i in [0,ENERGY]], F[i for i in [0,ENERGY]], Q[i for i in [0,ENERGY]] }
label starve_l_q = { Q[i for i in [ENERGY/2,ENERGY]], L[i for i in [ENERGY/2,ENERGY]] } 


/* ======================================= */
/*                   RULES                 */
/* ======================================= */
/* --------- Reproduction rules ---------- */
/* The queen will lay eggs depending on 7 factor: 
 * - the fertility (queenFertilityRate);
 * - the more satiated the queen, the more likely she is to lay eggs (1.0 - i / ENERGY);
 * - the temperature;
 * - the number of current larvae (1 / (#larvae + 1));
 * - it is highly influenced by the food stored in the nest, indeed the more food there is in the nest (food storage), the more likely the queen is to lay eggs ((f / FOOD_STORAGE)^2);
 * - the size of the colony;
 * - food availability;
 *
 * The queen will lay a number of eggs that are constant (eggs) and consume a lot of energy.
 */
rule queen_lays_eggs for i in [0, ENERGY/2] and f in [FOOD_STORAGE/2, FOOD_STORAGE] {
  Q[i]|H[f] -[ (1.0 - i / ENERGY) * ((f / FOOD_STORAGE) ^ 2) * (queenFertilityRate - temperatureInfluence / 5) * (1 / (#larvae + 1)) * ((#ants * (foodAvailabilityRate ^ 0.5)) / antBound) ]-> Q[i+2]|H[f]|L[0]<eggs>
}

/* ------- Consume energy rules --------- */
/* The energy consumed (Metabolism of the ant) depends on the Mass of the ant (that is abstracted with the Multipliers) and the Temperature: 
 * - Farter is the temperature from the ideal temperature, faster will be the metabolism (temperature influence);
 * - The heavier the ant, the faster the metabolism (multiplier).
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
/* 
 * When an ant eats then the food from the global storage is decreased by one. Only Nurses and Foragers eat food directly.
 */
rule nurse_hungry_eats for i in [ENERGY/2, ENERGY] and f in [1, FOOD_STORAGE] {
  N[i]|H[f] -[ i / ENERGY * eatRate ]-> N[i-1]|H[f-1]
}
rule forager_hungry_eats for i in [ENERGY/2, ENERGY] and f in [1, FOOD_STORAGE] {
  F[i]|H[f] -[ i / ENERGY * eatRate ]-> F[i-1]|H[f-1]
}

/* ------------- Work rules ------------- */
/* The work of the ants are mainly influenced by the Temperature:
 * - The farther the temperature is from the ideal temperature, slower the Nurse will be and the slower it will be for feed the queen and larvae;
 * - The farther the temperature is from the ideal temperature, slower the Forager will be and the slower it will be for food to be harvested.
 *
 * Moreover, the Foragers are also influenced by the availability of the food: the more food there is, the greater it will be for food to be harvested.
 */
rule nurse_feed_queen for i in [0, ENERGY-1] and j in [2, ENERGY] and f in [2, FOOD_STORAGE] {
  N[i]|Q[j]|H[f] -[ nurseFeedQueenRate * (((#nurses) * 2 + 1) / (#ants + 1)) ]-> N[i+1]|Q[j-2]|H[f-2]
}
rule nurse_feed_larva for i in [0, ENERGY-1] and b in [ENERGY/2, ENERGY] and f in [FOOD_STORAGE/2, FOOD_STORAGE] {
  N[i]|L[b]|H[f] -[ (nurseFeedLarvaRate - temperatureInfluence / 2) * (f / FOOD_STORAGE) * (#nurses / #ants) ]-> N[i+1]|L[b-1]|H[f-1]
}
rule nurse_clean_nest for i in [0, ENERGY-1] and f in [0, FOOD_STORAGE-1] {
  N[i]|H[f]|DL -[ (nurseCleanRate - temperatureInfluence / 5) * (#DL / eggs) ]-> N[i]|H[f+1]
}
rule forager_collects_food for i in [0, ENERGY-1] and f in [0, FOOD_STORAGE-3] {
  F[i]|H[f] -[ (foragerWorkRate - temperatureInfluence / 2) * foodAvailabilityRate * (#foragers / #ants) ]-> F[i+1]|H[f+3]
}

/* ------------- Die rules ------------- */
/* The probability of death mainly depends on the energy level: the hungrier the ant, the more likely it is to die.
 * However, the probability of death also depends on the kind of ant:
 * - it is more likely the larva dies if not well feeded or if the temperature is not adequate;
 * - the worker death rate is pretty low.
 */
rule queen_dies {
  /* The power (^10) is used to delay the queen's death when executing the model more time (when replica > 1), in order to obtain consistent results. */
  Q[ENERGY-1] -[ queenDeathRate * (1 // #ants) ^ 10 ]-> DL
}
rule larva_dies for i in [ENERGY / 4 * 2, ENERGY] {
  L[i] -[ (i / ENERGY * larvaDeathRate) / 3 + temperatureInfluence / 3 * 2 ]-> DL
}
rule nurse_dies for i in [ENERGY / 4 * 3, ENERGY] {
  N[i] -[ i / ENERGY * workerDeathRate ]-> DA
}
rule forager_dies for i in [ENERGY / 4 * 3, ENERGY] {
  F[i] -[ i / ENERGY * workerDeathRate ]-> DA
}

/* ------- Larvae transformation rules -------- */
/* When a larva has grown enough, it will turn into: Nurse or Forager; the probability is the same for both, and it is 50%.
 * The growth is accelerated by the number of the larvae: the more larvae there are in the nest, the faster they will become adults.
 */
rule larva_becomes_nurse for i in [0, ENERGY] {
  L[i] -[ transformationRate * larvaGrowRate * #larvae * %larvae ]-> N[i]
}
rule larva_becomes_forager for i in [0, ENERGY] {
  L[i] -[ transformationRate * larvaGrowRate * #larvae * %larvae ]-> F[i]
}

/* ------------- Change of work rules -------------- */
/* During the life, an ant (Forager or Nurse) that is not dying ([0, ENERGY / 4 * 3]) can change the job:
 * - A Nurse can become a Forager if the amount of food stored in the nest is scarce, the starve ants is low and the percentage of Nurses increase;
 * - Viceversa, a Forager can become a Nurse if the amount of food stored in the nest is plentiful, the starve ants are high and the percentage of Foragers increase.
 */
rule nurse_becomes_forager for i in [0, ENERGY / 4 * 3] and f in [0, FOOD_STORAGE] {
  N[i]|H[f] -[ changeOfWorkRate * #nurses * (1 - (f / (FOOD_STORAGE - 1) + #starve_l_q / (#larvae + 1)) / 2) * (#nurses // #workers) ]-> F[i]|H[f]
}
rule forager_becomes_nurse for i in [0, ENERGY / 4 * 3] and f in [0, FOOD_STORAGE] {
  F[i]|H[f] -[ changeOfWorkRate * #foragers * (f / (FOOD_STORAGE - 1) + #starve_l_q / (#larvae + 1)) / 2 * (#foragers // #workers) ]-> N[i]|H[f]
}


/* ======================================= */
/*          MEASURES & PREDICATES          */
/* ======================================= */
measure n_queen = #Q[i for i in [0,ENERGY]];
measure n_nurse = #nurses;
measure p_nurse = %nurses;
measure n_forager = #foragers;
measure p_forager = %foragers;
measure n_larvae = #larvae;
measure p_larvae = %larvae;
measure n_ants = #ants;
measure n_death = #DA;
measure n_larvae_death = #DL;
measure n_starve_l_q = #starve_l_q;

predicate colony_stationary = ((#nurses + #foragers + #larvae + delta_ants >= initial_ants) || (#nurses + #foragers + #larvae - delta_ants <= initial_ants));
predicate colony_growing = (#nurses + #foragers + #larvae > initial_ants);
predicate colony_survived = (#Q[i for i in [0,ENERGY]] > 0);
predicate colony_dying = ( #Q[i for i in [0,ENERGY]] == 0 );


/* ======================================= */
/*                SYSTEM DEF               */
/* ======================================= */
system initial = H[FOOD_STORAGE-1]<1>|Q[0]<1>|N[0]<initial_nurses>|F[0]<initial_forager>|L[0]<initial_larvae>|DA<0>|DL<0>;