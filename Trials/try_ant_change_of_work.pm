const ENERGY = 10;
const FOOD_STORAGE = 10;

species Q of [0, ENERGY]*[0, FOOD_STORAGE]; 	/* Queen    : Q[i, j] queen with hungry level i, and j is the food storage */
species N of [0, ENERGY]; 		                /* Nurse    : N[i] hunger of the nurse ant */
species F of [0, ENERGY]; 		                /* Forager  : F[i] hunger of the forager ant */
species D;

/* ======================================= */
/*                  LABELS                 */
/* ======================================= */
label nurses = { N[i for i in [0,ENERGY]] }
label foragers = { F[i for i in [0,ENERGY]] }

/* Change of work rules */
rule nurse_becomes_forager for i in [0, ENERGY/2] and j in [0, ENERGY] and f in [0, FOOD_STORAGE] {
  /* #nurses * (1 - f / FOOD_STORAGE) * (1 - %foragers) */
  Q[j,f]|N[i] -[ #nurses * (1 - f / FOOD_STORAGE) * (1 - %foragers) ]-> Q[j,f]|F[i]
}
rule forager_becomes_nurse for i in [0, ENERGY/2] and j in [0, ENERGY] and f in [0, FOOD_STORAGE] {
  /* #foragers * (f / FOOD_STORAGE) * (1 - %nurses) */
  Q[j,f]|F[i] -[ #foragers * (f / FOOD_STORAGE) * (1 - %nurses) ]-> Q[j,f]|N[i]
}


measure n_queen = #Q[i, j for i in [0,ENERGY] and j in [0,FOOD_STORAGE]];
measure n_nurse = #nurses;
measure n_forager = #foragers;
measure p_nurse = %nurses;
measure p_forager = %foragers;


system balanced = Q[0, 9]<1>
                    |N[0]<10>
                    |F[0]<10>;

system unbalanced = Q[0, 2]<1>
                    |N[0]<15>
                    |F[0]<5>
                    |D<100>;

system balancedDifferentEnergy = Q[0, 9]<1>
                    |N[0]<2>|N[2]<2>|N[4]<2>|N[6]<2>|N[8]<2>
                    |F[0]<2>|F[2]<2>|F[4]<2>|F[6]<2>|F[8]<2>;