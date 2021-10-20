<?php

foreach ($_SERVER as $k => $v) {
  if (!is_string($v)) {
    $v = print_r($v, true);
  }
  echo "${k} => ${v}\n";
}
