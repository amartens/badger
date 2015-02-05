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

function [ok,bllst]=ratel_adjust_inout(bllst,connectmat)

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
endfunction
