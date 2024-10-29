(*
  This file is free and unencumbered software released into the public domain.
  The license of the mimalloc library can be found in the LICENSE file of the mimalloc submodule.
*)
Unit fpc_mimalloc;

Interface

{$LINKLIB mimalloc}

const
    LibName = 'mimalloc';

    Function mi_malloc(Size: ptruint): Pointer; cdecl; external LibName name 'mi_malloc';
    Function mi_calloc(Count, Size: ptruint): Pointer; cdecl; external LibName name 'mi_malloc';
    Procedure mi_free(P: Pointer); cdecl; external LibName name 'mi_free';
    Function mi_realloc(P: Pointer; Size: ptruint): Pointer; cdecl; external LibName name 'mi_realloc';
    Function mi_usable_size(P: Pointer): ptruint; cdecl; external LibName name 'mi_usable_size';
    Procedure mi_thread_init; cdecl; external LibName name 'mi_thread_init';
    Procedure mi_thread_done; cdecl; external LibName name 'mi_thread_done';
    Procedure mi_process_info(elapsed_msecs, user_msecs, system_msecs, current_rss, peak_rss, current_commit, peak_commit, page_faults: pptruint); cdecl; external LibName name 'mi_process_info';

Implementation

type pptruint = ^ptruint;

Function MIGetMem(Size: ptruint): Pointer;
begin
    MIGetMem := mi_malloc(Size + sizeof(ptruint));

    if MIGetMem <> nil then
    begin
        pptrint(MIGetMem)^ := Size;
        Inc(MIGetMem, sizeof(ptruint));
    end;
end;

Function MIFreeMem(P: Pointer): ptruint;
begin
    if P <> nil then
        Dec(P, sizeof(ptruint));

    mi_free(P);
    MIFreeMem := 0;
end;

Function MIFreeMemSize(P: Pointer; Size: ptruint): ptruint;
begin
    if Size <= 0 then
    begin
        if Size = 0 then
            exit;
        runerror(204);
    end;

    if P <> nil then
    begin
        if Size <> pptruint(P - sizeof(ptruint))^ then
            runerror(204);
    end;

    MIFreeMemSize := MIFreeMem(P);
end;

Function MIAllocMem(Size: ptruint): Pointer;
var
    TotalSize: ptruint;
begin
    TotalSize := Size + sizeof(ptruint);

    MIAllocMem := mi_calloc(TotalSize, 1);

    if MIAllocMem <> nil then
    begin
        pptruint(MIAllocMem)^ := Size;
        Inc(MIAllocMem, sizeof(ptruint));
    end;
end;

Function MIReAllocMem(var P: Pointer; Size: ptruint): Pointer;
begin
    if Size = 0 then
    begin
        if P <> nil then
        begin
            dec(P, sizeof(ptruint));

            mi_free(P);
            P := nil;
        end;
    end
    else
    begin
        Inc(Size, sizeof(ptruint));
        if P = nil then
            P := mi_malloc(Size)
        else
        begin
            Dec(P, sizeof(ptruint));
            P := mi_realloc(P, Size);
        end;

        if P <> nil then
        begin
            pptruint(p)^ := Size - sizeof(ptruint);
            Inc(P, sizeof(ptruint));
        end;
    end;

    MIReAllocMem := P;
end;

Function MIMemSize(P: Pointer): ptruint;
begin
    MIMemSize := pptruint(P - sizeof(ptruint))^;
end;

Procedure MIThreadInit;
begin
    mi_thread_init;
end;

Procedure MIThreadDone;
begin
    mi_thread_done;
end;

Function MIGetHeapStatus: THeapStatus;
var CurrentRSS, PeakRSS, CurrentCommit, PeakCommit, PageFaults: ptruint;
begin
    FillChar(MIGetHeapStatus, SizeOf(MIGetHeapStatus), 0);
    mi_process_info(nil, nil, nil, @CurrentRSS, @PeakRSS, @CurrentCommit, @PeakCommit, @PageFaults);
    (* TODO: Verify that any of this is correct *)
    MIGetHeapStatus.TotalAddrSpace := CurrentCommit;
    MIGetHeapStatus.TotalUncommitted := PeakCommit - CurrentCommit;
    MIGetHeapStatus.TotalCommitted := CurrentCommit;
    MIGetHeapStatus.TotalAllocated := CurrentCommit;
    MIGetHeapStatus.TotalFree := PeakCommit - CurrentCommit;
    MIGetHeapStatus.FreeSmall := PeakCommit - CurrentCommit;
    MIGetHeapStatus.Unused := PeakCommit - CurrentCommit;
end;

Function MIGetFPCHeapStatus: TFPCHeapStatus;
var CurrentRSS, PeakRSS, CurrentCommit, PeakCommit, PageFaults: ptruint;
begin
    FillChar(MIGetFPCHeapStatus, SizeOf(MIGetFPCHeapStatus), 0);
    mi_process_info(nil, nil, nil, @CurrentRSS, @PeakRSS, @CurrentCommit, @PeakCommit, @PageFaults);
    (* TODO: Verify that any of this is correct *)
    MIGetFPCHeapStatus.MaxHeapUsed := PeakCommit;
    MIGetFPCHeapStatus.CurrHeapSize := CurrentCommit;
    MIGetFPCHeapStatus.CurrHeapUsed := CurrentCommit;
end;

Const MIMemoryManager: TMemoryManager = (
    NeedLock: false;
    GetMem: @MIGetMem;
    FreeMem: @MIFreeMem;
    FreeMemSize: @MIFreeMemSize;
    AllocMem: @MIAllocMem;
    ReallocMem: @MIReAllocMem;
    MemSize: @MIMemSize; (* TODO: Can we use mi_usable_size here? Or does it need to return the exact size like it does now? *)
    InitThread: @MIThreadInit;
    DoneThread: @MIThreadDone;
    RelocateHeap: Nil;
    GetHeapStatus: @MIGetHeapStatus;
    GetFPCHeapStatus: @MIGetFPCHeapStatus
);

Var PreviousMemoryManager: TMemoryManager;

Initialization
    GetMemoryManager(PreviousMemoryManager);
    SetMemoryManager(MIMemoryManager);
Finalization
    SetMemoryManager(PreviousMemoryManager);
end.

