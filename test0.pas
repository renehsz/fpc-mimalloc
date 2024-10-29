program test0;

uses fpc_mimalloc;

var p1, p2, p3: Pointer;
    i: Integer;
begin
    (* Test 0: Basic allocation and deallocation *)
    p1 := GetMem(10);
    FreeMem(p1);
    WriteLn('Test 0 complete');

    (* Test 1: Allocate and deallocate multiple blocks *)
    p1 := GetMem(10);
    p2 := GetMem(20);
    p3 := GetMem(30);
    for i := 0 to 9 do
        PByte(P1)[i] := i;
    for i := 0 to 19 do
        PByte(P2)[i] := i;
    for i := 0 to 29 do
        PByte(P3)[i] := i;
    FreeMem(p1);
    FreeMem(p2);
    FreeMem(p3);
    FreeMem(p3); (* intentionally try to free multiple times (which should not crash with this allocator) *)
    FreeMem(p3);
    WriteLn('Test 1 complete');

    (* Test 2: Re-allocate and deallocate multiple blocks *)
    p1 := GetMem(10);
    p2 := GetMem(20);
    p3 := GetMem(30);
    for i := 0 to 9 do
        PByte(P1)[i] := i;
    for i := 0 to 19 do
        PByte(P2)[i] := i;
    for i := 0 to 29 do
        PByte(P3)[i] := i;
    p1 := ReAllocMem(p1, 20);
    p2 := ReAllocMem(p2, 30);
    p3 := ReAllocMem(p3, 40);
    for i := 0 to 9 do
        if PByte(P1)[i] <> i then
            WriteLn('Test 2 ERROR');
    for i := 0 to 19 do
        if PByte(P2)[i] <> i then
            WriteLn('Test 2 ERROR');
    for i := 0 to 29 do
        if PByte(P3)[i] <> i then
            WriteLn('Test 2 ERROR');
    FreeMem(p1);
    FreeMem(p2);
    FreeMem(p3);
    WriteLn('Test 2 complete');
end.
