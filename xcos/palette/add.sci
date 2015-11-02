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

function [x, y, typ] = add(job, arg1, arg2)
  x = []; y = []; typ = [];
  blk_version = 0.3; //store with object to allow for changes in parameters
  select job
    case 'set' then
      x = arg1;
      graphics = arg1.graphics;
      model = arg1.model;
      exprs = graphics.exprs;
      parameters = model.opar(1);
      settings = parameters.settings;
      latency = settings.latency;
      while %t do
        [ok, label, latency]=scicos_getvalue("adder settings",..
                 ["label"; "latency"], list('str', -1, 'intvec', 1), [exprs(1), msprintf("%i", latency)]);
        if ~ok then
          break
        end
      
        ok = %f;
        //check range
        if (latency < 0) then
          block_parameter_error("incorrect range for ''latency'' setting", "value must be >= 0");
        else
          ok = %t;
          break;
        end //if chain
      end //while

      if ok then
        settings.latency = latency;
        parameters.settings = settings; 
        model.opar(1) = parameters; 
        x.model = model;

        exprs(1) = label;
        graphics.exprs = exprs;
        x.graphics = graphics;
      end

    case 'define' then
      model = scicos_model();
      model.blocktype = 'f';
      model.outtyp = [6];
      model.out = 1;
      outinfo = struct('sign', [], 'nbits', [], 'binpt', [], 'calc', 'add');
      model.intyp = [-1; -1]; //determine input info from source
      model.in = [1; 1];
      ininfo = struct('sign', [-1, -1], 'nbits', [-1, -1], 'binpt', [-1, -1]);
      settings = struct('latency', 0);
      parameters = struct(...
        'version', blk_version, ...
        'settings', settings, ...
        'in', ininfo, ...
        'out', outinfo);
      model.opar = list(parameters);
      x = ratel_block_gen([2 2], model, [''], ['a';'b'], ['a+b']);
  end //select
endfunction
