set history save on

# this lists all loaded modules (kernel, drivers and dlls)

define list-modules
  set $m = (struct _LDR_DATA_TABLE_ENTRY*)PsLoadedModuleList->Flink
  while &$m->InLoadOrderLinks != &PsLoadedModuleList
    p $m->BaseDllName.Buffer
    p $m->DllBase
    set $m = (struct _LDR_DATA_TABLE_ENTRY*)$m->InLoadOrderLinks.Flink
  end
end

# this is specific to my build

define load-ntoskrnl
#  add-symbol-file ntoskrnl.exe 0x80401000 -s .bss 0x8061c000 -s .data 0x805b8000 -s .edata 80645000
  add-symbol-file ../../output-gdb-old/symbols/ntoskrnl.exe 0x80401000 -s .bss 0x8061c000 -s .data 0x805b8000 -s .edata 80645000
end

define load-ntoskrnl-sep17
#  add-symbol-file ntoskrnl.exe 0x80401000 -s .bss 0x8061c000 -s .data 0x805b8000 -s .edata 80645000
  add-symbol-file ../../output-gdb/symbols/ntoskrnl.exe 0x80401000 -s .bss 0x8061c000 -s .data 0x805b8000 -s .edata 80645000
end

# attach to target, load kernel symbols and break on BSOD
# also specific to my setup

define init-reactos
  target remote localhost:2001
  load-ntoskrnl
  break RtlpBreakWithStatusInstruction@0
end

define init-reactos-sep17
  target remote localhost:2002
  load-ntoskrnl-sep17
  break RtlpBreakWithStatusInstruction@0
end

# example:
# offsetof _EPROCESS ThreadListHead
# $1 = (LIST_ENTRY *) 0x180
# first argument is the name of the struct not the type name

define offsetof
  if $argc != 2
    print "Usage: offsetof struct-name field-name"
  else
    print &((struct $arg0 *)0) -> $arg1
  end
end

# usage: list-threads-of-process process
# example: list-threads-of-process PsInitialSystemProcess

define list-threads-of-process
  set $entry = $arg0->ThreadListHead.Flink
  while $entry != &$arg0->ThreadListHead
    set $thread = (struct _ETHREAD *)(((char*)$entry) - (char*)(&((struct _ETHREAD *)0)->ThreadListEntry))
    p $thread
    p $thread->StartAddress
    p (enum _KTHREAD_STATE) $thread->Tcb->State
    set $entry = $entry->Flink
  end
end

# usage: eip-of-thread <thread-pointer> <out-eip-value>
define eip-of-thread
  set $arg1 = ((ULONG_PTR*)(((struct _ETHREAD *) $arg0)->Tcb.KernelStack))[2]
end

define ebp-of-thread
  set $arg1 = ((ULONG_PTR*)(((struct _ETHREAD *) $arg0)->Tcb.KernelStack))[3]
end

define esp-of-thread
  set $arg1 = ((struct _ETHREAD *) $arg0)->Tcb.KernelStack
end

# This switches gdb's context to thread ETHREAD $arg0
# it ONLY sets eip, esp and ebp so backtrace should work
# but running in the new thread probably gives wrong results.
define switch-context
  set $old_eip = $eip
  set $old_esp = $esp
  set $old_ebp = $ebp

  eip-of-thread $arg0 $eip
  esp-of-thread $arg0 $esp
  ebp-of-thread $arg0 $ebp
end
