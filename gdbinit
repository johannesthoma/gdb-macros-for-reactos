set history save on

# this lists all loaded modules (kernel, drivers and dlls)

define list-modules
  set $m = (struct _LDR_DATA_TABLE_ENTRY*)PsLoadedModuleList->Flink
  while &$m->InLoadOrderLinks != &PsLoadedModuleList
    p $m->BaseDllName.Buffer
    set $m = (struct _LDR_DATA_TABLE_ENTRY*)$m->InLoadOrderLinks.Flink
  end
end

# this is specific to my build

define load-ntoskrnl
  add-symbol-file ntoskrnl.exe 0x80401000 -s .bss 0x8061c000 -s .data 0x805b8000 -s .edata 80645000
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
# this does not work yet
define list-threads-of-process
  set $m = (struct _EPROCESS*)$arg0->ThreadListHead.Flink
  while &((struct _ETHREAD*)$m)->ThreadListEntry != &$arg0->ThreadListHead
    p "hallo"
#    set $n = ((char*)$m)-offsetof _ETHREAD ThreadListEntry
    set $n = ((char*)$m)-0x224
    p $m
    p $n
    set $m = ((struct _ETHREAD*)$n)->ThreadListEntry.Flink
  end
end
