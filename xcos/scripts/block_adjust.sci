function[blk, ok] = block_adjust(job, arg1)
//calls 
  ok = %f; fname = 'block_adjust'

  blk = arg1
  if typeof(blk) == 'fpmodel', base = blk.sim(1);
  elseif typeof(blk) == 'Block', base = blk.model.sim(1);
  else, 
    ratel_log(msprintf('don''t know how to use %s',typeof(blk))+'\n',{[fname], 'error'})
    return
  end //if
  fn_name = msprintf('%s_adjust', base)
  ratel_log(msprintf('fn_name = %s',fn_name)+'\n',[fname])
  // if adjust object with right name exists
  if exists(fn_name),
    str = msprintf('t = typeof(%s)', fn_name) 
    execstr(str)
    if ~exists('t'),
      ratel_log(msprintf('execstr(''%s'') returned no result',str)+'\n', {'error',[fname]});
      return
    else,
      if isempty(t),
        ratel_log(msprintf('execstr(''%s'') returned empty result',str)+'\n', {'error',[fname]});
        return
      else,              
        //and it is a function
        if t == 'function',
          //call it asking it to determine fixed point info for srcblk
          fn_call_str = msprintf('[x] = %s(''%s'', blk)',fn_name,job)
          execstr(fn_call_str)
          if ~exists('x'),
            ratel_log(msprintf('execstr(''%s'') returned no result',fn_call_str)+'\n', {'error',[fname]})
            return
          else,
            if isempty(x),
              ratel_log(msprintf('execstr(''%s'') returned empty result',fn_call_str)+'\n', {'error',[fname]})
              return
            else,
              blk = x
            end
          end //if ~exists(x)
        end //if t == function
      end //isempty(t)
    end //~exists(t)
  end //exists(fn_fname)
  //note that if fn_name does not exist we return the block unchanged 
  //and don't report an error 

  ok = %t;
endfunction //block_adjust
