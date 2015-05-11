#!perl

package Patch;
#Author: Madhavarao Kulkarni(madhavabk@gmail.com)
#Module to handle operations on patch itself

sub new {
    my $class = shift;
    my $self = {
        PATCH_ID => "",
        PATCH_PATH => "",
        SCM_TYPE => "",
        FILES_COUNT => 0,
        FILES_OBJ => (),
    };
    bless ($self, $class);
    return $self;
}

#Getters & Setters
sub patchId {
    $self = shift;
    if($#_ >= 0 ) {
        $self->{PATCH_ID} = shift;
    } else {
        return $self->{PATCH_ID};
    }
}

sub scmType {
    $self = shift;
    if($#_ >= 0 ) {
        $self->{SCM_TYPE} = shift;
    } else {
        return $self->{SCM_TYPE};
    }
}

sub patchPath {
    $self = shift;
    if($#_ >= 0 ) {
        $self->{PATCH_PATH} = shift;
    } else {
        return $self->{PATCH_PATH};
    }
}

sub splitDiff {
    #splitdiff cc_diff use this.
    my($self, $env) = @_;
    print "Splitting diff file now\n";
    if($self->{FILES_COUNT} > 0 ) {
        my $out = `splitdiff -a $self->{PATCH_PATH}`;
        if($out > 0 ) {
            print "Failed to split diff file\n";
        }
    }
    return;
}

sub generateFiles {
    my ($self, $env) = @_;
    for(my $i=0; $i< $self->{FILES_COUNT}; $i++ ) {
        my $file = $self->{FILES_OBJ}[$i];
        $file->copy_files($env);
    }
}

sub getFiles {
    my($self, $env) = @_;
    my $patchPath = $self->{PATCH_PATH};
    my $cmd = 'lsdiff -n ' . $patchPath .  ' | while read n file ; do sed -ne "$n,$(($n+1))p" ' . $patchPath . '; done';
    #my @files = `lsdiff -n $patch`;
    my @files_all = `$cmd`;

    my $part = 1; #This is to store part001, 002 for split patch
    for( my $i=0; $i <= $#files_all; $i = $i+2 ) {
        my $file =  PatchFile->new($scm_type);
        $self->{FILES_COUNT}++; #Count number of files in patch
        $file->setName($files_all[$i+1]);;
        $file->predName($files_all[$i]);
        $file->process();
        if($#files_all > 1) {
            $file->patchPath("$patchPath.part00" . $part++ ) 
        } else {
            $file->patchPath($patchPath);
        }
        push @{$self->{FILES_OBJ}}, $file;
    }
}

sub cleanupDiff {
    my($self, $flag) = @_;
    return if(! $flag);
    my $patch = $self->{PATCH_PATH};
    `cp $patch $patch.org`;
    #my $cmd = `filterdiff --clean $patch.org --remove-timestamps > $patch`;
    my $cmd = `filterdiff --clean $patch.org > $patch`;
}

sub detectScm {
    return "SVN";
}

sub applyPatch {
    my ($self, $env) = @_;
    for(my $i=0; $i< $self->{FILES_COUNT}; $i++ ) {
        my $file = $self->{FILES_OBJ}[$i];
        $file->patchIt($env);
    }
}

1;
