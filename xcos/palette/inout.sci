function [x, y, typ] = inout(job, arg1, arg2)
//a helper block inserted to ease creation of verilog ports
  x = []; y = []; typ = [];
  version = 0.1;
  select job
    case 'define' then
      port_type = arg1; //0 = output, 1 = input

      model = scicos_model();

      model.in = 1;      
      model.intyp = [-2]; //figure out type from what it is connected to
      ininfo = struct('sign', [-2], 'nbits', [-2], 'binpt', [-2]);

      model.out = 1;     
      model.outtyp = [-2];//and propagate this all the way through
      outinfo = struct('sign', [-2], 'nbits', [-2], 'binpt', [-2], 'calc', []);

      settings = struct('type', port_type);
 
      parameters = struct('version', version, 'settings', settings, 'in', ininfo, 'out', outinfo)
      
      //this must be a list, not a struct apparently
      model.opar = list(parameters);
      model.ipar = 0; //0 = input, 1 = output

      //create scicos block with standard settings  
      //TODO input and output labels 
      x = ratel_block_gen([2 1], model, [""], [], []);
  end
endfunction
