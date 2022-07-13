/*
  Testing change work rules
  
  Expected behavior: 
  - if there is a lot of food, the Foragers are more likely to become Nurses
  - if there is a little food, the Nurses are more likely to become Foragers 
*/

const FOOD_STORAGE = 10;

species Q of [0, FOOD_STORAGE]; 	/* Queen    : Q[i, j] queen with hungry level i, and j is the food storage */
species N; 		                /* Nurse    : N[i] hunger of the nurse ant */
species F; 		                /* Forager  : F[i] hunger of the forager ant */
species D;                    /* A useless agents (used only to check the percentage operator effects with N and F on the rules) */

/* ======================================= */
/*                  LABELS                 */
/* ======================================= */
label nurses = { N }
label foragers = { F }
label workers = { N, F }

rule new_nurse for f in [0, FOOD_STORAGE] {
  Q[f] -[ 0.1 ]-> Q[f]|N<10>
}

/* Change of work rules */
rule nurse_becomes_forager for f in [0, FOOD_STORAGE] {
  Q[f]|N -[ #nurses * (1 - (f/2) / (FOOD_STORAGE-1)) * (#nurses / #workers) ]-> Q[f]|F
}
rule forager_becomes_nurse for f in [0, FOOD_STORAGE] {
  Q[f]|F -[ #foragers * ((f / (FOOD_STORAGE-1)) / 2) * (#foragers / #workers) ]-> Q[f]|N
}

measure n_queen = #Q[j for j in [0,FOOD_STORAGE]];
measure n_nurse = #nurses;
measure n_forager = #foragers;
measure n_workers = #workers;
measure p_nurse = %nurses;
measure p_forager = %foragers;
measure p_workers = 1 / (1 + #nurses + #foragers);

/* Balanced system with a lot of food; Expectation: 10 Foragers, 10 Nurses */
system balancedFoodH = Q[9]<1>
                        |N<10>
                        |F<10>
                        |D<100>;

/* Balanced system with a little food; Expectation: 5 Nurses, 15 Foragers */
system balancedFoodL = Q[1]<1>
                        |N<10>
                        |F<10>
                        |D<100>;

/* Balanced system with half food; Expectation: 7 Nurses, 13 Foragers */
system balancedFoodM = Q[5]<1>
                        |N<10>
                        |F<10>
                        |D<100>;

/* Unbalanced system with a lot of food;  Expectation: 10 Foragers, 10 Nurses */
system unbalancedFoodH = Q[9]<1>
                          |N<5>
                          |F<15>
                          |D<100>;

/* Unbalanced system with a little food; Expectation: 5 Nurses, 15 Foragers */
system unbalancedFoodL = Q[1]<1>
                          |N<5>
                          |F<15>
                          |D<100>;

/* Unbalanced system with half food; Expectation: 7 Nurses, 13 Foragers */
system unbalancedFoodM = Q[5]<1>
                          |N<5>
                          |F<15>
                          |D<100>;