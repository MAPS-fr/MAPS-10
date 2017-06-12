// Define the input variables
val gPopulation = Val[Double]
val gDiffusionRate = Val[Double]
val gEvaporationRate = Val[Double]
val seed = Val[Int]

// Define the output variables
val food1 = Val[Double]
val food2 = Val[Double]
val food3 = Val[Double]

// Define the NetlogoTask
val cmds = Seq("random-seed ${seed}", "run-to-grid")

val ants =
  NetLogo5Task(workDirectory / "ants.nlogo", cmds) set (
    // Map the OpenMOLE variables to NetLogo variables
    netLogoInputs += (gPopulation, "gpopulation"),
    netLogoInputs += (gDiffusionRate, "gdiffusion-rate"),
    netLogoInputs += (gEvaporationRate, "gevaporation-rate"),
    netLogoOutputs += ("final-ticks-food1", food1),
    netLogoOutputs += ("final-ticks-food2", food2),
    netLogoOutputs += ("final-ticks-food3", food3),
    // The seed is used to control the initialisation of the random number generator of NetLogo
    inputs += seed,
    outputs += seed
  )
  

val nsga2 =
  NSGA2(
    mu = 200,
    genome = Seq(gPopulation in (25.0, 250.0), gDiffusionRate in (0.0, 99.0), gEvaporationRate in (0.0, 99.0)),
    objectives = Seq(food1, food2, food3),
    replication = Replication(seed = seed, aggregation = Seq(median, median, median), max = 100)
  )


// parallelism = offspring
// 
val evolution =
  SteadyStateEvolution(
    algorithm = nsga2,
    evaluation = ants,
    parallelism = 500,
    termination = 2000
  )

//val env = LocalEnvironment(5)
val env = EGIEnvironment("vo.complex-systems.eu")

// Define a hook to save the Pareto frontier
val savePopulationHook = SavePopulationHook(evolution, workDirectory / "/results/calibration/")

// Plug everything together to create the workflow
(evolution on env by 20 hook savePopulationHook)