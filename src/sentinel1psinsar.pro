PRO Sentinel1PSInSAR

  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2

  ; execute ENVI
  e = ENVI(/HEADLESS)

  ; get Sentinel-1 GRD file and output directory
  s1zip = DIALOG_PICKFILE(/MULTIPLE_FILES, TITLE = 'Select Sentinel-1 zip file', FILTER = 'S1*.zip')
  s1aoi = DIALOG_PICKFILE(TITLE = 'Select AoI shapefile', FILTER = '*.shp')
  outDIR = DIALOG_PICKFILE(/DIRECTORY,TITLE = 'Select output directory')

  ; set up
  task_0 = ENVITASK('SARscape_setting_output_folder')
  task_0.output_folder = outDIR
  task_0.Execute

  ; import Sentinel-1
  task_1 = ENVITASK('SARsImportSentinel1Format')
  task_1.input_file_list = s1zip
  IF FILE_TEST(s1aoi) THEN task_1.input_roi_file = s1aoi
  task_1.generate_iw_ew_power = !TRUE
  task_1.cross_copolarization = 'ONLY_VV_POL'
  task_1.make_slc_list_mosaic = !TRUE
  task_1.remove_noise_from_lut = !TRUE
  task_1.skip_sample = !FALSE
  task_1.rename_the_file_using_parameters = !TRUE
  task_1.generate_ql = !FALSE
  task_1.root_uri_for_output = task_0.root_uri_for_output
  task_1.Execute

  ; get SRTM 3 arc-sec DEM
  task_2 = ENVITask('SARsToolsDEMExtractionSRTM4')
  task_2.reference_sarscapedata = task_1.output_sarscapedata
  task_2.grid_size_x_val = 90.0
  task_2.grid_size_y_val = 90.0
  task_2.replace_dummy_with_min_val = !TRUE
  task_2.output_cartographic_system =  ["GEO-GLOBAL","","GEO","","WGS84","","0.0000000"]
  task_2.root_uri_for_output = task_0.root_uri_for_output
  task_2.Execute

  ; PS-InSAR step 1. generate connection graph
  task_3 = ENVITASK('SARsInSARConnectionGraphPS')
  task_3.input_sarscapedata = task_1.output_sarscapedata
  task_3.max_baseline_th = 5.0 ; Sentinel-1 critical baseline : 5km ==> max basline : 250m
  task_3.generate_ql = !FALSE
  task_3.root_uri_for_output = task_0.root_uri_for_output
  task_3.execute

  ; PS-InSAR step 2. generate interferogram
  task_4 = ENVITASK('SARsInSARStackPSInterferogramGeneration')
  task_4.auxiliary_file_name = task_3.auxiliary_processing_info_file
  task_4.dem_sarscapedata = task_2.output_sarscapedata
  task_4.multilooking_diff_interf = !FALSE
  task_4.rebuild_all = !TRUE
  task_4.cc_range_win_number_cc = 8.0
  task_4.cc_azimuth_win_number_cc = 2.0
  task_4.coregistration_with_dem = !TRUE
  task_4.output_cartographic_system = ["GEO-GLOBAL","","GEO","","WGS84","","0.0000000"]
  task_4.generate_ql = !FALSE
  task_4.root_uri_for_output = task_0.root_uri_for_output
  task_4.Execute

  ; PS-InSAR step 3. apply first inversion
  task_5 = ENVITASK('SARsInSARStackPSInversionStep1')
  task_5.auxiliary_file_name = task_4.auxiliary_processing_info_file
  task_5.velocity_step = 1.0
  task_5.minimum_velocity = -25.0
  task_5.maximum_velocity = 25.0
  task_5.height_step = 2.0
  task_5.minimum_height = -70.0
  task_5.maximum_height = 70.0
  task_5.ps_atmospheric_area_km = 25.0
  task_5.perc_area_overlap = 30.0
  task_5.nbr_of_candidates = 5.0
  task_5.rebuild_all = !TRUE
  task_5.generate_ql = !FALSE
  task_5.root_uri_for_output = task_0.root_uri_for_output
  task_5.Execute

  ; PS-InSAR step 4. apply second inversion
  task_6 = ENVITASK('SARsInSARStackPSInversionStep2')
  task_6.auxiliary_file_name = task_5.auxiliary_processing_info_file
  task_6.atmosphere_hp_days = 365.0
  task_6.atmosphere_lp_meters = 1200.0
  task_6.rebuild_all = !TRUE
  task_6.generate_ql = !FALSE
  task_6.root_uri_for_output = task_0.root_uri_for_output
  task_6.Execute

  ; PS-InSAR step 5. apply geocoding
  task_7 = ENVITASK('SARsInSARStackPSGeocode')
  task_7.auxiliary_file_name = task_6.auxiliary_processing_info_file
  task_7.dem_sarscapedata = task_2.output_sarscapedata
  task_7.ps_coherence_threshold = 0.59999999999999996
  task_7.ps_generate_kml = !FALSE
  task_7.make_geocoded_shape = !TRUE
  task_7.ps_max_points_in_shape = 10000000.0
  task_7.make_geocoded_raster = !TRUE
  task_7.make_slant_ps_shape = !FALSE
  task_7.force_rebuild_all = !TRUE
  task_7.refinement_stacking = 'StackAllProductsRefinement'
  task_7.radius = 20.0
  task_7.refinement_res_phase_poly_degree = '3'
  task_7.generate_vertical = !TRUE
  task_7.generate_max_slope = !FALSE
  task_7.generate_user_custom = !FALSE
  task_7.geocode_rg_grid_size = 20.0
  task_7.geocode_az_grid_size = 20.0
  task_7.output_cartographic_system = ["GEO-GLOBAL","","GEO","","WGS84","","0.0000000"]
  task_7.generate_ql = !FALSE
  task_7.root_uri_for_output = task_0.root_uri_for_output
  task_7.Execute

  ; terminate ENVI
  e.Close

END