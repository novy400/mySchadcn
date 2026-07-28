**free
        /if defined(*CRTBNDRPG)
         ctl-opt dftactgrp(*no)
                 actgrp(*new);
        /endif
        Ctl-Opt BndDir('QC2LE':'CKOOL')
                Option(*nodebugio:*srcstmt:*nounref)
                main(main);
        /include 'employee.rpgleinc'
        //------------------------------------------------------------- *
        dcl-proc  main;
        dcl-pi *N;
        end-pi;
          dcl-s ErrorHappened ind ;
        dcl-ds lContext likeDS(CMAGIC_context) inz;
        dcl-s lTotalCount like(CMAGIC_totalCount);
        dcl-ds lErrors likeDS(GLOBAL_listError) inz;
        dcl-s list pointer;
        dcl-ds lItem likeds(employee_item_t) based(lItemPtr);
        dcl-s lCount int(10);
        clear lContext;
        lContext.pagination.perPage = 10;
        lContext.pagination.numPage = 1;
        lContext.sort = *blanks;
        lContext.filter = *blanks;
        IF not employee_search(lContext : lTotalCount : list : lErrors);
         CKOOL_displayListError(lErrors);
        else;
           CKOOL_displayLongMessage('Employee search OK');
            CKOOL_displayLongMessage('Total count : ' + %char(lTotalCount));
           lItemPtr = list_get(list : 0);
           CKOOL_displayLongMessage('Employee : ' + lItem.id.code + ' - ' + lItem.nom);
         dow (1 <> 0);
           lItemPtr = list_iterate(list);
            if lItemPtr = *null;
              leave;
            endif;
            CKOOL_displayLongMessage('Employee : ' + lItem.id.code + ' - ' + lItem.nom);
         enddo;
        clear lCount;
        lCount = list_size(list);
        CKOOL_displayLongMessage('Total items in list : ' + %char(lCount));
        endif;

        on-exit ErrorHappened;
          if ErrorHappened;
          endif;
          list_dispose(list);           
          return;
        end-proc;
