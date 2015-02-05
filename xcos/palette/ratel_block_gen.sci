function o=badger_block_gen(sz, model, exprs, in_labels, out_labels)
//initialize graphic part of the block data structure

  gr_i=[];

  nin=size(model.in,1);
  if nin>0 then pin(nin,1)=0,else pin=[],end

  nout=size(model.out,1);
  if nout>0 then pout(nout,1)=0,else pout=[],end

  ncin=size(model.evtin,1);
  if ncin>0 then pein(ncin,1)=0,else pein=[],end

  ncout=size(model.evtout,1);
  if ncout>0 then peout(ncout,1)=0,else peout=[],end
  
  if type(gr_i)<>15 then gr_i=list(gr_i,8),end
  if gr_i(2)==[] then gr_i(2)=8,end
  if gr_i(2)==0 then gr_i(2)=[],end
  
  model.blocktype = 'f';

  graphics=scicos_graphics();
  graphics.exprs=exprs;
  graphics.sz=sz;
  graphics.pin=pin;
  graphics.pout=pout;
  graphics.pein=pein;
  graphics.peout=peout;
  graphics.gr_i=gr_i;
  graphics.in_label=in_labels;
  graphics.out_label=out_labels;
  [r,c] = size(in_labels);
  graphics.in_implicit=repmat(['E'], r*c, 1); //make size implicit to fool delete_unconnected  
  
  [ln,mc]=where()
  o=scicos_block(graphics=graphics,model=model,gui=mc(2))
endfunction

