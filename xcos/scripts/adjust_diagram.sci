function [adjusted_diagram, ok] = adjust_diagram(diagram)
//various diagram sanity checks, determines port types etc
//returns updated diagram
  
  ok = %f; adjusted_diagram = diagram;
  //for logging
  fname = 'adjust_diagram';

  if strcmp(typeof(diagram), 'diagram'),
    ratel_log(msprintf('%s passed instead of diagram', typeof(diagram))+'\n', [fname, 'error']);
    return;
  end

  //add blocks to be used during port creation
  ratel_log(msprintf('adding port creation helper blocks to %s',diagram.props.title)+'\n', [fname]);
  [diagram_with_helpers, ko] = add_port_helpers(diagram);
  if ~ko,
    msg = msprintf('error adding port creation helper blocks to diagram %s',diagram.props.title);
    ratel_log(msg+'\n', [fname, 'error']);
    return;
  end 
 
  //we run c_pass1 to do certain connectivity checks and 'flatten' structure
  ratel_log(msprintf('running c_pass1 on %s', diagram.props.title)+'\n', [fname]);
  [blklst, connectmat, ccmat, cor, corinv, ko]=c_pass1(diagram_with_helpers);  
  if ~ko then
    ratel_log('error in first pass\n', [fname, 'error']);
    return;
  end
 
  //adjust size of vector passed through ports 
  ratel_log('adjusting inout\n', [fname]);
  [ko, blklst]=adjust_inout(blklst, connectmat)
  if ~ko then
    ratel_log('error adjusting port inout\n', [fname, 'error']);
    return;
  end
  
  //adjust type of input/output ports
  ratel_log('adjusting type\n', [fname]);
  [ko, blklst]=adjust_typ(blklst, connectmat)
  if ~ko then
    ratel_log('error adjusting port type\n', [fname, 'error']);
    return;
  end

  //adjust fixed point info for blocks
  ratel_log('adjusting fixed point info\n', [fname]);
  [ko, blklst] = adjust_fp(blklst, connectmat)
  if ~ko then
    ratel_log('error adjusting fixed point info\n', [fname, 'error']);
    return;
  end

  //update graphical diagram from flattened block list so that all
  //info is in one place
  ratel_log('adjusting models\n', [fname]);
  [ko, adjusted_diagram] = adjust_models(blklst, cor, diagram_with_helpers, list());
  if ~ko,
    msg = msprintf('error adjusting diagram models from blklst');
    ratel_log(msg+'\n', [fname, 'error']);
    return;
  end  
  
  ok = %t;
endfunction //adjust_diagram

function[diagram_with_helpers, ok] = add_port_helpers(diagram)
//adds blocks after input ports and before output ports that will not
//be removed during c_pass1 that will help when generating verilog
  diagram_with_helpers = diagram; ok = %f;
  fname = 'add_port_helpers';
  in_blocks=["IN_f","INIMPL_f","CLKIN_f","CLKINV_f"]
  out_blocks=["OUT_f","OUTIMPL_f","CLKOUT_f","CLKOUTV_f"]
  
  if strcmp(typeof(diagram), 'diagram'),
    ratel_log(msprintf('%s passed instead of diagram', typeof(diagram))+'\n', [fname, 'error']);
    return;
  end
  
  for obj_i = 1:length(diagram.objs),
    obj = diagram.objs(obj_i);
    n_objs = length(diagram_with_helpers.objs)

    if typeof(obj) == 'Block' then
      //process input port blocks
      if or(obj.gui==in_blocks) then
        msg = msprintf('processing %s(%d)', obj.gui, obj.model.ipar);
        ratel_log(msg+'\n', [fname]);

        //new link between input port and helper
        lnk = scicos_link()
        lnk.id = 'helper'
        lnk.from = [obj_i, 1, 0]
        lnk.to = [n_objs+1, 1, 1] 

        //construct input helper block
        io = inout('define', 'input')
        io.graphics.exprs(1) = msprintf('%s%s', obj.gui, obj.graphics.exprs(1))
        pout = obj.graphics.pout    

        //link helper to input port's links
        io.graphics.pout = pout       
        //link helper to new link to input port
        io.graphics.pin = n_objs+2
        //change input port's link
        obj.graphics.pout = n_objs+2

        //insert new object, new link, and updated object
        diagram_with_helpers.objs(n_objs+1) = io
        diagram_with_helpers.objs(n_objs+2) = lnk
        diagram_with_helpers.objs(obj_i) = obj
    
        //lastly update existing links to point to helper as source
        diagram_with_helpers.objs(pout).from = [n_objs+1, 1, 0]

      elseif or(obj.gui==out_blocks) then
        msg = msprintf('processing %s(%d)', obj.gui, obj.model.ipar);
        ratel_log(msg+'\n', [fname]);

        //new link between helper and output port
        lnk = scicos_link()
        lnk.id = 'helper'
        lnk.from = [n_objs+1, 1, 0]
        lnk.to = [obj_i, 1, 1] 

        //construct output helper block
        io = inout('define', 'output')
        io.graphics.exprs(1) = msprintf('%s%s', obj.gui, obj.graphics.exprs(1))
        pin = obj.graphics.pin
        //link helper to link into output port
        io.graphics.pin = pin       
        //link helper to new link to output port
        io.graphics.pout = n_objs+2

        obj.graphics.pin = n_objs+2

        //insert new object, new link, and updated object
        diagram_with_helpers.objs(n_objs+1) = io
        diagram_with_helpers.objs(n_objs+2) = lnk
        diagram_with_helpers.objs(obj_i) = obj
    
        //lastly update existing links to point to helper as destination
        diagram_with_helpers.objs(pin).to = [n_objs+1, 1, 1]

      elseif obj.model.sim=="super"|obj.model.sim=="csuper" then
        msg = msprintf('adding port helpers to superblock at offset %d', obj_i);
        ratel_log(msg+'\n', [fname]);
        
        //update superblock
        [updated_super, ko] = add_port_helpers(obj.model.rpar);
        if ~ko then
          msg = msprintf('error adding port helpers in superblock found at %d', obj_i);
          ratel_log(msg+'\n', [fname, 'error']);
        end //if
      
        //update diagram with updated super block
        diagram_with_helpers.objs(obj_i).model.rpar = updated_super;
      end //if super
    end //if Block
  end //for

  ok = %t;
endfunction //add_port_helpers

//taken from c_pass2
//adjust_inout : it resolves positive, negative and null size
//               of in/out port dimensions of connected block.
//               If it's not done in a first pass, the second 
//               pass try to resolve negative or null port 
//               dimensions by asking user to informed dimensions 
//               with underconnection function.
//               It is a fixed point algorithm.
//
//in parameters  : bllst : list of blocks
//
//                 connectmat : matrix of connection
//                              connectmat(lnk,1) : source block
//                              connectmat(lnk,2) : source port
//                              connectmat(lnk,3) : target block
//                              connectmat(lnk,4) : target port
//
//out parameters : ok : a boolean flag to known if adjust_inout have
//                      succeeded to resolve the in/out port size
//                      - ok = %t : all size have been resolved in bllst
//                      - ok = %f : problem in size adjustement
//
//                 bllst : modified list of blocks
//
//18/05/06, Alan  : improvement in order to take into
//                  account two dimensional port size.
//
//28/12/06, Alan : type for source port and target port must
//                 be the same.
//
//29/12/06, Fady : type for source and target can be different
//                 in one condition that they are double and complex.
//                 the result on the link will be complex.
//
//04/01/07, Fady : Can test the case of negatives equals target's dimensions.
//
//19/01/07, Alan : - Return correct information for user in editor
//                   with preceding test of Fady in the first pass
//                 - Second pass reviewed : under_connection returns two dimensions now
//
//10/05/07, Alan : - if-then-else event-select case

function [ok,bllst]=adjust_inout(bllst,connectmat)

  //Adjust in2/out2, inttyp/outtyp
  //in accordance to in/out in bllst
  [ko,bllst]=adjust_in2out2(bllst);
  if ~ko then ok=%f,return, end //if adjust_in2out2 failed then exit
                                //adjust_inout with flag ok=%f

  nlnk=size(connectmat,1) //nlnk is the number of link

  //loop on number of block (pass 1 and pass 2)
  for hhjj=1:length(bllst)+1
     //%%%%% pass 1 %%%%%//
     for hh=1:length(bllst)+1 //second loop on number of block
        ok=%t
        for jj=1:nlnk //loop on number of link

           //intyp/outtyp are the type of the
           //target port and the source port of the observed link
           outtyp = bllst(connectmat(jj,1)).outtyp(connectmat(jj,2))
           intyp = bllst(connectmat(jj,3)).intyp(connectmat(jj,4))
           //nnin/nnout are the size (two dimensions) of the
           //target port and the source port of the observed link
           //before adjust
           nnout(1,1)=bllst(connectmat(jj,1)).out(connectmat(jj,2))
           nnout(1,2)=bllst(connectmat(jj,1)).out2(connectmat(jj,2))
           nnin(1,1)=bllst(connectmat(jj,3)).in(connectmat(jj,4))
           nnin(1,2)=bllst(connectmat(jj,3)).in2(connectmat(jj,4))

	   //This Part is done in adjust_typ

           //check intyp/outtyp
//            if intyp<>outtyp then
//              if (intyp==1 & outtyp==2) then
//                bllst(connectmat(jj,3)).intyp(connectmat(jj,4))=2;
//              elseif (intyp==2 & outtyp==1) then
//                bllst(connectmat(jj,1)).outtyp(connectmat(jj,2))=2;
//              else
//                if bllst(connectmat(jj,3)).sim(2)<0 //if-then-else/eselect case
//                  bllst(connectmat(jj,3)).intyp(connectmat(jj,4))=...
//                    bllst(connectmat(jj,1)).outtyp(connectmat(jj,2))
//                else
//                  bad_connection(corinv(connectmat(jj,1)),connectmat(jj,2),..
//                                 nnout,outtyp,..
//                                 corinv(connectmat(jj,3)),connectmat(jj,4),..
//                                 nnin,intyp,1)
//                  ok=%f;
//                  return
//                end
//              end
//            end

           //loop on the two dimensions of source/target port 
           for ndim=1:2
              //check test source/target sizes
              //in case of negatif equal target dimensions
              //nin/nout are the size (two dimensions) of the
              //target port and the source port of the observed link
              nout(1,1)=bllst(connectmat(jj,1)).out(connectmat(jj,2))
              nout(1,2)=bllst(connectmat(jj,1)).out2(connectmat(jj,2))
              nin(1,1)=bllst(connectmat(jj,3)).in(connectmat(jj,4))
              nin(1,2)=bllst(connectmat(jj,3)).in2(connectmat(jj,4))

              //first case : dimension of source and
              //             target ports are explicitly informed
              //             informed with positive size
              if(nout(1,ndim)>0&nin(1,ndim)>0) then
                 //if dimension of source and target port doesn't match
                 //then call bad_connection, set flag ok to false and exit
                 if nin(1,ndim)<>nout(1,ndim) then
                    bad_connection(corinv(connectmat(jj,1)),connectmat(jj,2),..
                                   nnout,outtyp,..
                                   corinv(connectmat(jj,3)),connectmat(jj,4),..
                                   nnin,intyp)
                    ok=%f;return
                 end

              //second case : dimension of source port is
              //              positive and dimension of
              //              target port is negative
              elseif(nout(1,ndim)>0&nin(1,ndim)<0) then
                 //find vector of input ports of target block with
                 //first/second dimension equal to size nin(1,ndim)
                 //and assign it to nout(1,ndim)
                 ww=find(bllst(connectmat(jj,3)).in==nin(1,ndim))
                 bllst(connectmat(jj,3)).in(ww)=nout(1,ndim)
                 ww=find(bllst(connectmat(jj,3)).in2==nin(1,ndim))
                 bllst(connectmat(jj,3)).in2(ww)=nout(1,ndim)

                 //find vector of output ports of target block with
                 //first/second dimension equal to size nin(1,ndim)
                 //and assign it to nout(1,ndim)
                 ww=find(bllst(connectmat(jj,3)).out==nin(1,ndim))
                 bllst(connectmat(jj,3)).out(ww)=nout(1,ndim)
                 ww=find(bllst(connectmat(jj,3)).out2==nin(1,ndim))
                 bllst(connectmat(jj,3)).out2(ww)=nout(1,ndim)

                 //find vector of output ports of target block with
                 //ndim dimension equal to zero and sum the ndim
                 //dimension of all input ports of target block
                 //to be the new dimension of the ndim dimension
                 //of the output ports of the target block
                 if ndim==1 then
                   ww=find(bllst(connectmat(jj,3)).out==0)
                   if (ww<>[]&min(bllst(connectmat(jj,3)).in(:))>0) then
                      bllst(connectmat(jj,3)).out(ww)=sum(bllst(connectmat(jj,3)).in(:))
                   end
                 elseif ndim==2 then
                   ww=find(bllst(connectmat(jj,3)).out2==0)
                   if (ww<>[]&min(bllst(connectmat(jj,3)).in2(:))>0) then
                      bllst(connectmat(jj,3)).out2(ww)=sum(bllst(connectmat(jj,3)).in2(:))
                   end
                 end

                 //if nzcross of the target block match with
                 //the negative dimension nin(1,ndim) then
                 //adjust it to nout(1,ndim)
                 if bllst(connectmat(jj,3)).nzcross==nin(1,ndim) then
                    bllst(connectmat(jj,3)).nzcross=nout(1,ndim)
                 end
                 //if nmode of the target block match with
                 //the negative dimension nin(1,ndim) then
                 //adjust it to nout(1,ndim)
                 if bllst(connectmat(jj,3)).nmode==nin(1,ndim) then
                    bllst(connectmat(jj,3)).nmode=nout(1,ndim)
                 end

              //third case : dimension of source port is
              //             negative and dimension of
              //             target port is positive
              elseif(nout(1,ndim)<0&nin(1,ndim)>0) then
                 //find vector of output ports of source block with
                 //first/second dimension equal to size nout(1,ndim)
                 //and assign it to nin(1,ndim)
                 ww=find(bllst(connectmat(jj,1)).out==nout(1,ndim))
                 bllst(connectmat(jj,1)).out(ww)=nin(1,ndim)
                 ww=find(bllst(connectmat(jj,1)).out2==nout(1,ndim))
                 bllst(connectmat(jj,1)).out2(ww)=nin(1,ndim)

                 //find vector of input ports of source block with
                 //first/second dimension equal to size nout(1,ndim)
                 //and assign it to nin(1,ndim)
                 ww=find(bllst(connectmat(jj,1)).in==nout(1,ndim))
                 bllst(connectmat(jj,1)).in(ww)=nin(1,ndim)
                 ww=find(bllst(connectmat(jj,1)).in2==nout(1,ndim))
                 bllst(connectmat(jj,1)).in2(ww)=nin(1,ndim)

                 //find vector of input ports of source block with
                 //ndim dimension equal to zero and sum the ndim
                 //dimension of all output ports of source block
                 //to be the new dimension of the ndim dimension
                 //of the input ports of the source block
                 if ndim==1 then
                   ww=find(bllst(connectmat(jj,1)).in==0)
                   if (ww<>[]&min(bllst(connectmat(jj,1)).out(:))>0) then
                      bllst(connectmat(jj,1)).in(ww)=sum(bllst(connectmat(jj,1)).out(:))
                   end
                 elseif ndim==2 then
                   ww=find(bllst(connectmat(jj,1)).in2==0)
                   if (ww<>[]&min(bllst(connectmat(jj,1)).out2(:))>0) then
                      bllst(connectmat(jj,1)).in2(ww)=sum(bllst(connectmat(jj,1)).out2(:))
                   end
                 end

                 //if nzcross of the source block match with
                 //the negative dimension nout(1,ndim) then
                 //adjust it to nin(1,ndim)
                 if bllst(connectmat(jj,1)).nzcross==nout(1,ndim) then
                    bllst(connectmat(jj,1)).nzcross=nin(1,ndim)
                 end
                 //if nmode of the source block match with
                 //the negative dimension nout(1,ndim) then
                 //adjust it to nin(1,ndim)
                 if bllst(connectmat(jj,1)).nmode==nout(1,ndim) then
                    bllst(connectmat(jj,1)).nmode=nin(1,ndim)
                 end

              //fourth case : a dimension of source port is
              //              null
              elseif(nout(1,ndim)==0) then
                 //set ww to be the vector of size of the ndim
                 //dimension of input port of the source block
                 if ndim==1 then
                    ww=bllst(connectmat(jj,1)).in(:)
                 elseif ndim==2 then
                    ww=bllst(connectmat(jj,1)).in2(:)
                 end

                 //test if all size of the ndim dimension of input
                 //port of the source block is positive
                 if min(ww)>0 then
                    //test if the dimension of the target port
                    //is positive
                    if nin(1,ndim)>0 then

                       //if the sum of the size of the ndim dimension of the input 
                       //port of the source block is equal to the size of the ndim dimension
                       //of the target port, then the size of the ndim dimension of the source
                       //port is equal to nin(1,ndim)
                       if sum(ww)==nin(1,ndim) then
                          if ndim==1 then
                             bllst(connectmat(jj,1)).out(connectmat(jj,2))=nin(1,ndim)
                          elseif ndim==2 then
                             bllst(connectmat(jj,1)).out2(connectmat(jj,2))=nin(1,ndim)
                          end
                       //else call bad_connection, set flag ok to false and exit
                       else
                          bad_connection(corinv(connectmat(jj,1)),0,0,1,-1,0,0,1)
                          ok=%f;return
                       end

                    //if the ndim dimension of the target port is negative
                    //then the size of the ndim dimension of the source port
                    //is equal to the sum of the size of the ndim dimension
                    //of input ports of source block, and flag ok is set to false
                    else
                       if ndim==1 then
                         bllst(connectmat(jj,1)).out(connectmat(jj,2))=sum(ww)
                       elseif ndim==2 then
                         bllst(connectmat(jj,1)).out2(connectmat(jj,2))=sum(ww)
                       end
                       ok=%f
                    end

                 else
                    //set nww to be the vector of all negative size of input ports
                    //of the source block
                    nww=ww(find(ww<0))

                    //if all negative size have same size and if size of the
                    //ndim dimension of the target port is positive then assign
                    //size of the ndim dimension of the source port to nin(1,ndim)
                    if norm(nww-nww(1),1)==0 & nin(1,ndim)>0 then
                       if ndim==1 then
                          bllst(connectmat(jj,1)).out(connectmat(jj,2))=nin(1,ndim)
                       elseif ndim==2 then
                          bllst(connectmat(jj,1)).out2(connectmat(jj,2))=nin(1,ndim)
                       end

                       //compute a size to be the difference between the size
                       //of the ndim dimension of the target block and sum of positive 
                       //size of input ports of the source block divided by the number
                       //of input ports of source block with same negative size
                       k=(nin(1,ndim)-sum(ww(find(ww>0))))/size(nww,'*')

                       //if this size is a positive integer then assign it
                       //to the size of the ndim dimension of input ports of the 
                       //source block which have negative size
                       if k==int(k)&k>0 then
                          if ndim==1 then
                             bllst(connectmat(jj,1)).in(find(ww<0))=k
                          elseif ndim==2 then
                             bllst(connectmat(jj,1)).in2(find(ww<0))=k
                          end
                       //else call bad_connection, set flag ok to false and exit
                       else
                          bad_connection(corinv(connectmat(jj,1)),0,0,1,-1,0,0,1)
                          ok=%f;return
                       end

                    //set flag ok to false
                    else
                      ok=%f
                    end

                 end

              //fifth case : a dimension of target port is
              //             null
              elseif(nin(1,ndim)==0) then
                 //set ww to be the vector of size of the ndim
                 //dimension of output port of the target block
                 if ndim==1 then
                    ww=bllst(connectmat(jj,3)).out(:)
                 elseif ndim==2 then
                    ww=bllst(connectmat(jj,3)).out2(:)
                 end

                 //test if all size of the ndim dimension of output
                 //port of the target block is positive
                 if min(ww)>0 then
                    //test if the dimension of the source port
                    //is positive
                    if nout(1,ndim)>0 then

                       //if the sum of the size of the ndim dimension of the output 
                       //port of the target block is equal to the size of the ndim dimension
                       //of the source port, then the size of the ndim dimension of the target
                       //port is equal to nout(1,ndim)
                       if sum(ww)==nout(1,ndim) then
                          if ndim==1 then
                             bllst(connectmat(jj,3)).in(connectmat(jj,4))=nout(1,ndim)
                          elseif ndim==2 then
                             bllst(connectmat(jj,3)).in2(connectmat(jj,4))=nout(1,ndim)
                          end
                       //else call bad_connection, set flag ok to false and exit
                       else
                          bad_connection(corinv(connectmat(jj,3)),0,0,1,-1,0,0,1)
                          ok=%f;return
                       end

                    //if the ndim dimension of the source port is negative
                    //then the size of the ndim dimension of the target port
                    //is equal to the sum of the size of the ndim dimension
                    //of output ports of target block, and flag ok is set to false
                    else
                       if ndim==1 then
                         bllst(connectmat(jj,3)).in(connectmat(jj,4))=sum(ww)
                       elseif ndim==2 then
                         bllst(connectmat(jj,3)).in2(connectmat(jj,4))=sum(ww)
                       end
                       ok=%f
                    end

                 else
                    //set nww to be the vector of all negative size of output ports
                    //of the target block
                    nww=ww(find(ww<0))

                    //if all negative size have same size and if size of the
                    //ndim dimension of the source port is positive then assign
                    //size of the ndim dimension of the target port to nout(1,ndim)
                    if norm(nww-nww(1),1)==0 & nout(1,ndim)>0 then
                       if ndim==1 then
                          bllst(connectmat(jj,3)).in(connectmat(jj,4))=nout(1,ndim)
                       elseif ndim==2 then
                          bllst(connectmat(jj,3)).in2(connectmat(jj,4))=nout(1,ndim)
                       end

                       //compute a size to be the difference between the size
                       //of the ndim dimension of the source block and sum of positive 
                       //size of output ports of the target block divided by the number
                       //of output ports of target block with same negative size
                       k=(nout(1,ndim)-sum(ww(find(ww>0))))/size(nww,'*')

                       //if this size is a positive integer then assign it
                       //to the size of the ndim dimension of output ports of the 
                       //target block which have negative size
                       if k==int(k)&k>0 then
                          if ndim==1 then
                             bllst(connectmat(jj,3)).out(find(ww<0))=k
                          elseif ndim==2 then
                             bllst(connectmat(jj,3)).out2(find(ww<0))=k
                          end
                       //else call bad_connection, set flag ok to false and exit
                       else
                          bad_connection(corinv(connectmat(jj,3)),0,0,1,-1,0,0,1)
                          ok=%f;return
                       end

                    //set flag ok to false
                    else
                      ok=%f
                    end

                 end

              //sixth (& last) case : dimension of both source 
              //                      and target port are negatives
              else
                 ok=%f //set flag ok to false
              end
           end
        end
        if ok then return, end //if ok is set true then exit adjust_inout
     end
     //if failed then display message
     messagebox(msprintf(_('Not enough information to find port sizes.\n'+..
              'I try to find the problem.')),"modal","info");

     //%%%%% pass 2 %%%%%//
     //Alan 19/01/07 : Warning  : Behavior have changed, To Be more Tested
     findflag=%f //set findflag to false

     for jj=1:nlnk //loop on number of block
        //nin/nout are the size (two dimensions) of the
        //target port and the source port of the observed link
        nout(1,1)=bllst(connectmat(jj,1)).out(connectmat(jj,2))
        nout(1,2)=bllst(connectmat(jj,1)).out2(connectmat(jj,2))
        nin(1,1)=bllst(connectmat(jj,3)).in(connectmat(jj,4))
        nin(1,2)=bllst(connectmat(jj,3)).in2(connectmat(jj,4))

        //loop on the two dimensions of source/target port
        //only case : target and source ports are both
        //            negatives or null
        if nout(1,1)<=0&nin(1,1)<=0 | nout(1,2)<=0&nin(1,2)<=0 then
            findflag=%t;
            //
            ninnout=under_connection(corinv(connectmat(jj,1)),connectmat(jj,2),nout(1,ndim),..
                                       corinv(connectmat(jj,3)),connectmat(jj,4),nin(1,ndim),1)
            //
            if size(ninnout,2) <> 2 then ok=%f;return;end
            if ninnout==[] then ok=%f;return;end
            if ninnout(1,1)<=0 | ninnout(1,2)<=0 then ok=%f;return;end
            //
            ww=find(bllst(connectmat(jj,1)).out==nout(1,1))
            bllst(connectmat(jj,1)).out(ww)=ninnout(1,1)
            ww=find(bllst(connectmat(jj,1)).out2==nout(1,1))
            bllst(connectmat(jj,1)).out2(ww)=ninnout(1,1)

            ww=find(bllst(connectmat(jj,1)).out==nout(1,2))
            bllst(connectmat(jj,1)).out(ww)=ninnout(1,2)
            ww=find(bllst(connectmat(jj,1)).out2==nout(1,2))
            bllst(connectmat(jj,1)).out2(ww)=ninnout(1,2)
            //

            if bllst(connectmat(jj,1)).nzcross==nout(1,1) then
               bllst(connectmat(jj,1)).nzcross=ninnout(1,1)
            end
            if bllst(connectmat(jj,1)).nzcross==nout(1,2) then
               bllst(connectmat(jj,1)).nzcross=ninnout(1,2)
            end
            //
            if bllst(connectmat(jj,1)).nmode==nout(1,1) then
               bllst(connectmat(jj,1)).nmode=ninnout(1,1)
            end
            if bllst(connectmat(jj,1)).nmode==nout(1,2) then
               bllst(connectmat(jj,1)).nmode=ninnout(1,2)
            end
            //
            ww=find(bllst(connectmat(jj,1)).in==nout(1,1))
            bllst(connectmat(jj,1)).in(ww)=ninnout(1,1)
            ww=find(bllst(connectmat(jj,1)).in2==nout(1,1))
            bllst(connectmat(jj,1)).in2(ww)=ninnout(1,1)

            ww=find(bllst(connectmat(jj,1)).in==nout(1,2))
            bllst(connectmat(jj,1)).in(ww)=ninnout(1,2)
            ww=find(bllst(connectmat(jj,1)).in2==nout(1,2))
            bllst(connectmat(jj,1)).in2(ww)=ninnout(1,2)
            //
            ww=find(bllst(connectmat(jj,1)).in==0)
            if (ww<>[]&min(bllst(connectmat(jj,1)).out(:))>0) then 
               bllst(connectmat(jj,1)).in(ww)=sum(bllst(connectmat(jj,1)).out)
            end

            ww=find(bllst(connectmat(jj,1)).in2==0)
            if (ww<>[]&min(bllst(connectmat(jj,1)).out2(:))>0) then 
                 bllst(connectmat(jj,1)).in2(ww)=sum(bllst(connectmat(jj,1)).out2)
            end
            //
            ww=find(bllst(connectmat(jj,3)).in==nin(1,1))
            bllst(connectmat(jj,3)).in(ww)=ninnout(1,1)
            ww=find(bllst(connectmat(jj,3)).in2==nin(1,1))
            bllst(connectmat(jj,3)).in2(ww)=ninnout(1,1)

            ww=find(bllst(connectmat(jj,3)).in==nin(1,2))
            bllst(connectmat(jj,3)).in(ww)=ninnout(1,2)
            ww=find(bllst(connectmat(jj,3)).in2==nin(1,2))
            bllst(connectmat(jj,3)).in2(ww)=ninnout(1,2)
            //
            if bllst(connectmat(jj,3)).nzcross==nin(1,1) then
               bllst(connectmat(jj,3)).nzcross=ninnout(1,1)
            end
            if bllst(connectmat(jj,3)).nzcross==nin(1,2) then
               bllst(connectmat(jj,3)).nzcross=ninnout(1,2)
            end
            if bllst(connectmat(jj,3)).nmode==nin(1,1) then
               bllst(connectmat(jj,3)).nmode=ninnout(1,1)
            end
            if bllst(connectmat(jj,3)).nmode==nin(1,2) then
               bllst(connectmat(jj,3)).nmode=ninnout(1,2)
            end
            //
            ww=find(bllst(connectmat(jj,3)).out==nin(1,1))
            bllst(connectmat(jj,3)).out(ww)=ninnout(1,1)
            ww=find(bllst(connectmat(jj,3)).out2==nin(1,1))
            bllst(connectmat(jj,3)).out2(ww)=ninnout(1,1)

            ww=find(bllst(connectmat(jj,3)).out==nin(1,2))
            bllst(connectmat(jj,3)).out(ww)=ninnout(1,2)
            ww=find(bllst(connectmat(jj,3)).out2==nin(1,2))
            bllst(connectmat(jj,3)).out2(ww)=ninnout(1,2)
            //
            ww=find(bllst(connectmat(jj,3)).out==0)
            if (ww<>[]&min(bllst(connectmat(jj,3)).in(:))>0) then
               bllst(connectmat(jj,3)).out(ww)=sum(bllst(connectmat(jj,3)).in(:))
            end
            ww=find(bllst(connectmat(jj,3)).out2==0)
            if (ww<>[]&min(bllst(connectmat(jj,3)).in2(:))>0) then
               bllst(connectmat(jj,3)).out2(ww)=sum(bllst(connectmat(jj,3)).in2(:))
            end
        end
     end

     //if failed then display message
     if ~findflag then 
        messagebox(msprintf(_('I cannot find a link with undetermined size.\n'+..
		      'My guess is that you have a block with unconnected \n'+..
			      'undetermined output ports.')),"modal","error");
        ok=%f;return;
     end
  end
endfunction //adjust_inout

//taken directly from c_pass2.sci
// adjust_typ: It resolves positives and negatives port types.
//		   Its Algorithm is based on the algorithm of adjust_inout
// Fady NASSIF: 14/06/2007

function [ok,bllst]=adjust_typ(bllst,connectmat)

  for i=1:length(bllst)
    if size(bllst(i).in,1)<>size(bllst(i).intyp,2) then
      bllst(i).intyp=bllst(i).intyp(1)*ones(size(bllst(i).in,1),1);
    end
    if size(bllst(i).out,1)<>size(bllst(i).outtyp,2) then
      bllst(i).outtyp=bllst(i).outtyp(1)*ones(size(bllst(i).out,1),1);
    end
  end
  nlnk=size(connectmat,1) 
  for hhjj=1:length(bllst)+1
    for hh=1:length(bllst)+1 
      ok=%t
      for jj=1:nlnk 
        nnout(1,1)=bllst(connectmat(jj,1)).out(connectmat(jj,2))
        nnout(1,2)=bllst(connectmat(jj,1)).out2(connectmat(jj,2))
        nnin(1,1)=bllst(connectmat(jj,3)).in(connectmat(jj,4))
        nnin(1,2)=bllst(connectmat(jj,3)).in2(connectmat(jj,4))
        outtyp = bllst(connectmat(jj,1)).outtyp(connectmat(jj,2))
        intyp = bllst(connectmat(jj,3)).intyp(connectmat(jj,4))
        
        //first case : types of source and
        //             target ports are explicitly informed
        //             with positive types
        if (intyp>0 & outtyp>0) then
    //if types of source and target port doesn't match and aren't double and complex
    //then call bad_connection, set flag ok to false and exit
    
    if intyp<>outtyp then
      if (intyp==1 & outtyp==2) then
        bllst(connectmat(jj,3)).intyp(connectmat(jj,4))=2;
      elseif (intyp==2 & outtyp==1) then
        bllst(connectmat(jj,1)).outtyp(connectmat(jj,2))=2;
      else
        bad_connection(corinv(connectmat(jj,1)),connectmat(jj,2),..
      nnout,outtyp,..
      corinv(connectmat(jj,3)),connectmat(jj,4),..
      nnin,intyp,1)
        ok=%f;
        return
      end
    end
    
    //second case : type of source port is
    //              positive and type of
    //              target port is negative
        elseif(outtyp>0&intyp<0) then
    //find vector of input ports of target block with
    //type equal to intyp
    //and assign it to outtyp
    ww=find(bllst(connectmat(jj,3)).intyp==intyp)
    bllst(connectmat(jj,3)).intyp(ww)=outtyp
    
    //find vector of output ports of target block with
    //type equal to intyp
    //and assign it to outtyp
    ww=find(bllst(connectmat(jj,3)).outtyp==intyp)
    bllst(connectmat(jj,3)).outtyp(ww)=outtyp
    
    //third case : type of source port is
    //             negative and type of
    //             target port is positive
        elseif(outtyp<0&intyp>0) then
    //find vector of output ports of source block with
    //type equal to outtyp
    //and assign it to intyp
    ww=find(bllst(connectmat(jj,1)).outtyp==outtyp)
    bllst(connectmat(jj,1)).outtyp(ww)=intyp
    
    //find vector of input ports of source block with
    //type equal to size outtyp
    //and assign it to intyp
    ww=find(bllst(connectmat(jj,1)).intyp==outtyp)
    bllst(connectmat(jj,1)).intyp(ww)=intyp
    
    
    //fourth (& last) case : type of both source 
    //                      and target port are negatives
        else
    ok=%f //set flag ok to false
        end
      end
      if ok then return, end //if ok is set true then exit adjust_typ
    end
    //if failed then display message
    messagebox(msprintf(_('Not enough information to find port type.\n'+..
        'I will try to find the problem.')),"modal","info");
    findflag=%f 
    for jj=1:nlnk 
      nouttyp=bllst(connectmat(jj,1)).outtyp(connectmat(jj,2))
      nintyp=bllst(connectmat(jj,3)).intyp(connectmat(jj,4))
      
      //loop on the two dimensions of source/target port
      //only case : target and source ports are both
      //            negatives or null
      if nouttyp<=0 & nintyp<=0 then
        findflag=%t;
        //
        inouttyp=under_connection(corinv(connectmat(jj,1)),connectmat(jj,2),nouttyp,..
      corinv(connectmat(jj,3)),connectmat(jj,4),nintyp,2)			   
        //
        if inouttyp<1|inouttyp>8 then ok=%f;return;end
        //
        ww=find(bllst(connectmat(jj,1)).outtyp==nouttyp)
        bllst(connectmat(jj,1)).outtyp(ww)=inouttyp
        
        //
        ww=find(bllst(connectmat(jj,1)).intyp==nouttyp)
        bllst(connectmat(jj,1)).intyp(ww)=inouttyp
        
        ww=find(bllst(connectmat(jj,3)).intyp==nintyp)
        bllst(connectmat(jj,3)).intyp(ww)=inouttyp
        //
        ww=find(bllst(connectmat(jj,3)).outtyp==nintyp)
        bllst(connectmat(jj,3)).outtyp(ww)=inouttyp
        
        //
      end
    end
    //if failed then display message
    if ~findflag then 
      messagebox(msprintf(_('I cannot find a link with undetermined size.\n'+..
          'My guess is that you have a block with unconnected \n'+..
          'undetermined types.')),"modal","error");
      ok=%f;return;
    end
  end
endfunction //adjust_typ

function[ok, bllst] = adjust_fp(bllst, connectmat)
//adjust_fp: Resolves fp info.
//  based on adjust_inout algorithm
//  Andrew: 05/12/2014

  ok = %f;
  fname = 'adjust_fp';

  nlnk=size(connectmat,1); //nlnk is the number of link

  //loop on number of block (pass 1 and pass 2)
  for hhjj=1:length(bllst)+1
    //%%%%% pass 1 %%%%%//
    for hh=1:length(bllst)+1 //second loop on number of block
      done=%t
      for jj=1:nlnk //loop on number of link
        srcblk = bllst(connectmat(jj,1)); 
        tgtblk = bllst(connectmat(jj,3));
        //we only care about links where source and destination
        //blocks use fixed point
        src_obt = srcblk.blocktype; tgt_ibt = tgtblk.blocktype;
        if (strcmp(src_obt, 'f') == 0) & (strcmp(tgt_ibt, 'f') == 0) then
          msg = msprintf('processing fixed point link between %d and %d', connectmat(jj,1), connectmat(jj,3));  
          ratel_log(msg+'\n', [fname]);
          //in/outinfo are parameter structs for blocks
          //containing fixed point info for ports
          src_oinfo = srcblk.opar(1).out; tgt_iinfo = tgtblk.opar(1).in;
          tgt_oinfo = tgtblk.opar(1).out;

          srcport_idx = connectmat(jj,2); tgtport_idx = connectmat(jj,4);

          //try to get other info.
          //if other info not available, ask block to try calculate it.
          //if still no luck, then mark as negative for this run

          srcsign = -1; srcnbits = -1; srcbinpt = -1;
          if (length(src_oinfo.sign) >= srcport_idx) then 
            srcsign = src_oinfo.sign(srcport_idx); 
          end
          if (length(src_oinfo.nbits) >= srcport_idx) then 
            srcnbits = src_oinfo.nbits(srcport_idx); 
          end
          if (length(src_oinfo.binpt) >= srcport_idx) then  
            srcbinpt = src_oinfo.binpt(srcport_idx);
          end
          
          tgtsign = -1; tgtnbits = -1; tgtbinpt = -1;
          if (length(tgt_iinfo.sign) >= tgtport_idx) then 
            tgtsign = tgt_iinfo.sign(tgtport_idx); 
          end
          if (length(tgt_iinfo.nbits) >= tgtport_idx) then 
            tgtnbits = tgt_iinfo.nbits(tgtport_idx); 
          end
          if (length(tgt_iinfo.binpt) >= tgtport_idx) then  
            tgtbinpt = tgt_iinfo.binpt(tgtport_idx);
          end

	        ratel_log('before:\n', [fname]);
          msg = msprintf('source: sign(%d) (%d,%d)', srcsign, srcnbits, srcbinpt);   
          ratel_log(msg+'\n', [fname]);
          msg = msprintf('target: sign(%d) (%d,%d)', tgtsign, tgtnbits, tgtbinpt);   
          ratel_log(msg+'\n', [fname]);

          //TODO
          //ask block to determine its own output settings
          //if outsign < 0 | outnbits < 0 | outbinpt < 0 then
          //  outcalc = outinfo.outcalc;  //function to calculate out info
          //  fn_call_str = msprintf('[x] = %s(''adjust'', outblk)', outcalc); 
          //  execstr(fn_call_str);
          //  //TODO how to check for errors? 
          //end
          //bllst(connectmat(jj,1)) = x;
          //outinfo = x.opar(1).out;
          //outsign = -1; outnbits = -1; outbinpt = -1;
          //outsign = outinfo.sign(outport);
          //outnbits = outinfo.nbits(outport);
          //outbinpt = outinfo.binpt(outport);
         
          //if both src and dest are positive but different
          if (tgtsign >= 0) & (srcsign >= 0) then 
            if (srcsign <> tgtsign) then 
              ratel_log('sign mismatch\n', [fname, 'error']);
              return;
            end //if
          //if src has a sign but target doesn't
          elseif tgtsign < 0 & srcsign >= 0 then 
            //update target port with sign
            tgt_iinfo.sign(tgtport_idx) = srcsign;
	          //find vector of output ports of target block with
	          //sign equal to tgtsign and assign it to srcsign
	          ww=find(tgt_oinfo.sign==tgtsign)
	          tgt_oinfo.sign(ww)=srcsign
          else
            done = %f;
          end
          
          //if both src and dest are positive but different
          if (srcnbits >= 0) & (tgtnbits >= 0) then
            if (srcnbits <> tgtnbits) then 
              ratel_log('number bits mismatch\n', [fname, 'error']);
              return;
            end //if
          elseif tgtnbits < 0 & srcnbits >= 0 then 
            tgt_iinfo.nbits(tgtport_idx) = srcnbits;
	          //find vector of output ports of target block with
	          //nbits equal to tgtnbits and assign it to srcnbits
	          ww=find(tgt_oinfo.nbits==tgtnbits)
	          tgt_oinfo.nbits(ww)=srcnbits
          else
            done = %f;
          end
          
          //if both src and dest are positive but different
          if (srcbinpt >= 0) & (tgtbinpt >= 0) then
            if (srcbinpt <> tgtbinpt) then 
              ratel_log('binary point mismatch\n', [fname, 'error']);
              return;
            end //if
          elseif tgtbinpt < 0 & srcbinpt >= 0 then 
            tgt_iinfo.binpt(tgtport_idx) = srcbinpt;
	          //find vector of output ports of target block with
	          //nbits equal to tgtnbits and assign it to srcnbits
	          ww=find(tgt_oinfo.binpt==tgtbinpt);
	          tgt_oinfo.binpt(ww)=srcbinpt;
          else
            done = %f;
          end
	  
          tgtsign = tgt_iinfo.sign(tgtport_idx); 
          tgtnbits = tgt_iinfo.nbits(tgtport_idx); 
          tgtbinpt = tgt_iinfo.binpt(tgtport_idx);
	        ratel_log('after:\n', [fname]);
          msg = msprintf('target: sign(%d) (%d,%d)', tgtsign, tgtnbits, tgtbinpt);   
          ratel_log(msg+'\n', [fname]);

          //update block list
          tgtblk.opar(1).in = tgt_iinfo;
          tgtblk.opar(1).out = tgt_oinfo;
          bllst(connectmat(jj,3)) = tgtblk;  

        end //if blocktype
      end //link loop
      //if ok is still set then gone through all links so return
      if done then 
        ok = %t 
        return 
      end //if  
    end //second loop
  end  //outer loop
endfunction //adjust_fp

function [ok, adjusted_diagram] = adjust_models(blklst, cor, diagram, offset)
//adjust models in diagram from blklst using cor starting at offset
  ok = %f; adjusted_diagram = diagram;
  fname = 'adjust_models';
 
  if typeof(diagram) ~= 'diagram',
    ratel_log(msprintf('%s passed instead of diagram', typeof(diagram))+'\n', [fname, 'error']);
    return;
  end

  diagname = diagram.props.title;

  //iterate through diagram
  for obj_index = 1:length(diagram.objs),
    obj = diagram.objs(obj_index);

    if typeof(obj) == 'Block' then
      updated_obj = obj;  
      blk_type = obj.gui;

      //if we have a superblock we update the models in it  
      if blk_type == 'SUPER_f' then
        msg = msprintf('updating models in superblock found at %d', obj_index);
        ratel_log(msg+'\n', [fname]);
        //update superblock
        [ko, updated_diagram] = adjust_models(blklst, cor, obj.model.rpar, list(offset(:), obj_index));
        if ~ko then
          msg = msprintf('error updating models in superblock found at %d', obj_index);
          ratel_log(msg+'\n', [fname, 'error']);
        end //if

        //update the adjusted diagram with updated superblock
        adjusted_diagram.objs(obj_index).model.rpar = updated_diagram;

      //otherwise we have a normal block to be updated from blklst
      else, 
        location = cor(list(offset(:), obj_index));
      
        //cor contains a 0 for the location if the block has been excluded during c_pass1
        if location(1) ~= 0 then
          loc_str = '';
          for loci = 1:length(location),
            if loci ~= 1 then loc_str = loc_str+','; end //if
            loc_str = loc_str+msprintf('%d',location(loci));
          end //for
          msg = msprintf('found %s ''%s'' at location [%s]', blk_type, obj.graphics.exprs(1), loc_str);
          ratel_log(msg+'\n', [fname]);
        
          //update model 
          obj.model = blklst(location);
          updated_obj = obj;
        else,
          ratel_log(msprintf('%s %s excluded from update', blk_type, obj.graphics.exprs(1))+'\n', [fname]);
        end //if location
      end //if super_block

      //update diagram with updated object 
      adjusted_diagram.objs(obj_index) = updated_obj;
    end // if Block
  end //for
    
  ok = %t;
endfunction //adjust_models

