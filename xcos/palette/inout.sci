function [x, y, typ] = inout(job, arg1, arg2)
//a helper block inserted to ease creation of verilog ports
  x = []; y = []; typ = [];
  select job
    case 'define' then
      model = scicos_model();

      model.sim = list('inout', 4)

      //all input parameters are determined from source    
      model.in = 1; model.intyp = [-1];  
      
      //all output parameters are determined from source    
      model.out = 1; model.outtyp = [-1]; 
      
      model.ipar = arg1; //1 = input, 0 = output

      //create scicos block with standard settings  
      //id, input and outputs labels are all port name
      x = ratel_block_gen([2 1], model, [arg2], [''], ['']);
  end
endfunction
