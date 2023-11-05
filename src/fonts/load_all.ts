// Copyright (c) 2023-present VexFlow contributors: https://github.com/vexflow/vexflow/graphs/contributors
// MIT License
//
// vexflow.js statically bundles & preloads all of our music engraving fonts.

import { loadBravura } from './load_bravura';
import { loadCustom } from './load_custom';
import { loadFinaleAsh } from './load_finaleash';
import { loadFinaleBroadway } from './load_finalebroadway';
import { loadFinaleMaestro } from './load_finalemaestro';
import { loadGonville } from './load_gonville';
import { loadGootville } from './load_gootville';
import { loadLeland } from './load_leland';
import { loadMuseJazz } from './load_musejazz';
import { loadPetaluma } from './load_petaluma';
// ADD_MUSIC_FONT
// import { loadXXX } from './load_xxx';

// Populate our font "database" with all our music fonts.
export function loadAllMusicFonts(): void {
  loadBravura();
  loadFinaleAsh();
  loadFinaleBroadway();
  loadFinaleMaestro();
  loadGonville();
  loadGootville();
  loadPetaluma();
  loadCustom();
  loadLeland();
  loadMuseJazz();
  // ADD_MUSIC_FONT
  // loadXXX();
}
