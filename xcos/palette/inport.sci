function [x, y, typ] = inport(job, arg1, arg2)
  x= []; y = []; typ = [];
  version = 0.1;
  select job
    case 'set' then
      x=arg1;
      graphics=arg1.graphics;
      model=arg1.model;
      exprs=graphics.exprs;
      settings = model.opar(4);

      labels = [ ..
        "label"; ..
        "data type (0=Unsigned, 1=Signed)"; ..
        "number of bits"; ..
        "binary point position"; ..
        "overflow strategy (0=Wrap, 1=Saturate)"; ..
        "quantization strategy (0=Truncate, 1=Round)"];
      typ = list('str', -1, 'intvec', 1, 'intvec', 1, 'intvec', 1, 'intvec', 1, 'intvec', 1);
      ini = [..
        exprs(1); ..
        msprintf("%i", settings.dtype); ..
        msprintf("%i", settings.n_bits); ..        
        msprintf("%i", settings.bin_pt); ..
        msprintf("%i", settings.overflow); ..        
        msprintf("%i", settings.quantization)];    
      
      while %t do     
        [ok, label, dtype, n_bits, bin_pt, overflow, quantization] = scicos_getvalue( ..
          "inport settings", labels, typ, ini); 
        if ~ok then
          break
        end
        
        ok = %f;
        //check range
        if (dtype < 0) | (dtype > 1) then
          block_parameter_error("incorrect range for ''data type'' setting", "value must be in range [0:1]");
        elseif (n_bits < 1) then
          block_parameter_error("incorrect range for ''number of bits'' setting", "value must be > 0");
        elseif (bin_pt < 0) then
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
        ini = [label; msprintf("%i", dtype); msprintf("%i", n_bits); msprintf("%i", bin_pt); ..
          msprintf("%i", overflow); msprintf("%i", quantization)];    
      end //while
  
      if ok then
        settings.dtype = dtype; 
        settings.n_bits = n_bits; 
        settings.bin_pt = bin_pt; 
        settings.overflow = overflow; 
        settings.quantization = quantization; 
        model.opar(4) = settings; 
        x.model = model;
      
        exprs(1) = label;
        graphics.exprs = exprs
        x.graphics = graphics;
      end

    case 'define' then
      model = scicos_model();
      model.blocktype = 'c';
      model.out = 1;
      model.outtyp = [1];
      model.in = 1;
      model.intyp = [1];
      //default settings
      settings = struct( ..
        'dtype', 1, ..
        'n_bits', 8, ..
        'bin_pt', 7, ..
        'overflow', 0, ..
        'quantization', 0);
      model.opar = list('version', version, 'settings', settings);
      //create scicos block with standard settings
  
      //TODO input and output labels 
      x = badger_block_gen([2 1], model, [""], [], []);
  end
endfunction
