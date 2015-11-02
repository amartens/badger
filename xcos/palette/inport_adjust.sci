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

function [x] = inport_adjust(job, arg1)
  x = []
  fname = 'inport_adjust';
  select job
    case 'fp' then
      ratel_log('calculating ''inport'' output fixed point info\n', [fname])
      fpm = arg1
      fpm.outsign = fpm.ipar(1); fpm.outnbits = fpm.ipar(2); fpm.outbinpt = fpm.ipar(3)
      x = fpm
    case 'hdl' then
      //in this case arg1 is a Block
      ratel_log('adjusting graphics info for ''inport'' hdl generation\n', [fname]);
      obj = arg1
      obj.graphics.out_label = ''
      x = obj
  end //select
endfunction
