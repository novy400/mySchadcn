**free

/if defined(*CRTBNDRPG)
ctl-opt dftactgrp(*no)
         actgrp(*new);
/endif

Ctl-Opt Main(HELLO);
/include 'cmagic.rpgleinc'
dcl-s HELLO_message varchar(220) template;
Dcl-Proc HELLO;
  Dcl-Pi *N;    
    pMessage like(HELLO_message) const;
  End-Pi;

    snd-msg *INFO %trim(pMessage);
  
End-Proc;