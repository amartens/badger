function [x, y, typ] = add(job, arg1, arg2)
  x= []; y = []; typ = [];
  blk_version = 0.1; //store with object to allow for changes in parameters
  select job
    case 'set' then
      x=arg1;
      graphics=arg1.graphics;
      model=arg1.model;
      exprs=graphics.exprs;
      settings = model.opar(4);
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
        model.opar(4) = settings; 
        x.model=model;

        exprs(1) = label;
        graphics.exprs = exprs
        x.graphics = graphics;
      end
 
    case 'define' then
      model = scicos_model();
      model.blocktype = 'c';
      model.out = 1;
      model.outtyp = [1];
      model.in = [1; 1];
      model.intyp = [1; 1];
      settings = struct('latency', 0);
      model.opar = list('version', blk_version, 'settings', settings);
      x = badger_block_gen([2 2], model, [''], ['a';'b'], ['a+b'])
    end
endfunction
