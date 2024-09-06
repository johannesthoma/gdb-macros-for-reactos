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

# attach to target, load kernel symbols and break on BSOD
# also specific to my setup

define init-reactos
  target remote localhost:2001
  load-ntoskrnl
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

define list-threads-of-process
  set $entry = $arg0->ThreadListHead.Flink
  p $entry
  p $arg0->ThreadListHead
  p &$arg0->ThreadListHead
  while $entry != &$arg0->ThreadListHead
    print "hallo"
    set $thread = (struct _ETHREAD *)(((char*)$entry) - (char*)(&((struct _ETHREAD *)0)->ThreadListEntry))
    p $entry
    p $thread
    set $entry = $entry->Flink
  end
end
