function [x, y, typ] = inport(job, arg1, arg2)
  x = []; y = []; typ = [];
  version = 0.3;
  select job
    case 'set' then
      x=arg1;
      graphics=arg1.graphics;
      model=arg1.model;
      exprs=graphics.exprs;
      parameters=model.opar(1);
      settings = parameters.settings;
      outinfo=parameters.out;
      outsign = outinfo.sign;
      outnbits = outinfo.nbits;
      outbinpt = outinfo.binpt;

      labels = [ ..
        "label"; ..
        "sign (0=Unsigned, 1=Signed)"; ..
        "number of bits"; ..
        "binary point position"; ..
        "overflow strategy (0=Wrap, 1=Saturate)"; ..
        "quantization strategy (0=Truncate, 1=Round)"];
      types = list('str', -1, 'intvec', 1, 'intvec', 1, 'intvec', 1, 'intvec', 1, 'intvec', 1);
      ini = [..
        exprs(1); ..
        msprintf("%i", outsign); ..
        msprintf("%i", outnbits); ..        
        msprintf("%i", outbinpt); ..
        msprintf("%i", settings.overflow); ..        
        msprintf("%i", settings.quantization)];    
      
      while %t do     
        [ok, label, sgn, nbits, binpt, overflow, quantization] = scicos_getvalue( ..
          "inport settings", labels, types, ini); 
        if ~ok then
          break
        end
        
        ok = %f;
        //check range
        if (sgn < 0) | (sgn > 1) then
          block_parameter_error("incorrect range for ''sign'' setting", "value must be in range [0:1]");
        elseif (nbits < 1) then
          block_parameter_error("incorrect range for ''number of bits'' setting", "value must be > 0");
        elseif (binpt < 0) then
          block_parameter_error("incorrect range for ''binary point position'' setting", "value must be >= 0");
        elseif (overflow < 0) | (overflow > 1) then
          block_parameter_error("incorrect range for ''overflow strategy'' setting", "value must be in range [0:1]");
        elseif (quantization < 0) | (quantization > 1) then
          block_parameter_error("incorrect range for ''quantization strategy'' setting", "value must be in range [0:1]");
        else 
          ok = %t; 
          break;
        end //if chain

        //keep user's current settings if still looping
        ini = [label; msprintf("%i", sgn); msprintf("%i", nbits); msprintf("%i", binpt); ..
          msprintf("%i", overflow); msprintf("%i", quantization)];    
      end //while
  
      if ok then
        outinfo.sign = sgn; 
        outinfo.nbits = nbits; 
        outinfo.binpt = binpt; 
        parameters.out = outinfo;  

        settings.overflow = overflow; 
        settings.quantization = quantization;         
        parameters.settings = settings;

        model.opar(1) = parameters; 
        x.model = model;
      
        exprs(1) = label;
        graphics.exprs = exprs
        x.graphics = graphics;
      end
  
    case 'define' then
      model = scicos_model();
      model.out = 1;     
      model.outtyp = [6]; 
      outinfo = struct('sign', [0], 'nbits', [1], 'binpt', [0], 'calc', 'inport');
      model.in = 1;      
      model.intyp = [-1]; //figure out type from what it is connected to
      ininfo = struct('sign', [-1], 'nbits', [-1], 'binpt', [-1]);
      //default settings
      settings = struct( ..
        'overflow', 0, ..
        'quantization', 0);

      parameters = struct('version', version, 'settings', settings, 'in', ininfo, 'out', outinfo)
      
      //this must be a list, not a struct apparently
      model.opar = list(parameters);
      //create scicos block with standard settings
  
      //TODO input and output labels 
      x = ratel_block_gen([2 1], model, [""], [], []);
  end
endfunction
