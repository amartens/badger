function [x, y, typ] = inout(job, arg1, arg2)
//a helper block inserted to ease creation of verilog ports
  x = []; y = []; typ = [];
  select job
    case 'define' then
      model = scicos_model();

      //all input parameters are determined from source    
      model.in = 1; model.intyp = [-2];  
      model.insign = [-2]; model.innbits = [-2]; model.inbinpt = [-2];
      
      //all output parameters are determined from source    
      model.out = 1; model.outtyp = [-2]; 
      model.outsign = [-2]; model.outnbits = [-2]; model.outbinpt = [-2];
      
      //this must be a list, not a struct apparently
      model.ipar = arg1; //1 = input, 0 = output

      //create scicos block with standard settings  
      //TODO input and output labels 
      x = ratel_block_gen([2 1], model, [""], [], []);
  end
endfunction
