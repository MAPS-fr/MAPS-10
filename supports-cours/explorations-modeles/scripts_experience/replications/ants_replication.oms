// Define the input variables
val gPopulation = Val[Double]
val gDiffusionRate = Val[Double]
val gEvaporationRate = Val[Double]
val seed = Val[Int]

val i = Val[Double]

//val resPath = "/iscpif/users/rey/ANTS/RESULTS/"

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

// Slot ? 

val medFood1 = Val[Double]
val medFood2 = Val[Double]
val medFood3 = Val[Double]

val medians = 
  Slot(ScalaTask("""
    import math.abs
  
    val medFood1 = food1.median
    val medFood2 = food2.median
    val medFood3 = food3.median""") set (
    name := "medians",
    inputs += (food1.array, food2.array, food3.array),
    outputs += (medFood1, medFood2, medFood3)
  ))


// series of replications
val exploration = Capsule(
    ExplorationTask(i in (0.0 to 100.0 by 1.0)) set (
        name := "Series of replications",
        gPopulation := 125.0,
        gDiffusionRate:= 25.0,
        gEvaporationRate := 25.0,
        outputs += (gPopulation,gDiffusionRate,gEvaporationRate))
    )

//val env = LocalEnvironment(5)
val env = EGIEnvironment("vo.complex-systems.eu")


// replications
val replication = Capsule(ExplorationTask(seed in (UniformDistribution[Int]() take 50)), strain = true)

// Define the hooks to collect the results
//val displayMedians = ToStringHook(medFood1, medFood2, medFood3)
val saveHook = AppendToCSVFileHook(workDirectory / "/results/replication/ants_100s_50r.csv", i, gPopulation, gDiffusionRate, gEvaporationRate, medFood1, medFood2, medFood3)

// Execute the workflow
 exploration -< Strain(replication  -< (ants on env by 50) >- medians) hook saveHook
