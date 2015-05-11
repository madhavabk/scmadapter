#!perl

#   Author: Madhavarao Kulkarni (madhavabk@gmail.com)
#   Date  : 16-Mar-2015

#   ScmAdapter is a utility tool which helps in SCM automation, 
#   workflow automation
#   code review type of needs. It can also integrated in workflow that demands for SCM operations.
#   It also removes the complexity to access user machines for getting modified files. 
#   Instead it generates them through patch.

#   One of the most important features includes, no connection requirements to user workspace.
#   Modifications in user workspace will be re-computed from ScmAdapter to give you flexibility
#   that you get with committed code.

# FEATURES:
#   1. Generate list of files modified.
#   2. Generates number of blocks modified per file.
#   3. Generates content for original & modified file
#   4. Generates LOC ( Lines of Code ) as added, modified, deleted.
#   5. Generates side-by-side view of the original and modified code.
#   6. Handles diff/patch that contains files from various SCM systems.
#   7. Provides language based color coding for the files.
#   8. Prints diff type, SCM type for pre-inspection.
###############################################################################


BEGIN {
    use lib "../lib";
    my $diffUtilPath = "/usr/local/bin"; #Change this path if diffUtils installed in different location.
    $ENV{PATH} = $diffUtilPath . ":" . $ENV{PATH};
}

use Patch;
use PatchFile;
use Env;
use Getopt::Long;

my $diff_location;
my $clean_flag = 1;
my $output_path;
my $patchId;

### Call main routine ###
main();

sub main {
    #Create environment object to hold all common environment values.
    my $env = Env->new();
    $DB::single = 1 ;
    process_options();

    #Create patch object
    my $patch = Patch->new();
    $patch->patchId($patchId);
    $patch->patchPath($patchPath);

    #Detect the diff
    if( ! $scm_type ) { 
        #If SCM type not specified with -s option then we can detect.
        $scm_type = $patch->detectScm();
    }
    $patch->scmType($scm_type);

    #cleanup the diff
    $patch->cleanupDiff($clean_flag);
    #Split diff and have patches ready for each file. So that patch can be applied on individual files.
    $patch->getFiles($env);
    $patch->splitDiff($env);

    #TO-DO Get files object
    #TO-DO Get hunks
    #TO-DO Get LOC

    #Produce files
    $patch->generateFiles($env);

    #Apply patch
    $patch->applyPatch($env);
}

sub process_options {
    $DB::single = 1;
    GetOptions( "patch=s" => \$patchPath,
                "id=i" => \$patchId,
                "outdir=s" => \$output_path );
    usage() if( $patchId == null );
    if( $patchPath eq null ) {
        usage();
    }
}

sub usage {
    print "ScmAdapater.pl -id <int> -patch <patch_path> [ -outdir <output_path> ]\n";
    exit(1);
}
