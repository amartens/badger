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

function [x] = add_adjust(job, arg1)
  fname = 'add_adjust';
  x = [];
  select job
    case 'fp' then
      ratel_log('calculating output data info\n', [fname]);
      x = arg1;
      intype = x.intyp; insign = ininfo.sign; 
      innbits = ininfo.nbits; inbinpt = ininfo.binpt;
      //if any input is signed, make output signed 
      if find(insign > 0) then parameters.out.sign = 1; end
      //if all inputs have the number of bits defined, output bits are 1 plus the max
      if isempty(find(innbits < 0)) then parameters.out.nbits = 1+max(innbits); end
      //if all decimal point positions are defined, output can be calculated as max
      if isempty(find(inbinpt < 0)) then parameters.out.binpt = max(inbinpt); end
      x.opar(1) = parameters;
  end
endfunction 
