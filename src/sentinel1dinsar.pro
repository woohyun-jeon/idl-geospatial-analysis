PRO Sentinel1DInSAR

  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2

  ; execute ENVI
  e = ENVI(/HEADLESS)

  ; get Sentinel-1 SLC files and output directory
  s1files = DIALOG_PICKFILE(/MULTIPLE_FILES, TITLE = 'Select Sentinel-1 master and slave file', FILTER = 'S1*.zip')
  s1aoi = DIALOG_PICKFILE(TITLE = 'Select AoI shapefile', FILTER = '*.shp')
  outDIR = DIALOG_PICKFILE(/DIRECTORY,TITLE = 'Select output directory')

  ; set up
  task_0 = ENVITASK('SARscape_setting_output_folder')
  task_0.output_folder = outDIR
  task_0.Execute

  ; open Sentinel-1
  task_1 = ENVITask('SARsImportSentinel1Format')
  task_1.input_file_list = s1files
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
  task_2.slope_flag_val = !FALSE
  task_2.replace_dummy_with_min_val = !FALSE
  task_2.output_cartographic_system = ["GEO-GLOBAL","","GEO","","WGS84","","0.0000000"]
  task_2.generate_ql = !FALSE
  task_2.root_uri_for_output = task_0.root_uri_for_output
  task_2.Execute

  ; search Sentinel-1 files
  slcfiles = FILE_SEARCH(outDIR + PATH_SEP() + '*_slc_list_pwr')

  ; generate interferogram
  task_3 = ENVITask('SARsInSARInterferogramGeneration')
  task_3.reference_sarscapedata = slcfiles[0]
  task_3.secondary_sarscapedata = slcfiles[1]
  task_3.dem_sarscapedata = task_2.output_sarscapedata
  task_3.rg_looks_nbr = 8.0
  task_3.az_looks_nbr = 2.0
  task_3.coreg_slc_too = !TRUE
  task_3.coregistration_with_dem = !TRUE
  task_3.output_cartographic_system = ["GEO-GLOBAL","","GEO","","WGS84","","0.0000000"]
  task_3.generate_ql = !FALSE
  task_3.root_uri_for_output = task_0.root_uri_for_output
  task_3.Execute

  ; apply adaptive filter and generate coherence
  task_4 = ENVITask('SARsInSARFilterAndCoherence')
  task_4.dint_sarscapedata = task_3.dint_sarscapedata
  task_4.reference_sarscapedata = task_3.reference_power_sarscapedata
  task_4.secondary_sarscapedata = task_3.secondary_power_sarscapedata
  task_4.coherence = !TRUE
  task_4.interf_filt = !TRUE
  task_4.filtering_method = 'ADAPTIVE_NON_LOCAL_INSAR'
  task_4.coherence_from_fint = !TRUE
  task_4.generate_ql = !FALSE
  task_4.root_uri_for_output = task_0.root_uri_for_output
  task_4.Execute

  ; apply phase unwrapping
  task_5 = ENVITask('SARsInSARPhaseUnwrapping')
  task_5.coherencefile_name = task_4.coherence_sarscapedata
  task_5.infile_name = task_4.fint_sarscapedata
  task_5.upha_method_type = 'MCF_DELAUNAY'
  task_5.upha_coh_threshold = 0.20000000000000001
  task_5.generate_ql = !FALSE
  task_5.root_uri_for_output = task_0.root_uri_for_output
  task_5.Execute

  ; convert phase to displacement and apply geocoding
  task_6 = ENVITask('SARsInSARPhaseToDisplacement')
  task_6.input_sarscapedata = task_5.outfile_name
  task_6.cohernce_sarscapedata = task_4.coherence_sarscapedata
  task_6.dem_sarscapedata = task_2.output_sarscapedata
  task_6.coherence_threshold = 0.20000000000000001
  task_6.allow_skip_refinement = !TRUE
  task_6.generate_vertical = !TRUE
  task_6.generate_max_slope = !FALSE
  task_6.generate_user_custom = !FALSE
  task_6.geocode_rg_grid_size = 20.0
  task_6.geocode_az_grid_size = 20.0
  task_6.geocode_dummy_removal = !FALSE
  task_6.output_cartographic_system = ["GEO-GLOBAL","","GEO","","WGS84","","0.0000000"]
  task_6.root_uri_for_output = task_0.root_uri_for_output
  task_6.Execute

  ; terminate ENVI
  e.Close

END