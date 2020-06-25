# plan.R
plan_bestfitlayerkl <- drake::drake_plan(
  # Data input
  bestfitlayerkl_dbs = target({
    list.files(path_sims3, pattern = "*.db$", full.names = TRUE)[1:18]
    },
    format = "file"
  ),
  bestfitlayerkls_pred_SW = target(
    read_dbtab(path = bestfitlayerkl_dbs, table = "Report"),
    dynamic = map(bestfitlayerkl_dbs)
  ),
  bestfitlayerkls_obs_SW = target(
    autoapsimx::subset_obs(DT = drake::readd(SW_mean), 
                           treatment1 = sites ,
                           treatment2 = sds),
    transform = cross(sites = c("AshleyDene", "Iversen12"),
                      sds = c("SD1",  "SD2", "SD3",  "SD4",  "SD5",
                              "SD6",  "SD7",  "SD8",  "SD9",  "SD10"))
  ),
  
  pred_SW = target(
    data.table::melt(bestfitlayerkls_pred_SW,
                     value.name = "pred_VWC",
                     measure.vars = readd(value_vars),
                     variable.name = "Depth",
                     variable.factor = FALSE),
    dynamic = map(bestfitlayerkls_pred_SW)
  ),
  long = target(
    data.table::melt(bestfitlayerkls_obs_SW,
                     value.name = "obs_VWC",
                     measure.vars = readd(value_vars),
                     variable.name = "Depth",
                     variable.factor = FALSE),
    transform =  map(bestfitlayerkls_obs_SW)
  ),
  # Joining the prediction and observation for Soil water in each layer
  pred_obs_sw = target(
    merge.data.table(pred_SW[,(c("CheckpointID", "Experiment", "FolderName","Zone")) := NULL],
                     long,
                     by.x = c("Date", "Depth"),
                     by.y = c("Clock.Today", "Depth"))[, Depth := forcats::fct_relevel(as.factor(Depth), paste0("SW(",1:22, ")"))],
    transform = map(pred_SW, long)
  ),
  plot_SW = target(
    plot_params(DT = pred_obs_sw,
                col_pred = "pred_VWC", col_obs = "obs_VWC",
                Depth = "Depth",stats = FALSE, 
                height = 16, width = 9,
                title = file_out(!!paste0(path_layerkl,"/",.id_chr)),format = "png"),
    transform = map(pred_obs_sw),
    trigger = trigger(condition = TRUE, mode = "blacklist")
  ),
  bestfitlayerkls_obs_SWC = target(
    autoapsimx::subset_obs(DT = drake::readd(SWC_mean), 
                           treatment1 = sites ,
                           treatment2 = sds),
    transform = cross(sites = c("AshleyDene", "Iversen12"),
                      sds = c("SD1",  "SD2", "SD3",  "SD4",  "SD5",
                              "SD6",  "SD7",  "SD8",  "SD9",  "SD10"))
  ),
  
  pred_obs_swc = target(
    merge.data.table(bestfitlayerkls_pred_SW,
                     bestfitlayerkls_obs_SWC,
                     by.x = c("Date"),
                     by.y = c("Clock.Today")),
    transform = map(bestfitlayerkls_pred_SW, bestfitlayerkls_obs_SWC)
  ),
  plot_SWC = target(
    plot_params(DT = pred_obs_swc, stats = FALSE, group_params = "SKL",
                title = file_out(!!paste0(path_layerkl,"/",.id_chr)),format = "png"),
    transform = map(pred_obs_swc),
    trigger = trigger(condition = TRUE, mode = "blacklist")
  )

  
)
