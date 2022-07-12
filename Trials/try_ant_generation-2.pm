const eggs = 100;

species Q; 	  /* Queen */
species I; 		/* Immature or Larve ant */
species A; 	  /* Adult Ant */
species D; 	  /* Death Ant */

rule createLarve {
  Q -[ 0.1 ]-> Q|I<eggs>
}

rule larve_grow {
  I -[ 0.2 ]-> A
}

rule larve_die {
  I -[ 0.3 ]-> D
}
rule adult_die {
  A -[ 0.1 ]-> D
}

measure n_queen = #Q;
measure n_larve = #I;
measure n_adult = #A;
measure n_death = #D;

system balanced = Q<1>|I<0>|A<0>|D<0>;