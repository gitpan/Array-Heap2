use ExtUtils::MakeMaker;

use 5.006;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text Heap2.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    NAME => "Array::Heap2",
    VERSION_FROM => "Heap2.pm",
);

