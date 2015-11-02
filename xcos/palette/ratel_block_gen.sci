//This file is part of ratel.
//
//    ratel is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    ratel is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with ratel.  If not, see <http://www.gnu.org/licenses/>.

function o=ratel_block_gen(sz, model, exprs, in_labels, out_labels)
//initialize graphic part of the block data structure

  gr_i = [];

  nin = size(model.in,1);
  if nin > 0, pin(nin,1) = 0, else pin = [], end

  nout = size(model.out,1);
  if nout > 0, pout(nout,1) = 0, else pout = [], end

  ncin = size(model.evtin,1);
  if ncin > 0, pein(ncin,1) = 0, else pein = [], end

  ncout = size(model.evtout,1);
  if ncout > 0, peout(ncout,1) = 0, else peout = [], end
  
  if type(gr_i) <> 15, gr_i = list(gr_i,8), end
  if gr_i(2) == [], gr_i(2) = 8, end
  if gr_i(2) == 0, gr_i(2) = [], end
  
  model.blocktype = 'd';

  graphics = scicos_graphics();
  graphics.exprs = exprs;
  graphics.sz = sz;
  graphics.pin = pin;
  graphics.pout = pout;
  graphics.pein = pein;
  graphics.peout = peout;
  graphics.gr_i = gr_i;
  graphics.in_label = in_labels;
  graphics.out_label = out_labels;
  [r,c] = size(in_labels);
  graphics.in_implicit = repmat(['E'], r*c, 1); //make size implicit to fool delete_unconnected  
  
  [ln,mc] = where()
  o = scicos_block(graphics = graphics,model = model,gui = mc(2))
endfunction

