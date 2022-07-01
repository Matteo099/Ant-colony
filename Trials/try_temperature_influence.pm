const ENERGY = 10;
const IDEAL_TEMPERATURE = 29;
const AVARAGE_TEMPERATURE = 10;
const e = 2.718281;

/* t = 29,                    tInfluence = 0 */
/* t = 20.097 or t = 38.429,  tInfluence ~ 0.25 */
/* t = 0 or t = 60,           tInfluence ~ 0.5 */
param temperature = 29; 

const baseConsumeEnergyRate = 0.25;
const consumeEnergyMultiplier = 2;
const temperatureInfluence = (1 - (e ^ -((temperature - IDEAL_TEMPERATURE) ^ 2 / (temperature/IDEAL_TEMPERATURE + AVARAGE_TEMPERATURE) ^ 2))) / 2;

species A of [0, ENERGY]; 	/* Ant : Q[i] is the ant with i energy (0 = full of energy, 10 = no energy) */

rule ant_consume_energy for i in [0, ENERGY-1] {
  A[i] -[ baseConsumeEnergyRate * consumeEnergyMultiplier + temperatureInfluence ]-> A[i+1]
}

measure n_ant = #A[i for i in [0,ENERGY]];

system initial = A[0]<10>;