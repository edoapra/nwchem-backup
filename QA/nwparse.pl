#
# $Id: nwparse.pl,v 1.18 2003-03-29 02:51:28 edo Exp $
#
#
# perl script to parse nwchem output files
#
# The script is envoked with the command:
#    perl nwparse.pl [-h||-H||-help] [-d] [-q] [-s suffix]  nwchem_output_file_1 [nwchem_output_file_2 ...]
# 
# 
# Written:  4/21/97
# By:       Ricky A. Kendall
#           High Performance Computational Chemistry Group
#           Theory Modeling and Simulation Program
#           Environmental Molecular Sciences Laboratory
#           Pacific Northwest National Laboratory
#           P.O. Box 999
#           Richland, WA 99352-0999
#
$quiet = 0;
$debug = 0;
$num_argv = @ARGV;

if ($num_argv == 0) {
    &Usage;
    die "fatal error: no file to parse\n";
}
$suffix = '.nwparse';
#
# parse optional arguments 
# 1) -d 
# 2) -s suffix
# 3) -q 

@FILES_TO_PARSE = ();
$get_suffix = 0;
foreach $argument (@ARGV) {
    if ($get_suffix){
	$suffix = $argument;
	if (!($suffix =~ /^\./)) {$suffix = '.' . $suffix;}
        $get_suffix = 0;
    }
    elsif ($argument eq '-h' || $argument eq '-help' || $argument eq '-H'){
        &Usage;	exit 0;}
    elsif ($argument eq '-d') {print "debug: debug turned on at command line\n";$debug = 1;}
    elsif ($argument eq '-s') {$get_suffix = 1;}
    elsif ($argument eq '-q') {$quiet = 1;}
    elsif ($argument =~ /^-/) {print "\n\nUnrecognized argument: $argument\n";die "fatal error";}
    else {push(@FILES_TO_PARSE,$argument);}
}

if ($debug) {$quiet =0;}

if ($debug) {
 print "\ndebug:number of arguments: $num_argv\n\n";print "debug: arguments @ARGV";
 print "\ndebug: suffix is $suffix\n";
 print "\ndebug: files to parse @FILES_TO_PARSE";
}

foreach $filename (@FILES_TO_PARSE) {
    @atoms = ();
    @coords = ();
    @grads  = ();
    if ($debug) {print "\ndebug: file to open is $filename\n";}
    open(FILE_TO_PARSE,$filename) || die "fatal error: Could not open file:$filename\n";
    
    $fileout  = '>' . $filename . $suffix ;
    if ($debug) {print "\ndebug: file for parsed output is: $fileout\n";}
    open(FILE_OUTPUT,$fileout) || die "fatal error: Could not open file:$fileout\n";
    
    $selcipt_block = 0;
    $gradient_block = 0;
    $lines = 0 ;
    while (<FILE_TO_PARSE>){
	$lines ++;
	if ($selcipt_block && /^\s*$/) {
	    $selcipt_block = 0;
	    $num_energies = @ci_energy;
	    $num_test = @pt_correc;
	    if ($num_test != $num_energies) {
		die "number of ci+pt energies different than number of corrections\n";
	    }
	    $num_test = @cipt_ene;
	    if ($num_test != $num_energies) {
		die "number of ci+pt energies different than number of summed ci+pt energies\n";
	    }
	    $num_test = @pt_norm;
	    if ($num_test != $num_energies) {
		die "number of ci+pt energies different than number of pt norms\n";
	    }
	    if (! $quiet) {
		printf " ci energy   pt correction ci+pt energy PT norm\n";
		printf " ----------  ------------- ------------ -------\n";
		}
	    printf FILE_OUTPUT "ci energy   pt correction ci+pt energy PT norm\n";
	    printf FILE_OUTPUT "----------  ------------- ------------ -------\n";
	    for ($itok = 0;$itok < $num_energies; $itok++){
		if (! $quiet){
		    printf "%11.5f %13.5f %12.5f %7.3f\n", 
		           set_to_digits($ci_energy[$itok],5), 
		           set_to_digits($pt_correc[$itok],5),
                           set_to_digits($cipt_ene[$itok],5),
                           set_to_digits($pt_norm[$itok],3);
		}
		    printf FILE_OUTPUT "%11.5f %13.5f %12.5f %7.3f\n", 
		           set_to_digits($ci_energy[$itok],5), 
		           set_to_digits($pt_correc[$itok],5),
                           set_to_digits($cipt_ene[$itok],5),
                           set_to_digits($pt_norm[$itok],3);
	    }
	    
	}
	if ($gradient_block && /^\s*$/) {
	    $gradient_block = 0;
	    $num_atoms = @atoms;
	    $num_grads = @grads;
	    $num_coords = @coords;
	    if (($num_grads/3) != $num_atoms){
		print " num_grads = $num_grads\n";
		print " num_atoms = $num_atoms\n";
		die " fatal error ";
	    }
	    if (($num_coords/3) != $num_atoms){
		print " num_coords = $num_coords\n";
		print " num_atoms  = $num_atoms\n";
		die " fatal error ";
	    }
	    if ($debug){
		print "debug: number of atoms: $num_atoms @atoms\n";
		print "debug: number of grads: $num_grads @grads\n";
		print "debug: number of coords: $num_coords @coords\n";
	    }
#               SSSSSSSSSS FFFFFFFFFF FFFFFFFFFF FFFFFFFFFF
	    if (! $quiet) {
		printf "   Atoms             Coordinates:\n";
	    }
	    printf FILE_OUTPUT "   Atoms             Coordinates:\n";
	    for ($iatom=0;$iatom < $num_atoms; $iatom++){
		$indx1 = $iatom*3 ;
		$indx2 = $indx1 + 1;
		$indx3 = $indx1 + 2;
		if (! $quiet) {
		    printf " %10s %10.4f %10.4f %10.4f\n", 
		           $atoms[$iatom], 
                           set_to_digits($coords[$indx1],4), 
                           set_to_digits($coords[$indx2],4), 
		           set_to_digits($coords[$indx3],4) ;
		}
		printf FILE_OUTPUT " %10s %10.4f %10.4f %10.4f\n", 
		       $atoms[$iatom], 
                       set_to_digits($coords[$indx1],4), 
                       set_to_digits($coords[$indx2],4), 
                       set_to_digits($coords[$indx3],4);
	    }
#               SSSSSSSSSS FFFFFFFFFF FFFFFFFFFF FFFFFFFFFF
	    if (! $quiet) {
		printf "   Atoms              Gradients:\n";
	    }
	    printf FILE_OUTPUT "   Atoms              Gradients:\n";
	    for ($iatom=0;$iatom < $num_atoms; $iatom++){
		$indx1 = $iatom*3 ;
		$indx2 = $indx1 + 1;
		$indx3 = $indx1 + 2;
		if (! $quiet) {
		    printf " %10s %10.4f %10.4f %10.4f\n", 
		         $atoms[$iatom], 
		         set_to_digits($grads[$indx1],4), 
		         set_to_digits($grads[$indx2],4),
  		         set_to_digits($grads[$indx3],4);
		}
		printf FILE_OUTPUT " %10s %10.4f %10.4f %10.4f\n", 
		         $atoms[$iatom], 
		         set_to_digits($grads[$indx1],4), 
		         set_to_digits($grads[$indx2],4),
  		         set_to_digits($grads[$indx3],4);
	    }
	    
	    @atoms = ();
	    @coords = ();
	    @grads  = ();
	}
	next if /^\s*$/;
	if (/failed/i || /warning/i) {
	    print $_;
	}
	if (/^ Frequency/ || /^ P.Frequency/){
	    if ($debug) {print "\ndebug: $_";}
	    @line_tokens = split(' ');
	    $num_line_tokens = @line_tokens;
	    if ($debug) {
		print "debug:line_tokens: @line_tokens \n";
		print "debug:number     : $num_line_tokens \n";
	    }
	    if (! $quiet) {
		printf "%s", @line_tokens[0];
	    }
	    printf FILE_OUTPUT "%s", @line_tokens[0];
	    for($itok = 1;$itok < $num_line_tokens; $itok++){
		if (! $quiet) {
		    printf "%10.0f ", set_to_digits(@line_tokens[$itok],0);
		}
		printf FILE_OUTPUT "%10.0f ", set_to_digits(@line_tokens[$itok],0);
	    }
	    if (! $quiet) {
		printf "\n";
	    }
	    printf FILE_OUTPUT "\n";
	}
	if (/Zero-Point Energy/) {
	    if ($debug) {print "\ndebug: $_";}
	    @line_tokens = split(' ');
	    $num_line_tokens = @line_tokens;
	    if ($debug) {
		print "debug:line_tokens: @line_tokens \n";
		print "debug:number     : $num_line_tokens \n";
	    }
	    for($itok = 0;$itok < ($num_line_tokens-1); $itok++){
		if (! $quiet) {
		    printf "%s ", @line_tokens[$itok];
		}
		printf FILE_OUTPUT "%s ", @line_tokens[$itok];
	    }
#                                                    *** Assumes $itok was incremented above
	    if (! $quiet) {
		printf "%.5f\n", set_to_digits(@line_tokens[$itok],5);
	    }
	    printf FILE_OUTPUT "%.5f\n", set_to_digits(@line_tokens[$itok],5);
	}
	if (/nuclear/ && /repulsion/ && /energy/){
	    if ($debug) {print "\ndebug: $_";}
	    @line_tokens = split(' ');
	    $num_line_tokens = @line_tokens;
	    if ($debug) {
		print "debug:line_tokens: @line_tokens \n";
		print "debug:number     : $num_line_tokens \n";
	    }
	    for($itok = 0;$itok < ($num_line_tokens-1); $itok++){
		if (! $quiet) {
		    printf "%s ", @line_tokens[$itok];
		}
		printf FILE_OUTPUT "%s ", @line_tokens[$itok];
	    }
#                                                    *** Assumes $itok was incremented above
	    if (! $quiet) {
		printf "%.4f\n", set_to_digits(@line_tokens[$itok],4);
	    }
	    printf FILE_OUTPUT "%.4f\n", set_to_digits(@line_tokens[$itok],4);
	}
	if (/Total/ && /energy/) {
	 if (/SCF/ || /DFT/ || /CCSD/ || /MP2/ || /MCSCF/ || /RIMP2/ || /RISCF/ || /BAND/ || /PAW/ || /PSPW/ ) {
		if ($debug) {print "\ndebug: $_";}
		@line_tokens = split(' ');
		$num_line_tokens = @line_tokens;
		if ($debug) {
		    print "debug:line_tokens: @line_tokens \n";
		    print "debug:number     : $num_line_tokens \n";
		}
		for($itok = 0;$itok < ($num_line_tokens-1); $itok++){
		    if (! $quiet) {
			printf "%s ", @line_tokens[$itok];
		    }
		    printf FILE_OUTPUT "%s ", @line_tokens[$itok];
		}
#                                                    *** Assumes $itok was incremented above
		if (! $quiet) {
		    printf "%.5f\n", set_to_digits(@line_tokens[$itok],5);
		}
		printf FILE_OUTPUT "%.5f\n", set_to_digits(@line_tokens[$itok],5);
	    }
	}
	if (/total/ && /energy/) {
	    if ( /MBPT/ || /LCCD/ || /CCD/ || /LCCSD/ || /CCSD/ || /CCSDT/ || /CCSDTQ/ || /QCISD/ || /CISD/ || /CISDT/ || /CISDTQ/ ) {
		if ($debug) {print "\ndebug: $_";}
		@line_tokens = split(' ');
		$num_line_tokens = @line_tokens;
		if ($debug) {
		    print "debug:line_tokens: @line_tokens \n";
		    print "debug:number     : $num_line_tokens \n";
		}
		for($itok = 0;$itok < ($num_line_tokens-1); $itok++){
		    if (! $quiet) {
			printf "%s ", @line_tokens[$itok];
		    }
		    printf FILE_OUTPUT "%s ", @line_tokens[$itok];
		}
#                                                    *** Assumes $itok was incremented above
		if (! $quiet) {
		    printf "%.7f\n", set_to_digits(@line_tokens[$itok],7);
		}
		printf FILE_OUTPUT "%.7f\n", set_to_digits(@line_tokens[$itok],7);
	    }
	}
	if (/Excitation energy/) {
	    if ($debug) {print "\ndebug: $_";}
	    @line_tokens = split(' ');
	    $num_line_tokens = @line_tokens;
	    if ($debug) {
	        print "debug:line_tokens: @line_tokens \n";
	        print "debug:number     : $num_line_tokens \n";
    	    }
	    for($itok = 0;$itok < ($num_line_tokens-1); $itok++){
	        if (! $quiet) {
    	    	    printf "%s ", @line_tokens[$itok];
	        }
	        printf FILE_OUTPUT "%s ", @line_tokens[$itok];
	    }
#                                                   *** Assumes $itok was incremented above
	    if (! $quiet) {
	        printf "%.5f\n", set_to_digits(@line_tokens[$itok],5);
	    }
	    printf FILE_OUTPUT "%.5f\n", set_to_digits(@line_tokens[$itok],5);
	}
	if ($gradient_block == 2) {
	    if ($debug) {print "debug:g3: $_";}	
	    @line_tokens = split(' ');
	    $num_line_tokens = @line_tokens;
	    if ($debug) {print "debug:num tok: $num_line_tokens\n"};
	    if ($num_line_tokens == 8) {
		push(@atoms, $line_tokens[1]);
		push(@coords,@line_tokens[2..4]);
		push(@grads, @line_tokens[5..7]) ;
		if ($debug) {
		    $num_atoms = @atoms;
		    print " number of atoms: $num_atoms @atoms\n";
		    $num_grads = @grads;
		    print " number of grads: $num_grads @grads\n";
		    $num_coords = @coords;
		    print " number of coords: $num_coords @coords\n";
		}
	    }
	    else {print "possible bad gradient block\n";}
	}
	if (/atom               coordinates                        gradient/){
	    @atoms = ();
	    @coords = ();
	    @grads  = ();
	    $gradient_block = 1;
	    if ($debug) {print "debug:g1: $_";}
	}
	if (/x          y          z           x          y          z/){
	    if ($debug) {print "debug:g2: gradient_block is $gradient_block\n";}
	    if ($gradient_block == 1){
		$gradient_block++ ;
		if ($debug) {print "debug:g2: $_";}
	    }
	}
	if ($selcipt_block == 2){
	    if ($debug){print "debug:selci get info block: $_";}
	    @line_tokens = split(' ');
	    $num_line_tokens = @line_tokens;
	    if ($debug) {print "debug:num tok: $num_line_tokens\n"};
	    if ($num_line_tokens == 5){
		push(@ci_energy, $line_tokens[1]);
		push(@pt_correc, $line_tokens[2]);
		push(@cipt_ene,  $line_tokens[3]);
		push(@pt_norm,   $line_tokens[4]);
	    }
	    else {print "possible bad selci or selci+pt energy block\n";}
	}
	if (/^ EN\|/ || /^ MP\|/) {
	    if ($selcipt_block == 1){
		@ci_energy = ();
		@pt_correc = ();
		@cipt_ene  = ();
		@pt_norm   = ();
	    }
	    $selcipt_block++ ;
	    if ($debug) {print "debug:selcipt inc:$selcipt_block: line: $_";}
	}
	if (/^ Root/ && /final energy/){
	    if ($debug) {print "\ndebug: $_";}
	    @line_tokens = split(' ');
	    $num_line_tokens = @line_tokens;
	    if ($debug) {
		print "debug:line_tokens: @line_tokens \n";
		print "debug:number     : $num_line_tokens \n";
	    }
	    for ($itok = 0; $itok < ($num_line_tokens - 1); $itok++){
		if ($itok == 1) {
		    if (! $quiet) {printf "%4d ", @line_tokens[$itok];}
		    printf FILE_OUTPUT "%4d ", @line_tokens[$itok];
		}
		else{
		    if (! $quiet) {printf "%s ", @line_tokens[$itok];}
		    printf FILE_OUTPUT "%s ", @line_tokens[$itok];
		}
	    }
	    if (! $quiet){printf "%.5f\n", set_to_digits(@line_tokens[$itok],5);}
	    printf FILE_OUTPUT "%.5f\n", set_to_digits(@line_tokens[$itok],5);
	}
    }
    
#
#
#
    if (! $quiet){
	print "nwparse.pl: parsed $lines in file $filename sent output to $fileout \n";
    }
#
# done close input and output files 
#
    close(FILE_TO_PARSE);
    close(FILE_OUPUT);
}
sub Usage
{
    print "\n\nUsage: perl nwparse.pl [-h||-H||-help] [-d] [-q] [-s suffix]  nwchem_output_file_1 [nwchem_output_file_2 ...]\n\n";
    print " -d := debug mode\n";
    print " -q := quiet mode (nothing to stdout) **\n";
    print " -s := override default suffix of .nwparse to user supplied 'suffix'\n";
    print " -h := prints this help message (equivalent to -help or -H)\n";
    print "\n **:Note: if -d is set -q is ignored\n";
}
sub set_to_digits
{
    $value  = shift;
    $digits = shift;
    for ($i = 0; $i < $digits ; $i++) {$value *= 10.0;}
    if ($value < 0.0) {$value -= 0.5;}
    else              {$value += 0.5;}
    $value = int ($value);
    for ($i = 0; $i < $digits ; $i++) {$value /= 10.0;}
    if (abs($value) == 0.0) {$value = 0.0;}
    return $value;
}
