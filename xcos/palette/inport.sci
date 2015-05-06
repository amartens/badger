function [x, y, typ] = inport(job, arg1, arg2)
  x = []; y = []; typ = [];
  select job
    case 'set' then
      x = arg1
      graphics = arg1.graphics;
      model = arg1.model
      exprs = graphics.exprs
      ipar = model.ipar
      outsign = ipar(1); outnbits = ipar(2); outbinpt = ipar(3);
      overflow = ipar(4); quantization = ipar(5);

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
        msprintf("%i", overflow); ..        
        msprintf("%i", quantization)];    
      
      while %t do     
        [ok, label, sgn, nbits, binpt, of, q] = scicos_getvalue( ..
          "inport settings", labels, types, ini); 
        if ~ok then
          break
        end
        
        ok = %f;
        //check range
        if (sgn < 0) | (sgn > 1),
          block_parameter_error("incorrect range for ''sign'' setting", "value must be in range [0:1]")
        elseif (nbits < 1),
          block_parameter_error("incorrect range for ''number of bits'' setting", "value must be > 0")
        elseif (binpt < 0),
          block_parameter_error("incorrect range for ''binary point position'' setting", "value must be >= 0")
        elseif (of < 0) | (of > 1),
          block_parameter_error("incorrect range for ''overflow strategy'' setting", "value must be in range [0:1]")
        elseif (q < 0) | (q > 1),
          block_parameter_error("incorrect range for ''quantization strategy'' setting", "value must be in range [0:1]")
        else 
          ok = %t 
          break
        end //if chain

        //keep user's current settings if still looping
        ini = [label; msprintf("%i", sgn); msprintf("%i", nbits); msprintf("%i", binpt); ..
          msprintf("%i", of); msprintf("%i", q)]    
      end //while
  
      if ok then
        ipar = list(sgn, nbits, binpt, of, q)
        model.ipar = ipar
        x.model = model
      
        exprs(1) = label
        graphics.exprs = exprs
        x.graphics = graphics
      end
  
    case 'define' then
      model = scicos_model()
      model.sim = list('inport', 4); //TODO version 4?
      model.out = 1; model.outtyp = [6]; //uint32 type for the moment 
      model.in = 1; model.intyp = [-1];      //figure out type from what it is connected to
                    //outsign, outnbits, outbinpt, overflow, quantization
      model.ipar = list(0, 1, 0, 0, 0) 
      //create scicos block with standard settings
  
      //TODO input and output labels 
      x = ratel_block_gen([2 1], model, [""], [], [])
  end
endfunction
