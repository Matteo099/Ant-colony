const M = 10;

species Q of [0, M]; 	/* Queen : Q[i] queen with i eggs */
species I; 		/* Immature or Larve ant */

rule createLarve for i in [1, M]{
  Q[i] -[ 1.0 ]-> Q[i-1]|I
}

measure n_queen = #Q[i for i in [0,M]];
measure n_larve = #I;

system balanced = Q[M-1]<1>|I<10>;