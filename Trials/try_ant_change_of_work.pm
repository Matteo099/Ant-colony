/*
  Testing change work rules
  
  Expected behavior: 
  - if there is a lot of food, the Foragers are more likely to become Nurses
  - if there is a little food, the Nurses are more likely to become Foragers 
*/

const ENERGY = 10;
const FOOD_STORAGE = 10;

species Q of [0, ENERGY]*[0, FOOD_STORAGE]; 	/* Queen    : Q[i, j] queen with hungry level i, and j is the food storage */
species N of [0, ENERGY]; 		                /* Nurse    : N[i] hunger of the nurse ant */
species F of [0, ENERGY]; 		                /* Forager  : F[i] hunger of the forager ant */
species D;                                    /* A useless agents (used only to check the percentage operator effects with N and F on the rules) */

/* ======================================= */
/*                  LABELS                 */
/* ======================================= */
label nurses = { N[i for i in [0,ENERGY]] }
label foragers = { F[i for i in [0,ENERGY]] }
label workers = { N[i for i in [0,ENERGY]], F[i for i in [0,ENERGY]] }

/* Change of work rules */
rule nurse_becomes_forager for i in [0, ENERGY/2] and j in [0, ENERGY] and f in [0, FOOD_STORAGE] {
  /* #nurses * (1 - f / FOOD_STORAGE) * (1 - %foragers) */
  Q[j,f]|N[i] -[ #nurses * (1 - f / FOOD_STORAGE) * (#nurses / #workers) ]-> Q[j,f]|F[i]
}
rule forager_becomes_nurse for i in [0, ENERGY/2] and j in [0, ENERGY] and f in [0, FOOD_STORAGE] {
  /* #foragers * (f / FOOD_STORAGE) * (1 - %nurses) */
  Q[j,f]|F[i] -[ #foragers * (f / FOOD_STORAGE) * (#foragers / #workers) ]-> Q[j,f]|N[i]
}


measure n_queen = #Q[i, j for i in [0,ENERGY] and j in [0,FOOD_STORAGE]];
measure n_nurse = #nurses;
measure n_forager = #foragers;
measure n_workers = #workers;
measure p_nurse = %nurses;
measure p_forager = %foragers;

/* Balanced system with a lot of food; Expectation: 5 Foragers, 15 Nurses */
system balancedFoodH = Q[0, 9]<1>
                        |N[0]<10>
                        |F[0]<10>
                        |D<100>;

/* Balanced system with a little food; Expectation: 5 Nurses, 15 Foragers */
system balancedFoodL = Q[0, 1]<1>
                        |N[0]<10>
                        |F[0]<10>
                        |D<100>;

/* Balanced system with half food; Expectation: 10 Nurses, 10 Foragers */
system balancedFoodM = Q[0, 5]<1>
                        |N[0]<10>
                        |F[0]<10>
                        |D<100>;

/* Unbalanced system with a lot of food;  Expectation: 5 Foragers, 15 Nurses */
system unbalancedFoodH = Q[0, 9]<1>
                          |N[0]<5>
                          |F[0]<15>
                          |D<100>;

/* Unbalanced system with a little food; Expectation: 5 Nurses, 15 Foragers */
system unbalancedFoodL = Q[0, 1]<1>
                          |N[0]<5>
                          |F[0]<15>
                          |D<100>;

/* Unbalanced system with half food; Expectation: 10 Nurses, 10 Foragers */
system unbalancedFoodM = Q[0, 5]<1>
                          |N[0]<5>
                          |F[0]<15>
                          |D<100>;