const ENERGY = 4;
const queenDeathRate = 0.01;

species Q of [0, ENERGY]; 	  /* Queen (Q[i] is the hungry/energy level) */
species L; 		                /* Larvae */
species N; 		                /* Nurses */
species DA; 		              /* Death ants */

label workers = { L, N }

rule reproduction for i in [0, ENERGY/2]{
  Q[i] -[ 0.5 ]-> Q[i+1]|L<5>
}

rule queen_consume_energy for i in [0, ENERGY-1] {
  Q[i] -[ 0.5 ]-> Q[i+1] 
}

rule queen_dies { /* for i in [ENERGY / 4 * 3, ENERGY] */
  Q[ENERGY-1] -[ queenDeathRate * %Q[ENERGY-1] ]-> DA
}

measure n_queen = #Q[i for i in [0,ENERGY]];
measure n_larve = #L;
measure n_nurses = #N;
measure n_deaths = #DA;

/* around 30 steps, the queen dies */
system configA = Q[0]<1>|N<10>|L<10>;

/* around 75 steps, the queen dies */
system configB = Q[0]<1>|N<100>|L<100>;