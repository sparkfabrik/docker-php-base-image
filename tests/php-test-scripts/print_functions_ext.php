<?php

$exts = [];

foreach (get_loaded_extensions() as $ext) {
  $ext_funcs = [];
  $funcs = get_extension_funcs($ext);
  if ($funcs && count($funcs) > 0) {
    foreach($funcs as $func) {
      $ext_funcs[] = $func;
    }
  }
  $exts[$ext] = $ext_funcs;
}

echo json_encode($exts, JSON_PRETTY_PRINT);
