PRO Sentinel1SBAS

  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2

  ; execute ENVI
  e = ENVI(/HEADLESS)

  ; get Sentinel-1 GRD file and output directory
  s1zip = DIALOG_PICKFILE(/MULTIPLE_FILES, TITLE = 'Select Sentinel-1 zip file', FILTER = 'S1*.zip')
  s1aoi = DIALOG_PICKFILE(TITLE = 'Select AoI shapefile', FILTER = '*.shp')
  outDIR = DIALOG_PICKFILE(/DIRECTORY,TITLE = 'Select output directory')

  ; set up
  task_0 = ENVITask('SARscape_setting_output_folder')
  task_0.output_folder = outDIR
  task_0.Execute

  ; import Sentinel-1
  task_1 = ENVITask('SARsImportSentinel1Format')
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

  ; ===========================
  ; SBAS-InSAR procedure
  ; ===========================
  ; step 01. get connection Graph
  task_3 = ENVITask('SARsInSARStackSBASGenerateConnectionGraph')
  task_3.input_sarscapedata = task_1.output_sarscapedata
  task_3.degree_of_redundancy = 'low'
  task_3.redundancy_criterium = 'min_normal'
  task_3.root_uri_for_output = task_0.root_uri_for_output
  task_3.Execute

  ; step 02. apply interferogram generation and unwrapping
  task_4 = ENVITask('SARsInSARStackSBASInterferogramGeneration')
  task_4.auxiliary_file_name = task_3.auxiliary_processing_info_file
  task_4.dem_sarscapedata = task_2.output_sarscapedata
  task_4.rg_looks_nbr = 8.0
  task_4.az_looks_nbr = 2.0
  task_4.layover_shadow_mask = !FALSE
  task_4.coregistration_with_dem = !TRUE
  task_4.upha_method_type = 'MCF_DELAUNAY'
  task_4.filtering_method = 'ADAPTIVE_NON_LOCAL_INSAR'
  task_4.output_cartographic_system = ["GEO-GLOBAL","","GEO","","WGS84","","0.0000000"]
  task_4.root_uri_for_output = task_0.root_uri_for_output
  task_4.Execute

  ; step 03. apply first inversion
  task_5 = ENVITask('SARsInSARStackSBASInversionStep1')
  task_5.auxiliary_file_name = task_4.auxiliary_processing_info_file
  task_5.product_coherence_threshold = 0.20000000000000001
  task_5.displacement_model_type = 'linear'
  task_5.disconnected_blocks_type = 'False'
  task_5.upha_method_type = 'MCF_DELAUNAY'
  task_5.radius = 20.0
  task_5.refinement_res_phase_poly_degree = '3'
  task_5.root_uri_for_output = task_0.root_uri_for_output
  task_5.Execute

  ; step 04. apply second inversion
  task_6 = ENVITask('SARsInSARStackSBASInversionStep2')
  task_6.auxiliary_file_name = task_5.auxiliary_processing_info_file
  task_6.product_coherence_threshold = 0.20000000000000001
  task_6.disconnected_blocks_type = 'NotOK'
  task_6.radius = 20.0
  task_6.refinement_res_phase_poly_degree = '3'
  task_6.root_uri_for_output = task_0.root_uri_for_output
  task_6.Execute

  ; step 05. apply geocoding
  task_7 = ENVITask('SARsInSARStackSBASGeocode')
  task_7.auxiliary_file_name = task_6.auxiliary_processing_info_file
  task_7.dem_sarscapedata = task_2.output_sarscapedata
  task_7.generate_raster = !TRUE
  task_7.generate_shape = !TRUE
  task_7.max_point_in_shape = 100000000.0
  task_7.shape_time_series = !TRUE
  task_7.generate_vertical = !TRUE
  task_7.generate_max_slope = !FALSE
  task_7.generate_user_custom = !FALSE
  task_7.geocode_mean_box_size = 20.0
  task_7.geocode_interpol_box_size = 20.0
  task_7.radius = 20.0
  task_7.refinement_res_phase_poly_degree = '3'
  task_7.output_cartographic_system = ["GEO-GLOBAL","","GEO","","WGS84","","0.0000000"]
  task_7.root_uri_for_output = task_0.root_uri_for_output
  task_7.Execute

  ; terminate ENVI
  e.Close

END