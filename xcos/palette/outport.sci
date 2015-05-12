function [x, y, typ] = outport(job, arg1, arg2)
  x = []; y = []; typ = [];
  select job
    case 'set' then
      x=arg1;
      graphics=arg1.graphics;
      model=arg1.model;
      exprs=graphics.exprs;

      while %t do
        [ok, label]=scicos_getvalue("outport settings",..
                 ["label"], list('str', -1), [exprs(1)]);
        if ~ok then
          break
        end
        break
      end //while
        
      if ok then
        x.model=model
        exprs(1) = label
        graphics.exprs = exprs
        x.graphics = graphics
      end //if

    case 'define' then
      model = scicos_model()
      model.sim = list('outport', 4); //TODO version 4?
      model.out = 1; model.outtyp = [-1]
      model.in = 1; model.intyp = [-1]
      //create scicos block with standard settings
      //TODO make graphics nicer
      x = ratel_block_gen([2 1], model, [""], [], [])
  end
endfunction
