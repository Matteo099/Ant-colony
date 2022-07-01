/*
 * Matteo Romagnoli - PAS Exam
 *
 * References: 
 *	https://onlinelibrary.wiley.com/doi/full/10.1111/gcb.16140 
 *	https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4951116
 *	https://www.terminix.com/ants/behavior/do-ants-hibernate
 *
 * Ant Colony
 * The ant colony is composed by different type of ants, each having a particular role:
 * - Queen (Q): is the queen of the colony, it is going to depositate new Eggs (Larve), depending on the food storage & queen hungry;
 * - Nurses (N): this ants are going to operate always inside the nest, and provide food to the queen & larves;
 * - Foragers (F): they collect food from the outside and provide nutrient for the social stomach. They never operate inside the nest;
 * - Larvae (L): with the term Larvae we refer to Eggs, Larvae and Pupi, and so, they are not still ants, but they require food in order to grow; when old enough, they become Foragers or Nurses.
 *
 * In particular 2 factors influence the colony survival & grow:
 * 1. Temperature: the ideal tempherature is between 23 and 35 °C; at these temperatures, ants are more likely to forage for food and maintain an active colony.
 * 2. Quantity of food in the environment.
 * 
 * The consumption of food depends on the role of the ant, if it work inside or outside (temperature), the level of hungry and the global food storage.
 */
const H = 10; /* hungry levels */
const M = 5; /* food storage */

species Q of [0, H]*[0, M]; 	/* Queen    : Q[i, j] queen with hungry level i, and j is the food storage */
species L of [0, H]; 		      /* Larvae   : L[i] hunger of the larve (0 = no hunger, 10 = really hungry) */
species N of [0, H]; 		      /* Nurse    : N[i] hunger of the nurse ant (0 = no hunger, 10 = really hungry) */
species F of [0, H]; 		      /* Forager  : F[i] hunger of the forager ant (0 = no hunger, 10 = really hungry) */
species D; 			              /* Death */

const rate = 1.0;
const halfRate = 0.5;
const eatRate = 0.5;
const consumeEnergyRate = 0.25;
const eggsRate = 1.0;

const larvaeConsumeEnergyMultiplier = 2.5;
const nurseConsumeEnergyMultiplier = 0.75;
const foragerConsumeEnergyMultiplier = 1;

param temperature = 20;
param foodQuantity = 1000;

/* --------- Reproduction rules ---------- */
rule reproduction for i in [0, H-1] and f in [1, M] {
  /* 1.0 - i / H => più la regina è sazia, più è probabile che depone uova */
  /* 1.0 - f / M => più cibo è presente, più è probabile che la regina depone uova */
  Q[i, f] -[ (1.0 - i / H) * (1.0 - f / M) * eggsRate ]-> Q[i+1, f]|L[0]
}

/* ------- Consume energy rules --------- */
/* TODO: they are needed? Maybe only for larvae... */
rule larva_consume_energy for i in [0, H-1] {
  L[i] -[ consumeEnergyRate * larvaeConsumeEnergyMultiplier ]-> L[i+1]
}
rule nurse_consume_energy for i in [0, H-1] {
  N[i] -[ consumeEnergyRate * nurseConsumeEnergyMultiplier ]-> N[i+1]
}
rule forager_consume_energy for i in [0, H-1] {
  F[i] -[ consumeEnergyRate * foragerConsumeEnergyMultiplier ]-> F[i+1]
}

/* ----------- Eating rules ------------ */
/* When an ant eats then the food from the global storage is decreased by one */
rule nurse_hungry_eats for i in [3, H] and j in [0, H] and f in [1, M] {
  Q[j,f]|N[i] -[ eatRate ]-> Q[j,f-1]|N[i-1]
}
rule forager_hungry_eats for i in [3, H] and j in [0, H] and f in [1, M] {
  Q[j,f]|F[i] -[ eatRate ]-> Q[j,f-1]|F[i-1]
}

/* ------------- Work rules ------------- */
rule nurse_works for i in [0, H-1] {
  /* rule for feeding larvae & queen */
  N[i] -[ 0.5 ]-> N[i+1]
}
rule nurse_feed_queen for i in [0, H-1] and j in [3, H] and f in [1, M] {
  Q[j,f]|N[i] -[ 1.0 ]-> Q[j-1,f-1]|N[i]
}
rule nurse_feed_larvae for i in [0, H-1] and b in [3, H] and j in [0, H] and f in [1, M] {
  Q[j,f]|N[i]|L[b] -[ 1.0 ]-> Q[j,f-1]|N[i]|L[b-1]
}
rule forager_works for i in [0, H-1] and j in [0, H] and f in [1, M-1] {
  Q[j,f]|F[i] -[ 0.25 ]-> Q[j,f+1]|F[i+1]
}

/* ------------- Die rules ------------- */
/* The probability of death depends on the hunger level: the hungrier the ant, the more likely it is to die */
/* TODO: the probability of death increase also with the age! */
rule queen_dies for i in [7, H-1] and f in [0, M-1]{
  Q[i, f] -[ i / H ]-> D
}
rule larvae_dies for i in [7, H-1] {
  L[i] -[ i / H ]-> D
}
rule nurse_dies for i in [7, H-1] {
  N[i] -[ i / H ]-> D
}
rule forager_dies for i in [7, H-1] {
  F[i] -[ i / H ]-> D
}

/* ------- Larvae transformation rules -------- */
rule larvae_becomes_nurse for i in [0, H] {
  L[i] -[ halfRate ]-> N[i]
}
rule larvae_becomes_forager for i in [0, H] {
  L[i] -[ halfRate ]-> F[i]
}

measure n_queen = #Q[i, j for i in [0,H] and j in [0,M]];
measure n_nurse = #N[i for i in [0,H]];
measure n_forager = #F[i for i in [0,H]];
measure n_larvae = #L[i for i in [0,H]];
measure n_death = #D;

predicate colony_survived = (#N[i for i in [0,H]] + #F[i for i in [0,H]] + #L[i for i in [0,H]] > 0);

param initial_larvae = 0;
param initial_nurses = 0;
param initial_forager = 0;

/* TODO */
predicate colony_dying = ( initial_larvae > #L[i for i in [0,H]] );

system initial = Q[0, M-1]<1>|N[0]<initial_nurses>|F[0]<initial_forager>|L[0]<initial_larvae>|D<0>;